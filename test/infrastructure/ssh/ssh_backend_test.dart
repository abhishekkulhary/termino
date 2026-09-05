// Real SSH against a real OpenSSH server, started unprivileged on a high port.
//
// These run under plain `flutter test`, not `integration_test`: dartssh2 is
// pure Dart with no platform plugin, so nothing here needs a device. That
// makes them fast, and it means the SSH backend counts towards the coverage
// gate rather than sitting outside it.
@Timeout(Duration(seconds: 120))
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_sshd.dart';

/// Runs [command] until [marker] appears in [buffer].
///
/// Two traps, both of which this suite fell into and neither of which is
/// obvious from a failing assertion:
///
///  * A shell discards anything queued while it is still initialising its line
///    editor, so input sent too early is echoed by the pty and never runs.
///    There is no reliable one-shot readiness signal — "Last login" arrives
///    before the shell starts, and a bare newline cannot be distinguished from
///    its own echo — so the command is simply re-sent until it answers.
///  * [marker] must not appear in [command], or the wait succeeds against the
///    terminal echoing back what was typed while the shell runs nothing at
///    all. Splitting the marker with empty quotes survives the echo and
///    vanishes from the output.
Future<void> _runAndWait(
  TerminalBackend backend,
  StringBuffer buffer,
  String command,
  String marker, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  assert(
    !command.contains(marker),
    'the marker must not match the command echo',
  );

  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    backend.write(Uint8List.fromList(utf8.encode('$command\n')));
    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (buffer.toString().contains(marker)) return;
    }
  }
  throw StateError('the shell never ran "$command". Got:\n$buffer');
}

