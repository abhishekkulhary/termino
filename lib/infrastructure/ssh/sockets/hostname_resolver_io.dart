import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/infrastructure/ssh/sockets/mdns_message.dart';

/// Resolves [host], falling back to multicast DNS for `.local` names.
///
/// A `.local` name is not ordinary DNS: it is answered by the machine itself
/// over multicast, and whether that works is entirely a matter of what the
/// operating system does for you. macOS and iOS have Bonjour built into the
/// resolver, so `pi@my-server.local` has always simply worked there. Android
/// has no mDNS in its resolver at all — the lookup fails with "no address
/// associated with hostname" before a single byte reaches the network.
///
/// The failure that produces is unusually confusing, because it happens
/// *before* the connection: no password prompt, no host key question, no
/// timeout — just an instant refusal for a host the user can reach from their
/// laptop. It reads as a broken app rather than a missing resolver.
///
/// So the name is resolved here, in the one place every SSH transport passes
/// through, and shells, SFTP and port forwards all reach a home-network host
/// the same way.
Future<String> resolveHostname(
  String host, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  if (!isMulticastName(host)) return host;

  // The operating system first. Where Bonjour or Avahi exists its answer is
  // cached and authoritative, and this leaves that behaviour untouched.
  try {
    final addresses = await InternetAddress.lookup(host);
    if (addresses.isNotEmpty) return host;
  } on SocketException {
    // Expected on Android. Fall through to asking the network ourselves.
  }

  final address = await _queryMulticast(host, timeout);
  if (address == null) {
    throw TerminalBackendFailure(
      TerminalBackendFailureKind.network,
      '$host did not answer. A .local name is announced by the machine '
      'itself over the local network, so both devices have to be on the '
      'same one — otherwise use the IP address.',
    );
  }

  // Logged without the address: which machines someone reaches on their own
  // network is not worth writing down.
  Loggers.ssh.info('Resolved $host over multicast DNS.');
  return address;
}

/// Whether [host] is a name only multicast DNS can answer.
///
/// An IP address is left alone: a literal needs no lookup and is never a
/// `.local` name anyway.
bool isMulticastName(String host) {
  if (InternetAddress.tryParse(host) != null) return false;
  final name = host.toLowerCase();
  return name.endsWith('.local') || name.endsWith('.local.');
}

/// Asks the network directly, from a port of our own.
///
/// Two attempts: a multicast datagram is unreliable by nature, and a second
/// question costs a few milliseconds against a failure the user reads as "this
/// app cannot reach my server".
Future<String?> _queryMulticast(String host, Duration timeout) async {
  for (var attempt = 0; attempt < 2; attempt++) {
    final address = await _askOnce(host, timeout);
    if (address != null) return address;
  }
  return null;
}

Future<String?> _askOnce(String host, Duration timeout) async {
  RawDatagramSocket? socket;
  StreamSubscription<RawSocketEvent>? subscription;

  try {
    // Port 0: the kernel gives us one nobody else holds. Binding 5353, as an
    // mDNS *server* would, means sharing it with the platform's own responder
    // and losing replies to it at random.
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..multicastHops = 255;

    final answer = Completer<String?>();
    final transactionId = Random().nextInt(0x10000);

    final listening = socket;
    subscription = listening.listen((event) {
      if (event != RawSocketEvent.read || answer.isCompleted) return;
      final datagram = listening.receive();
      if (datagram == null) return;

      final addresses = decodeAddressesFor(datagram.data, host);
      if (addresses.isNotEmpty) answer.complete(addresses.first);
    });

    listening.send(
      encodeAddressQuery(host, transactionId: transactionId),
      InternetAddress(mdnsGroupIPv4),
      mdnsPort,
    );

    return await answer.future.timeout(timeout, onTimeout: () => null);
  } on SocketException catch (error) {
    // No network, or a platform that will not let us open a multicast socket.
    Loggers.ssh.warning('Multicast DNS lookup for $host failed.', error);
    return null;
  } finally {
    await subscription?.cancel();
    socket?.close();
  }
}
