import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

/// The shell backend, the file browser and port forwarding all reach a server
/// through the same factory, so they must all describe a failure the same way.
/// Before this existed, only the shell classified errors: SFTP received the raw
/// `dartssh2` exception and could say nothing more useful than "the connection
/// failed", which is the same sentence for a typo in a password and for a
/// changed host key.
void main() {
  const host = SshHost(
    id: 'h',
    label: 'Server',
    hostname: 'example.test',
    username: 'someone',
    port: 2222,
  );

  group('mapSshFailure', () {
    test('classifies a rejected credential as authentication', () {
      final failure = mapSshFailure(
        SSHAuthFailError('no more methods'),
        host: host,
      );
      expect(failure.kind, TerminalBackendFailureKind.authentication);
      expect(failure.message, contains(host.target));
    });

    test('classifies an unreachable host as network', () {
      final failure = mapSshFailure(SSHSocketError('refused'), host: host);
      expect(failure.kind, TerminalBackendFailureKind.network);
      expect(failure.message, contains('example.test:2222'));
    });

    test('a refused host key outranks whatever the handshake threw', () {
      final failure = mapSshFailure(
        SSHAuthFailError('no more methods'),
        host: host,
        refused: const HostKeyCheck(
          verdict: HostKeyVerdict.mismatch,
          host: 'example.test',
          port: 2222,
          keyType: 'ssh-ed25519',
          fingerprint: 'SHA256:new',
        ),
      );
      expect(failure.kind, TerminalBackendFailureKind.hostKeyMismatch);
      expect(failure.message, contains('has changed'));
    });

    test('an already-classified failure passes through unchanged', () {
      const original = TerminalBackendFailure(
        TerminalBackendFailureKind.unsupported,
        'No local shell here.',
      );
      expect(mapSshFailure(original, host: host), same(original));
    });

    test('no message repeats the underlying exception text', () {
      // A raw exception string never reaches the user; the cause is for logs.
      final failure = mapSshFailure(
        StateError('internal detail nobody should read'),
        host: host,
      );
      expect(failure.message, isNot(contains('internal detail')));
      expect(failure.cause, isA<StateError>());
    });
  });
}
