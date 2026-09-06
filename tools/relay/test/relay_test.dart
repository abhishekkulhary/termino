@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:termino_relay/allowlist.dart';
import 'package:termino_relay/relay.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A TCP server that echoes what it receives, standing in for an SSH server.
Future<ServerSocket> startEchoServer() async {
  final server = await ServerSocket.bind('127.0.0.1', 0);
  server.listen((socket) {
    socket.listen(socket.add, onDone: socket.close, onError: (Object _) {});
  });
  return server;
}

void main() {
  late ServerSocket upstream;
  Relay? relay;

  setUp(() async => upstream = await startEchoServer());

  tearDown(() async {
    await relay?.stop();
    relay = null;
    await upstream.close();
  });

  Future<Relay> startRelay({String? token, int maxConnections = 64}) async {
    final started = Relay(
      RelayConfig(
        allowlist: Allowlist.parse(['127.0.0.1:${upstream.port}']),
        port: 0,
        token: token,
        maxConnections: maxConnections,
      ),
    );
    await started.start();
    relay = started;
    return started;
  }

  Uri tunnelUri(Relay r, {String? host, int? port, String? token}) => Uri.parse(
    'ws://127.0.0.1:${r.boundPort}/ssh'
    '?host=${host ?? '127.0.0.1'}&port=${port ?? upstream.port}'
    '${token == null ? '' : '&token=$token'}',
  );

  group('refusing to be an open proxy', () {
    test('a relay with no allowlist will not be created', () {
      expect(
        () => Relay(RelayConfig(allowlist: Allowlist.parse(const []))),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a destination outside the allowlist is refused', () async {
      final r = await startRelay();
      final other = await startEchoServer();
      addTearDown(other.close);

      final channel = WebSocketChannel.connect(tunnelUri(r, port: other.port));

      await expectLater(channel.ready, throwsA(isA<Object>()));
    });

    test('a wrong port on an allowed host is refused', () async {
      final r = await startRelay();

      final channel = WebSocketChannel.connect(tunnelUri(r, port: 1));

      await expectLater(channel.ready, throwsA(isA<Object>()));
    });
  });

  group('authentication', () {
    test('a token is required when configured', () async {
      final r = await startRelay(token: 'sekret');

      final channel = WebSocketChannel.connect(tunnelUri(r));

      await expectLater(channel.ready, throwsA(isA<Object>()));
    });

    test('the right token is accepted', () async {
      final r = await startRelay(token: 'sekret');

      final channel = WebSocketChannel.connect(tunnelUri(r, token: 'sekret'));
      await channel.ready;

      await channel.sink.close();
    });
  });

  group('forwarding', () {
    test('carries bytes both ways', () async {
      final r = await startRelay();
      final channel = WebSocketChannel.connect(tunnelUri(r));
      await channel.ready;

      final reply = Completer<String>();
      channel.stream.listen((message) {
        if (!reply.isCompleted) {
          reply.complete(utf8.decode(message as List<int>));
        }
      });
      channel.sink.add(utf8.encode('through-the-relay'));

      expect(await reply.future, 'through-the-relay');
      await channel.sink.close();
    });

    test('closing the tunnel releases the connection slot', () async {
      final r = await startRelay();
      final channel = WebSocketChannel.connect(tunnelUri(r));
      await channel.ready;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(r.openConnections, 1);

      await channel.sink.close();
      for (var i = 0; i < 40 && r.openConnections > 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      expect(r.openConnections, 0);
    });

    test('an unreachable destination closes the tunnel cleanly', () async {
      final dead = await ServerSocket.bind('127.0.0.1', 0);
      final deadPort = dead.port;
      await dead.close();

      final started = Relay(
        RelayConfig(
          allowlist: Allowlist.parse(['127.0.0.1:$deadPort']),
          port: 0,
        ),
      );
      await started.start();
      relay = started;

      final channel = WebSocketChannel.connect(
        Uri.parse(
          'ws://127.0.0.1:${started.boundPort}/ssh'
          '?host=127.0.0.1&port=$deadPort',
        ),
      );
      await channel.ready;

      // The relay accepts the WebSocket, fails to dial, then closes with a
      // server-error code. What matters is that the client is released rather
      // than left hanging; whether that arrives as a close or as an error on
      // the stream is a WebSocket detail, not a behaviour worth pinning.
      var finished = false;
      channel.stream.listen(
        (_) {},
        onError: (Object _) => finished = true,
        onDone: () => finished = true,
      );

      for (var i = 0; i < 60 && !finished; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      expect(finished, isTrue, reason: 'the client must not be left waiting');
      expect(started.openConnections, 0);
    });
  });

  group('health', () {
    test('reports ok', () async {
      final r = await startRelay();

      final response = await HttpClient()
          .getUrl(Uri.parse('http://127.0.0.1:${r.boundPort}/health'))
          .then((request) => request.close());

      expect(response.statusCode, 200);
    });

    test('an unknown path is not found', () async {
      final r = await startRelay();

      final response = await HttpClient()
          .getUrl(Uri.parse('http://127.0.0.1:${r.boundPort}/anything'))
          .then((request) => request.close());

      expect(response.statusCode, 404);
    });
  });
}