void main() {
  if (!TestSshd.isSupported) {
    test('SSH integration tests need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late InMemoryKnownHostsRepository knownHosts;
  late HostKeyVerifier verifier;

  SshHost hostProfile({int? port}) => SshHost(
    id: 'test-host',
    label: 'Test server',
    hostname: '127.0.0.1',
    username: TestSshd.username,
    port: port ?? server.port,
  );

  SshAuthPrompts keyAuth({String? pem}) => SshAuthPrompts(
    identities: SSHKeyPair.fromPem(pem ?? TestSshd.clientPrivateKey),
  );

  /// Accepts any first-sighting key, as a user clicking "trust" would.
  Future<bool> acceptUnknown(HostKeyCheck check) async => true;

  /// Refuses everything, as a user clicking "cancel" would.
  Future<bool> refuseUnknown(HostKeyCheck check) async => false;

  setUp(() async {
    knownHosts = InMemoryKnownHostsRepository();
    verifier = HostKeyVerifier(knownHosts);
    server = await TestSshd.start();
  });

  tearDown(() => server.stop());

  group('connecting', () {
    test('authenticates with a public key and runs a command', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );

      final transcript = StringBuffer();
      backend.output.listen(
        (chunk) => transcript.write(utf8.decode(chunk, allowMalformed: true)),
      );

      await backend.start();
      expect(backend.state, BackendConnectionState.connected);

      // The marker must not match the command's own echo, or the test passes
      // on the terminal echoing back what we typed while the shell runs
      // nothing at all. The empty quotes survive the echo and vanish from the
      // output.
      await _runAndWait(
        backend,
        transcript,
        'echo SSH-MARK""ER-OK',
        'SSH-MARKER-OK',
      );

      expect(transcript.toString(), contains('SSH-MARKER-OK'));
      await backend.close();
    });

    test('records the host key on first use', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );

      await backend.start();
      await backend.close();

      expect(knownHosts.entries, hasLength(1));
      final entry = knownHosts.entries.single;
      expect(entry.host, '127.0.0.1');
      expect(entry.port, server.port);
      expect(entry.fingerprint, startsWith('SHA256:'));
      expect(entry.source, KnownHostSource.trustOnFirstUse);
    });

    test('a second connection is trusted without prompting', () async {
      var prompts = 0;
      Future<bool> counting(HostKeyCheck check) async {
        prompts++;
        return true;
      }

      for (var i = 0; i < 2; i++) {
        final backend = SshBackend(
          host: hostProfile(),
          verifier: verifier,
          onHostKeyPrompt: counting,
          prompts: keyAuth(),
        );
        await backend.start();
        await backend.close();
      }

      expect(prompts, 1, reason: 'only the first sighting may ask');
    });

    test('resize reaches the server', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );
      await backend.start();
      final transcript = StringBuffer();
      backend.output.listen(
        (chunk) => transcript.write(utf8.decode(chunk, allowMalformed: true)),
      );

      // Wait until the shell genuinely runs a command. Two traps here, both
      // of which this test fell into:
      //
      //  * An interactive shell flushes pending input while it initialises its
      //    line editor, so anything typed too early is echoed by the pty and
      //    then discarded. Waiting for a fixed delay is a guess; waiting for
      //    real output is not.
      //  * The marker must not match its own echo, or the wait succeeds
      //    against the command line rather than its result. The empty quotes
      //    survive the echo and vanish from the output.
      // Wait until the shell genuinely runs something before resizing, and
      // use a marker that cannot match the command's own echo.
      await _runAndWait(backend, transcript, 'echo REA""DY', 'READY');

      backend.resize(103, 41);
      // The resize is a channel request; give it a moment to reach the pty
      // before asking the shell what size it thinks it is.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _runAndWait(backend, transcript, 'stty size', '41 103');

      expect(
        transcript.toString(),
        contains('41 103'),
        reason: 'stty prints rows then columns',
      );
      await backend.close();
    });
  });

  group('agent forwarding', () {
    test('off by default, so no agent socket appears remotely', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );
      final transcript = StringBuffer();
      backend.output.listen(
        (chunk) => transcript.write(utf8.decode(chunk, allowMalformed: true)),
      );
      await backend.start();

      await _runAndWait(
        backend,
        transcript,
        r'echo "sock=[$SSH_AUTH_SOCK]" | tr -d "\n"; echo DO""NE',
        'DONE',
      );

      expect(
        transcript.toString(),
        contains('sock=[]'),
        reason: 'forwarding is opt-in; nothing should be forwarded',
      );
      await backend.close();
    });

    test('when enabled, the remote session gets an agent socket', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: SshAuthPrompts(
          identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
          agent: SSHKeyPairAgent(
            SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
            comment: 'termino-test',
          ),
        ),
      );
      final transcript = StringBuffer();
      backend.output.listen(
        (chunk) => transcript.write(utf8.decode(chunk, allowMalformed: true)),
      );
      await backend.start();

      await _runAndWait(
        backend,
        transcript,
        r'echo "sock=[$SSH_AUTH_SOCK]" | tr -d "\n"; echo DO""NE',
        'DONE',
      );

      final output = transcript.toString();
      expect(
        output,
        isNot(contains('sock=[]')),
        reason: 'sshd sets SSH_AUTH_SOCK when forwarding is requested',
      );
      expect(output, contains('sock=[/'), reason: 'it is a socket path');
      await backend.close();
    });
  });

  group('host key verification', () {
    test('a changed host key blocks the connection', () async {
      // Connect once and trust the ed25519 key.
      final first = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );
      await first.start();
      await first.close();
      expect(knownHosts.entries, hasLength(1));

      // Restart on the *same port* presenting a different key of the same
      // type. The port matters: a different port is a different host as far as
      // known_hosts is concerned, and the check would rightly say "unknown".
      final port = server.port;
      await server.stop();
      server = await TestSshd.start(port: port, hostKey: 'client_ed25519');

      final second = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        // Even a user who would click "trust" must not be asked.
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );

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
      expect(second.state, BackendConnectionState.error);
      expect(
        knownHosts.entries.single.keyType,
        'ssh-ed25519',
        reason: 'the stored key must be untouched by a refused connection',
      );
      await second.close();
    });

    test('the mismatch is never offered as a prompt', () async {
      final first = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
      );
      await first.start();
      await first.close();

      final port = server.port;
      await server.stop();
      server = await TestSshd.start(port: port, hostKey: 'client_ed25519');

      var asked = false;
      final second = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: (check) async {
          asked = true;
          return true;
        },
        prompts: keyAuth(),
      );

      await expectLater(second.start(), throwsA(isA<TerminalBackendFailure>()));

      expect(
        asked,
        isFalse,
        reason: 'a changed key must never reach a dialog with an accept button',
      );
      await second.close();
    });

    test('refusing an unknown key refuses the connection', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: refuseUnknown,
        prompts: keyAuth(),
      );

      await expectLater(
        backend.start(),
        throwsA(isA<TerminalBackendFailure>()),
      );
      expect(knownHosts.entries, isEmpty);
      await backend.close();
    });
  });

  group('failures', () {
    test('a wrong key fails as an authentication failure', () async {
      final backend = SshBackend(
        host: hostProfile(),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(pem: TestSshd.untrustedPrivateKey),
      );

      await expectLater(
        backend.start(),
        throwsA(
          isA<TerminalBackendFailure>().having(
            (failure) => failure.kind,
            'kind',
            TerminalBackendFailureKind.authentication,
          ),
        ),
      );
      await backend.close();
    });

    test('an unreachable host fails as a network failure', () async {
      final backend = SshBackend(
        host: hostProfile(port: 1),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
        connectTimeout: const Duration(seconds: 3),
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
    });

    test('no failure message leaks an exception string', () async {
      final backend = SshBackend(
        host: hostProfile(port: 1),
        verifier: verifier,
        onHostKeyPrompt: acceptUnknown,
        prompts: keyAuth(),
        connectTimeout: const Duration(seconds: 3),
      );

      try {
        await backend.start();
        fail('expected a failure');
      } on TerminalBackendFailure catch (failure) {
        expect(failure.message, isNot(contains('Exception')));
        expect(failure.message, isNot(contains('SSHSocketError')));
        expect(failure.cause, isNotNull, reason: 'kept for logs only');
      }
      await backend.close();
    });
  });
}
