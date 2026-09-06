import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/infrastructure/backends/local_pty/local_pty_backend.dart';

/// Shell discovery needs `dart:io` but not the native PTY plugin, so unlike the
/// backend itself it can be tested in a plain unit test. Spawning a process is
/// covered by `integration_test/local_pty_test.dart`.
void main() {
  group('discoverShellProfiles', () {
    test('only offers shells that actually exist', () {
      for (final profile in discoverShellProfiles()) {
        expect(
          File(profile.executable).existsSync(),
          isTrue,
          reason: '${profile.executable} was offered but is not on disk',
        );
      }
    });

    test('finds at least one shell on this machine', () {
      // True of every platform this test can run on: macOS, Linux, Windows.
      expect(discoverShellProfiles(), isNotEmpty);
    });

    test('gives every profile a distinct id', () {
      final ids = discoverShellProfiles().map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('never offers the same shell twice under two names', () {
      // Android has /bin/sh symlinked to /system/bin/sh, so both candidates
      // matched and the picker listed one shell twice — under one id, which is
      // what a saved preference refers to.
      final resolved = discoverShellProfiles()
          .map((p) => File(p.executable).resolveSymbolicLinksSync())
          .toList();
      expect(resolved.toSet(), hasLength(resolved.length));
    });

    test(r"prefers the user's own $SHELL first when it is set", () {
      final userShell = Platform.environment['SHELL'];
      if (userShell == null || !File(userShell).existsSync()) {
        markTestSkipped(r'No usable $SHELL on this machine');
        return;
      }

      final first = discoverShellProfiles().first;
      expect(first.executable, userShell);
      expect(
        first.arguments,
        contains('-l'),
        reason: 'a login shell picks up the user real PATH and aliases',
      );
    });

    test('the default profile is the first discovered', () {
      expect(defaultShellProfile(), discoverShellProfiles().first);
    });

    test('profiles are named for humans, not paths', () {
      for (final profile in discoverShellProfiles()) {
        expect(profile.name, isNotEmpty);
        expect(profile.name, isNot(startsWith('/')));
      }
    });
  });
}
