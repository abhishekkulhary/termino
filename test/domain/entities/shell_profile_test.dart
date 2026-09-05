import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/shell_profile.dart';

void main() {
  group('ShellProfile', () {
    test('renders a command line for display', () {
      const profile = ShellProfile(
        id: 'bash',
        name: 'bash',
        executable: '/bin/bash',
        arguments: ['-l'],
      );

      expect(profile.commandLine, '/bin/bash -l');
    });

    test('quotes parts containing spaces', () {
      const profile = ShellProfile(
        id: 'git-bash',
        name: 'Git Bash',
        executable: r'C:\Program Files\Git\bin\bash.exe',
        arguments: ['--login', '-i'],
      );

      expect(
        profile.commandLine,
        r'"C:\Program Files\Git\bin\bash.exe" --login -i',
      );
    });

    test('round-trips through JSON', () {
      const profile = ShellProfile(
        id: 'zsh',
        name: 'zsh (login)',
        executable: '/bin/zsh',
        arguments: ['-l'],
        environment: {'FOO': 'bar'},
        workingDirectory: '/tmp',
      );

      expect(ShellProfile.fromJson(profile.toJson()), profile);
    });

    test('defaults are empty rather than null', () {
      const profile = ShellProfile(id: 'sh', name: 'sh', executable: '/bin/sh');

      expect(profile.arguments, isEmpty);
      expect(profile.environment, isEmpty);
      expect(profile.workingDirectory, isNull);
    });

    test('compares by value', () {
      const a = ShellProfile(id: 'sh', name: 'sh', executable: '/bin/sh');
      const b = ShellProfile(id: 'sh', name: 'sh', executable: '/bin/sh');
      const c = ShellProfile(id: 'sh', name: 'sh', executable: '/bin/bash');

      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
