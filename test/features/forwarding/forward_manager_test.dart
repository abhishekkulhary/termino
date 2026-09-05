@Timeout(Duration(seconds: 120))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/forwarding/application/forward_manager.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_sshd.dart';

/// A TCP server that echoes back whatever it is sent, so a tunnel can be
/// proven to carry bytes end to end rather than merely to open.
Future<ServerSocket> startEchoServer() async {
  final server = await ServerSocket.bind('127.0.0.1', 0);
  server.listen((socket) {
    socket.listen(
      (data) => socket.add(data),
      onDone: socket.close,
      onError: (Object _) => socket.destroy(),
    );
  });
  return server;
}

Future<int> freePort() async {
  final socket = await ServerSocket.bind('127.0.0.1', 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  if (!TestSshd.isSupported) {
    test('forwarding tests need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late SshConnection connection;
  late ForwardManager manager;

  setUp(() async {
    server = await TestSshd.start();
    final factory = SshConnectionFactory(
      verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
      onHostKeyPrompt: (_) async => true,
    );
    connection = await factory.connect(
      host: SshHost(
        id: 'fwd',
        label: 'fwd',
        hostname: '127.0.0.1',
        username: TestSshd.username,
        port: server.port,
      ),
      prompts: SshAuthPrompts(
        identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
      ),
    );
    manager = ForwardManager(connection.client);
  });

  tearDown(() async {
    // Awaited, so a remote forward's cancellation completes before the client
    // that carries it is closed.
    await manager.shutdown();
    manager.dispose();
    await connection.close();
    await server.stop();
  });

  Future<String> roundTrip(int port, String message) async {
    final socket = await Socket.connect('127.0.0.1', port);
    final reply = Completer<String>();
    socket
      ..listen((data) {
        if (!reply.isCompleted) reply.complete(utf8.decode(data));
      })
      ..add(utf8.encode(message));
    final result = await reply.future.timeout(const Duration(seconds: 10));
    await socket.close();
    return result;
  }

  group('local forwards', () {
    test('carry bytes to a host reachable from the server', () async {
      final echo = await startEchoServer();
      addTearDown(echo.close);
      final listenPort = await freePort();

      final forward = PortForward(
        id: 'local-1',
        hostId: 'fwd',
        kind: PortForwardKind.local,
        listenPort: listenPort,
        destinationHost: '127.0.0.1',
        destinationPort: echo.port,
      );

      await manager.start(forward);

      expect(manager.statusOf(forward.id)!.status, PortForwardStatus.active);
      expect(
        await roundTrip(listenPort, 'through-the-tunnel'),
        'through-the-tunnel',
      );
    });

    test('count the connections they carry', () async {
      final echo = await startEchoServer();
      addTearDown(echo.close);
      final listenPort = await freePort();

      final forward = PortForward(
        id: 'local-2',
        hostId: 'fwd',
        kind: PortForwardKind.local,
        listenPort: listenPort,
        destinationHost: '127.0.0.1',
        destinationPort: echo.port,
      );
      await manager.start(forward);

      await roundTrip(listenPort, 'one');
      await roundTrip(listenPort, 'two');

      expect(manager.statusOf(forward.id)!.connectionCount, 2);
    });

    test('stopping closes the listener', () async {
      final echo = await startEchoServer();
      addTearDown(echo.close);
      final listenPort = await freePort();

      final forward = PortForward(
        id: 'local-3',
        hostId: 'fwd',
        kind: PortForwardKind.local,
        listenPort: listenPort,
        destinationHost: '127.0.0.1',
        destinationPort: echo.port,
      );
      await manager.start(forward);
      await manager.stop(forward.id);

      expect(manager.statusOf(forward.id)!.status, PortForwardStatus.stopped);
      await expectLater(
        Socket.connect(
          '127.0.0.1',
          listenPort,
          timeout: const Duration(seconds: 2),
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('a port already in use fails with a message worth reading', () async {
      final occupied = await ServerSocket.bind('127.0.0.1', 0);
      addTearDown(occupied.close);

      final forward = PortForward(
        id: 'local-4',
        hostId: 'fwd',
        kind: PortForwardKind.local,
        listenPort: occupied.port,
        destinationHost: '127.0.0.1',
        destinationPort: 80,
      );

      await manager.start(forward);

      final status = manager.statusOf(forward.id)!;
      expect(status.status, PortForwardStatus.failed);
      expect(status.error, 'That port is already in use on this device.');
      expect(status.error, isNot(contains('SocketException')));
    });
  });

  group('remote forwards', () {
    test('carry bytes back from the server', () async {
      final echo = await startEchoServer();
      addTearDown(echo.close);
      final remotePort = await freePort();

      final forward = PortForward(
        id: 'remote-1',
        hostId: 'fwd',
        kind: PortForwardKind.remote,
        listenPort: remotePort,
        destinationHost: '127.0.0.1',
        destinationPort: echo.port,
      );

      await manager.start(forward);
      expect(manager.statusOf(forward.id)!.status, PortForwardStatus.active);

      // The "server" is this machine, so its listening port is reachable here.
      expect(await roundTrip(remotePort, 'back-through'), 'back-through');
    });
  });

  group('dynamic forwards', () {
    test('start a SOCKS listener', () async {
      final listenPort = await freePort();

      final forward = PortForward(
        id: 'dynamic-1',
        hostId: 'fwd',
        kind: PortForwardKind.dynamic,
        listenPort: listenPort,
      );

      await manager.start(forward);

      expect(manager.statusOf(forward.id)!.status, PortForwardStatus.active);
      final probe = await Socket.connect('127.0.0.1', listenPort);
      await probe.close();
    });
  });

  group('validation', () {
    test('an incomplete tunnel is refused before anything is opened', () async {
      const forward = PortForward(
        id: 'bad',
        hostId: 'fwd',
        kind: PortForwardKind.local,
        listenPort: 9999,
        // No destination.
      );

      await manager.start(forward);

      expect(manager.statusOf(forward.id)!.status, PortForwardStatus.failed);
      expect(manager.statusOf(forward.id)!.error, 'The tunnel is incomplete.');
    });

    test('stopAll stops everything', () async {
      final echo = await startEchoServer();
      addTearDown(echo.close);

      for (var i = 0; i < 2; i++) {
        await manager.start(
          PortForward(
            id: 'many-$i',
            hostId: 'fwd',
            kind: PortForwardKind.local,
            listenPort: await freePort(),
            destinationHost: '127.0.0.1',
            destinationPort: echo.port,
          ),
        );
      }

      await manager.stopAll();

      expect(
        manager.forwards.every((f) => f.status == PortForwardStatus.stopped),
        isTrue,
      );
    });
  });
}
