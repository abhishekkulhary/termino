// Integration tests for the real local PTY. These need a device — run them
// with, for example:
//
//     flutter test integration_test/local_pty_test.dart -d macos
//
// They deliberately exercise a real shell rather than a mock: the whole point
// is to find out how flutter_pty actually behaves, which is not something a
// unit test can tell us.
@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/shell_profile.dart';
import 'package:termino/infrastructure/backends/local_pty/local_pty_backend.dart';

/// A minimal, predictable shell: no profile files, no prompt, no colour.
ShellProfile _sh(List<String> arguments) => ShellProfile(
  id: 'test',
  name: 'sh',
  executable: Platform.isWindows ? 'cmd.exe' : '/bin/sh',
  arguments: arguments,
);

/// Collects everything a backend emits until it reaches a terminal state.
Future<String> _runToCompletion(TerminalBackend backend) async {
  final output = StringBuffer();
  final done = Completer<void>();

  backend.output.listen(
    (chunk) => output.write(utf8.decode(chunk, allowMalformed: true)),
    onDone: () {
      if (!done.isCompleted) done.complete();
    },
  );

  await backend.start();
  await backend.exitCode.timeout(
    const Duration(seconds: 20),
    onTimeout: () => null,
  );
  // Give any trailing output a chance to arrive.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return output.toString();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('shell discovery', () {
    test('finds at least one shell on this machine', () {
      final profiles = discoverShellProfiles();
      expect(profiles, isNotEmpty);
      for (final profile in profiles) {
        expect(
          File(profile.executable).existsSync(),
          isTrue,
          reason: '${profile.executable} was offered but does not exist',
        );
      }
    });

    test('the default profile is the first discovered', () {
      expect(defaultShellProfile(), isNotNull);
      expect(defaultShellProfile()!.id, discoverShellProfiles().first.id);
    });
  });

  group('LocalPtyBackend', () {
    test('runs a command and reports its output', () async {
      final backend = createLocalPtyBackend(
        profile: _sh(['-c', 'echo hello-from-pty']),
      );

      final output = await _runToCompletion(backend);

      expect(output, contains('hello-from-pty'));
      await backend.close();
    });

    test(
      'delivers the final line of output before the process exits',
      () async {
        // This is the behaviour flutter_pty's own documentation warns about:
        // "There is no guarantee that output have finished reporting the
        // buffered output of the process when the returned future completes."
        // If this fails, the last thing a command prints is being lost, which
        // is unacceptable for a terminal — and decides whether we move to the
        // flutter_pty2 fork.
        for (var attempt = 0; attempt < 5; attempt++) {
          final backend = createLocalPtyBackend(
            profile: _sh(['-c', 'echo FINAL-LINE-MARKER']),
          );
          final output = await _runToCompletion(backend);
          await backend.close();

          expect(
            output,
            contains('FINAL-LINE-MARKER'),
            reason: 'output was lost on attempt $attempt',
          );
        }
      },
    );

    test('reports the exit code', () async {
      final backend = createLocalPtyBackend(profile: _sh(['-c', 'exit 7']));

      await _runToCompletion(backend);

      expect(await backend.exitCode, 7);
      expect(backend.state, BackendConnectionState.closed);
      await backend.close();
    });

    test('an interactive shell accepts input and echoes it back', () async {
      final backend = createLocalPtyBackend(profile: _sh(const []));
      final output = StringBuffer();
      backend.output.listen(
        (chunk) => output.write(utf8.decode(chunk, allowMalformed: true)),
      );

      await backend.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      backend.write(Uint8List.fromList(utf8.encode('echo round-trip\n')));
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(output.toString(), contains('round-trip'));
      await backend.close();
    });

    test('resize reaches the child process', () async {
      // `stty size` prints "rows cols" as the child sees them, which is the
      // only way to prove the resize actually took effect rather than being
      // silently swallowed — and to catch the rows/columns argument order.
      final backend = createLocalPtyBackend(profile: _sh(const []));
      final output = StringBuffer();
      backend.output.listen(
        (chunk) => output.write(utf8.decode(chunk, allowMalformed: true)),
      );

      await backend.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      backend.resize(101, 37);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      backend.write(Uint8List.fromList(utf8.encode('stty size\n')));
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(
        output.toString(),
        contains('37 101'),
        reason: 'stty prints "rows columns"; 37 rows by 101 columns expected',
      );
      await backend.close();
    });

    test(
      'a missing executable fails with a spawn failure, not a crash',
      () async {
        final backend = createLocalPtyBackend(
          profile: const ShellProfile(
            id: 'missing',
            name: 'missing',
            executable: '/definitely/not/a/real/shell',
          ),
        );

        await expectLater(
          backend.start(),
          throwsA(
            isA<TerminalBackendFailure>().having(
              (failure) => failure.kind,
              'kind',
              TerminalBackendFailureKind.spawn,
            ),
          ),
        );
        expect(backend.state, BackendConnectionState.error);
        await backend.close();
      },
    );

    test('closing terminates the child', () async {
      final backend = createLocalPtyBackend(profile: _sh(['-c', 'sleep 60']));
      await backend.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      await backend.close();

      expect(backend.state, BackendConnectionState.closed);
    });
  });
}
