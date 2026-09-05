import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

/// Asks the user whether to trust a host key they have not seen before.
///
/// Returning false refuses the connection. Never called for a mismatch: that
/// is refused outright, without offering the user a button.
typedef HostKeyPrompt = Future<bool> Function(HostKeyCheck check);

/// An authenticated SSH connection, plus the jump hops carrying it.
class SshConnection {
  /// Creates a connection over [client], reached through [hops].
  new({required this.client, required this.hops});

  /// The client for the target host.
  final SSHClient client;

  /// The clients for each jump host, nearest first. Closed after [client].
  final List<SSHClient> hops;

  /// Closes the target and then every hop, innermost first, so each is torn
  /// down before the tunnel carrying it.
  Future<void> close() async {
    await client.close();
    for (final hop in hops.reversed) {
      await hop.close();
    }
  }
}

/// Opens authenticated SSH connections.
///
/// Extracted from `SshBackend` so that shells, SFTP and port forwarding all
/// reach a server the same way. That matters more than tidiness: host key
/// verification lives here, and a second copy of it — subtly different, and
/// only exercised by whichever feature was written last — is precisely how a
/// security check ends up not being one.
class SshConnectionFactory {
  /// Creates a factory.
  const new({
    required this.verifier,
    required this.onHostKeyPrompt,
    this.socketFactory = connectTcpSocket,
    this.connectTimeout = const Duration(seconds: 20),
  });

  /// Decides whether a server's key is trusted.
  final HostKeyVerifier verifier;

  /// Asks the user about an unrecognised key.
  final HostKeyPrompt onHostKeyPrompt;

  /// Opens the transport. Swapped for a WebSocket on the web.
  final SshSocketFactory socketFactory;

  /// How long to wait for the TCP connection.
  final Duration connectTimeout;

  /// Connects to [host], tunnelling through [jumpChain] nearest hop first.
  ///
  /// [refused] is populated when host key verification refuses the connection,
  /// so the caller can report *why* rather than surfacing a handshake error.
  Future<SshConnection> connect({
    required SshHost host,
    required SshAuthPrompts prompts,
    List<SshHost> jumpChain = const [],
    Map<String, SshAuthPrompts> jumpPrompts = const {},
    void Function(HostKeyCheck check)? refused,
  }) async {
    final hops = <SSHClient>[];
    SSHClient? previous;

    try {
      for (final hop in jumpChain) {
        final socket = previous == null
            ? await _openSocket(hop.hostname, hop.port)
            : await previous.forwardLocal(hop.hostname, hop.port);
        final client = await _authenticate(
          socket: socket,
          target: hop,
          prompts: jumpPrompts[hop.id] ?? const SshAuthPrompts(),
          refused: refused,
        );
        hops.add(client);
        previous = client;
      }

      final socket = previous == null
          ? await _openSocket(host.hostname, host.port)
          : await previous.forwardLocal(host.hostname, host.port);

      final client = await _authenticate(
        socket: socket,
        target: host,
        prompts: prompts,
        refused: refused,
      );

      return SshConnection(client: client, hops: hops);
    } on Object {
      // A hop that was opened before a later one failed must not be left
      // running.
      for (final hop in hops.reversed) {
        await hop.close();
      }
      rethrow;
    }
  }

  Future<SSHSocket> _openSocket(String hostname, int port) async {
    try {
      return await socketFactory(hostname, port, timeout: connectTimeout);
    } on Object catch (error) {
      throw TerminalBackendFailure(
        TerminalBackendFailureKind.network,
        '$hostname:$port could not be reached.',
        cause: error,
      );
    }
  }

  Future<SSHClient> _authenticate({
    required SSHSocket socket,
    required SshHost target,
    required SshAuthPrompts prompts,
    void Function(HostKeyCheck check)? refused,
  }) async {
    final client = SSHClient(
      socket,
      username: target.username,
      identities: prompts.identities,
      onPasswordRequest: prompts.onPasswordRequest,
      onUserInfoRequest: prompts.onUserInfoRequest,
      onUserauthBanner: prompts.onBanner,
      agentHandler: prompts.agent,
      keepAliveInterval: target.keepAliveInterval,
      onVerifyHostKey: (type, fingerprint) =>
          _verifyHostKey(target, type, fingerprint, refused),
    );

    await client.authenticated;
    return client;
  }

  /// The gate every connection passes through.
  Future<bool> _verifyHostKey(
    SshHost target,
    String keyType,
    Uint8List fingerprintBytes,
    void Function(HostKeyCheck check)? refused,
  ) async {
    // dartssh2 hands us the OpenSSH-style `SHA256:...` text, UTF-8 encoded.
    final fingerprint = utf8.decode(fingerprintBytes);

    final check = await verifier.check(
      host: target.hostname,
      port: target.port,
      keyType: keyType,
      fingerprint: fingerprint,
    );

    if (check.verdict.isAutomaticallyTrusted) return true;

    // A changed key is refused here and now. The user is never shown a
    // "connect anyway" button in the connection path; replacing a known key is
    // a separate, deliberate action taken from the mismatch dialog.
    if (check.verdict.blocksConnection) {
      refused?.call(check);
      return false;
    }

    final accepted = await onHostKeyPrompt(check);
    if (!accepted) {
      refused?.call(check);
      return false;
    }

    await verifier.trust(check);
    return true;
  }
}
