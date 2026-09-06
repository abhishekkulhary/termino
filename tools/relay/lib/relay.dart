import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:termino_relay/allowlist.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// How the relay is configured.
class RelayConfig {
  /// Creates a configuration.
  const new({
    required this.allowlist,
    this.address = '127.0.0.1',
    this.port = 8022,
    this.token,
    this.maxConnections = 64,
    this.connectTimeout = const Duration(seconds: 15),
  });

  /// Destinations the relay will connect to.
  final Allowlist allowlist;

  /// The address to bind. Defaults to loopback, so a relay started without
  /// thought is not immediately reachable from the network.
  final String address;

  /// The port to listen on.
  final int port;

  /// A shared secret every client must present, or null to require none.
  final String? token;

  /// How many tunnels may be open at once.
  final int maxConnections;

  /// How long to wait for the destination TCP connection.
  final Duration connectTimeout;
}

/// A WebSocket-to-TCP relay.
///
/// It forwards bytes in both directions and does nothing else. In particular it
/// does not terminate SSH: the client runs the SSH protocol itself over this
/// tunnel, so what passes through here is ciphertext. The relay cannot read a
/// session, cannot see a password or a private key, and cannot impersonate a
/// host — the host key the client checks is the real server's, and the
/// `known_hosts` store it is checked against is on the user's device.
///
/// That property is the reason the relay is allowed to be this simple. It is
/// not a trusted component; it is a pipe.
class Relay {
  /// Creates a relay from [config].
  new(this.config) {
    if (config.allowlist.isEmpty) {
      throw ArgumentError.value(
        config.allowlist,
        'allowlist',
        'A relay with no allowlist is an open proxy. Pass --allow at least '
            'once.',
      );
    }
  }

  /// How this relay is configured.
  final RelayConfig config;

  HttpServer? _server;
  var _open = 0;

  /// How many tunnels are currently open.
  int get openConnections => _open;

  /// The port actually bound, which differs from the configured one when 0 was
  /// requested.
  int get boundPort => _server?.port ?? config.port;

  /// Starts listening.
  Future<void> start() async {
    final handler = const Pipeline()
        .addMiddleware(logRequests(logger: _log))
        .addHandler(_router);

    _server = await shelf_io.serve(handler, config.address, config.port);
  }

  /// Stops listening and closes every tunnel.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Handler get _router => (request) {
    if (request.url.path == 'health') {
      return Response.ok('ok');
    }
    if (request.url.path != 'ssh') {
      return Response.notFound('Not found');
    }
    return _handleTunnel(request);
  };

  FutureOr<Response> _handleTunnel(Request request) {
    final query = request.requestedUri.queryParameters;

    final token = config.token;
    if (token != null && query['token'] != token) {
      // Deliberately indistinguishable from a bad destination: an attacker
      // probing the relay learns nothing about which part they got wrong.
      return Response.forbidden('Refused');
    }

    final host = query['host'];
    final port = int.tryParse(query['port'] ?? '');
    if (host == null || host.isEmpty || port == null) {
      return Response.badRequest(body: 'host and port are required');
    }

    if (!config.allowlist.allows(host, port)) {
      stderr.writeln('relay: refused $host:$port (not in the allowlist)');
      return Response.forbidden('Refused');
    }

    if (_open >= config.maxConnections) {
      return Response(503, body: 'Too many connections');
    }

    return webSocketHandler((channel, _) => _bridge(channel, host, port))(
      request,
    );
  }

  Future<void> _bridge(WebSocketChannel channel, String host, int port) async {
    _open++;

    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: config.connectTimeout);
    } on Object catch (error) {
      stderr.writeln('relay: could not reach $host:$port ($error)');
      // 4001, not 1011: web_socket_channel only permits 1000 or the
      // application range 3000-4999, and passing anything else throws — which
      // left the client waiting for a close that never came.
      await channel.sink.close(_upstreamUnreachable, 'Upstream unreachable');
      _open--;
      return;
    }

    socket.setOption(SocketOption.tcpNoDelay, true);
    final closed = Completer<void>();

    void finish() {
      if (closed.isCompleted) return;
      closed.complete();
    }

    // Payload is never logged. It is ciphertext, but a relay that writes it
    // anywhere becomes a place worth attacking.
    final upstream = socket.listen(
      channel.sink.add,
      onError: (Object _) => finish(),
      onDone: finish,
    );

    channel.stream.listen(
      (message) {
        if (message is List<int>) socket!.add(message);
      },
      onError: (Object _) => finish(),
      onDone: finish,
    );

    await closed.future;
    await upstream.cancel();
    socket.destroy();
    await channel.sink.close();
    _open--;
  }

  /// Close code for "the relay could not reach the destination".
  ///
  /// In the application-defined range, because the WebSocket spec reserves
  /// everything below 3000 and the client library enforces that.
  static const _upstreamUnreachable = 4001;

  static void _log(String message, bool isError) {
    // Request lines carry the destination but never the payload.
    (isError ? stderr : stdout).writeln('relay: $message');
  }
}
