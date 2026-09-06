// Real SSH over a real relay: dartssh2 speaking to a real OpenSSH server
// through the reference WebSocket relay, with no raw TCP socket in between.
//
// This is the whole web path except the browser's own WebSocket
// implementation, which is the one part a VM test cannot stand in for.
@Timeout(Duration(seconds: 120))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/sockets/websocket_ssh_socket.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';
import 'package:termino_relay/allowlist.dart';
import 'package:termino_relay/relay.dart';

import '../../../support/in_memory_known_hosts.dart';
import '../../../support/test_sshd.dart';

void main() {
  if (!TestSshd.isSupported) {
    test('relay tests need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late Relay relay;
  late InMemoryKnownHostsRepository knownHosts;

  setUp(() async {
    server = await TestSshd.start();
    relay = Relay(
      RelayConfig(
        allowlist: Allowlist.parse(['127.0.0.1:${server.port}']),
        port: 0,
      ),
    );
    await relay.start();
    knownHosts = InMemoryKnownHostsRepository();
  });

  tearDown(() async {
    await relay.stop();
    await server.stop();
  });

  SshHost hostProfile() => SshHost(
    id: 'relayed',
    label: 'Relayed',
    hostname: '127.0.0.1',
    username: TestSshd.username,
    port: server.port,
  );

  /// Dials through the relay instead of opening a TCP socket, exactly as the
  /// web build does.
  Future<SSHSocket> throughRelay(String host, int port, {Duration? timeout}) =>
      WebSocketSshSocket.connect(
        Uri.parse('ws://127.0.0.1:${relay.boundPort}/ssh'),
        host: host,
        port: port,
        timeout: timeout,
      );

  SshBackend backendThroughRelay() => SshBackend(
    host: hostProfile(),
    verifier: HostKeyVerifier(knownHosts),
    onHostKeyPrompt: (check) async => true,
    prompts: SshAuthPrompts(
      identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
    ),
    socketFactory: throughRelay,
  );

  Future<void> runAndWait(
    TerminalBackend backend,
    StringBuffer buffer,
    String command,
    String marker,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(deadline)) {
      backend.write(Uint8List.fromList(utf8.encode('$command\n')));
      for (var i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (buffer.toString().contains(marker)) return;
      }
    }
    throw StateError('the shell never ran "$command". Got:\n$buffer');
  }

  test('authenticates and runs a command through the relay', () async {
    final backend = backendThroughRelay();
    final transcript = StringBuffer();
    backend.output.listen(
      (chunk) => transcript.write(utf8.decode(chunk, allowMalformed: true)),
    );

    await backend.start();
    expect(backend.state, BackendConnectionState.connected);

    // The marker is split so it cannot match the command's own echo.
    await runAndWait(backend, transcript, 'echo RELA""YED-OK', 'RELAYED-OK');

    expect(transcript.toString(), contains('RELAYED-OK'));
    await backend.close();
  });

  test('host key verification still happens on this side', () async {
    // The point of running SSH in the browser rather than in the relay: the
    // relay carries ciphertext and the key is checked here.
    final backend = backendThroughRelay();
    await backend.start();
    await backend.close();

    expect(knownHosts.entries, hasLength(1));
    expect(knownHosts.entries.single.fingerprint, startsWith('SHA256:'));
    expect(knownHosts.entries.single.source, KnownHostSource.trustOnFirstUse);
  });

  test('a changed host key is refused even through a relay', () async {
    final first = backendThroughRelay();
    await first.start();
    await first.close();

    // Restart the server on the same port with a different key, and point a
    // fresh relay at it.
    final port = server.port;
    await relay.stop();
    await server.stop();
    server = await TestSshd.start(port: port, hostKey: 'client_ed25519');
    relay = Relay(
      RelayConfig(allowlist: Allowlist.parse(['127.0.0.1:$port']), port: 0),
    );
    await relay.start();

    final second = backendThroughRelay();

    await expectLater(
      second.start(),
      throwsA(
        isA<TerminalBackendFailure>().having(
          (failure) => failure.kind,
          'kind',
          TerminalBackendFailureKind.hostKeyMismatch,
        ),
      ),
    );
    await second.close();
  });

  test(
    'a destination the relay does not allow fails as a network error',
    () async {
      final backend = SshBackend(
        host: hostProfile().copyWith(port: 1),
        verifier: HostKeyVerifier(knownHosts),
        onHostKeyPrompt: (_) async => true,
        prompts: SshAuthPrompts(
          identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
        ),
        socketFactory: throughRelay,
        connectTimeout: const Duration(seconds: 5),
      );

      await expectLater(
        backend.start(),
        throwsA(
          isA<TerminalBackendFailure>().having(
            (failure) => failure.kind,
            'kind',
            TerminalBackendFailureKind.network,
          ),
        ),
      );
      await backend.close();
    },
  );

  test('the relay never sees plaintext', () async {
    // Everything the relay forwards is SSH wire format. A short readable
    // marker typed into the session must not appear in the bytes it carries,
    // which is what "the relay is a pipe, not a trusted component" means in
    // practice.
    final observed = BytesBuilder();
    final backend = SshBackend(
      host: hostProfile(),
      verifier: HostKeyVerifier(knownHosts),
      onHostKeyPrompt: (_) async => true,
      prompts: SshAuthPrompts(
        identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
      ),
      socketFactory: (host, port, {timeout}) async {
        final socket = await throughRelay(host, port, timeout: timeout);
        return _ObservingSocket(socket, observed);
      },
    );

    final transcript = StringBuffer();
    backend.output.listen(
      (chunk) => transcript.write(utf8.decode(chunk, allowMalformed: true)),
    );
    await backend.start();
    await runAndWait(
      backend,
      transcript,
      'echo SECR""ET-MARKER',
      'SECRET-MARKER',
    );

    final wire = utf8.decode(observed.takeBytes(), allowMalformed: true);
    expect(
      wire,
      isNot(contains('SECRET-MARKER')),
      reason: 'the marker reached the terminal but must not be on the wire',
    );
    expect(transcript.toString(), contains('SECRET-MARKER'));

    await backend.close();
  });
}

/// Wraps a socket and records everything sent through it, so a test can look
/// at exactly what the relay would carry.
class _ObservingSocket implements SSHSocket {
  new(this._inner, this._observed);

  final SSHSocket _inner;
  final BytesBuilder _observed;

  @override
  Stream<Uint8List> get stream => _inner.stream;

  @override
  StreamSink<List<int>> get sink {
    final controller = StreamController<List<int>>();
    controller.stream.listen((chunk) {
      _observed.add(chunk);
      _inner.sink.add(chunk);
    }, onDone: () => unawaited(_inner.sink.close()));
    return controller.sink;
  }

  @override
  Future<void> get done => _inner.done;

  @override
  Future<void> close() => _inner.close();

  @override
  void destroy() => _inner.destroy();

  @override
  Future<void> flush() => _inner.flush();
}
