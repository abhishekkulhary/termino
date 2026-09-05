import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/ssh/ssh_config.dart';

String get _fixture => File('test/fixtures/keys/ssh_config').readAsStringSync();

void main() {
  late List<SshConfigHost> hosts;

  setUpAll(() => hosts = SshConfig.parse(_fixture));

  SshConfigHost resolve(String alias) {
    final resolved = SshConfig.resolve(hosts, alias);
    expect(resolved, isNotNull, reason: 'no block matched $alias');
    return resolved!;
  }

  group('parse', () {
    test('reads every Host block', () {
      expect(hosts.map((h) => h.patterns.first), contains('build-01'));
      expect(hosts.map((h) => h.patterns.first), contains('bastion'));
      expect(hosts.map((h) => h.patterns.first), contains('db-*'));
    });

    test('reads the keywords Termino acts on', () {
      final build = hosts.firstWhere((h) => h.patterns.first == 'build-01');

      expect(build.hostName, 'build-01.internal.example.com');
      expect(build.user, 'deploy');
      expect(build.port, 2222);
      expect(build.identityFiles, [
        '~/.ssh/id_ed25519',
        '~/.ssh/id_rsa',
      ], reason: 'OpenSSH allows several IdentityFile lines, in order');
    });

    test('accepts the Keyword=value form', () {
      final equals = hosts.firstWhere((h) => h.patterns.first == 'equals');

      expect(equals.hostName, 'equals.example.com');
      expect(equals.port, 2022);
    });

    test('strips quotes from paths', () {
      final quoted = hosts.firstWhere((h) => h.patterns.first == 'quoted');

      expect(quoted.identityFiles.single, '~/.ssh/key with spaces');
    });

    test('ignores comments', () {
      expect(hosts.any((h) => h.patterns.first.startsWith('#')), isFalse);
    });

    test('a Match block ends the preceding Host block', () {
      // We cannot evaluate Match conditions without a live connection, so its
      // settings must not leak into whatever follows it.
      final after = hosts.firstWhere((h) => h.patterns.first == 'after-match');

      expect(after.user, isNull);
      expect(after.hostName, 'after.example.com');
    });

    test('unknown keywords are ignored rather than fatal', () {
      final parsed = SshConfig.parse('''
Host weird
    HostName weird.example.com
    ControlMaster auto
    SendEnv LANG LC_*
    NoSuchKeyword whatever
''');

      expect(parsed.single.hostName, 'weird.example.com');
    });
  });

  group('resolve', () {
    test('applies the matching block', () {
      final build = resolve('build-01');

      expect(build.hostName, 'build-01.internal.example.com');
      expect(build.user, 'deploy');
      expect(build.port, 2222);
    });

    test('inherits from Host * without overriding a specific value', () {
      final build = resolve('build-01');

      expect(
        build.serverAliveInterval,
        60,
        reason: 'inherited from the Host * block',
      );
      expect(
        build.forwardAgent,
        isFalse,
        reason: 'Host * sets ForwardAgent no and nothing overrides it',
      );
    });

    test('the first matching value wins, as OpenSSH specifies', () {
      // `Host db-*` sets ForwardAgent yes and appears before nothing else
      // relevant; `Host *` sets no. OpenSSH takes the first occurrence.
      final db = resolve('db-primary');

      expect(db.user, 'postgres');
      expect(db.proxyJump, 'bastion');
      expect(db.forwardAgent, isTrue);
    });

    test('a catch-all placed first overrides everything after it', () {
      // OpenSSH uses the first value it obtains for each keyword, which is why
      // `Host *` belongs at the end of a config. Getting this backwards is a
      // classic misconfiguration, and the parser must reproduce it faithfully
      // rather than doing what the user probably meant.
      final parsed = SshConfig.parse('''
Host *
    User catch-all

Host specific
    User specific-user
''');

      expect(SshConfig.resolve(parsed, 'specific')?.user, 'catch-all');
    });

    test('the same config with the catch-all last behaves as intended', () {
      final parsed = SshConfig.parse('''
Host specific
    User specific-user

Host *
    User catch-all
''');

      expect(SshConfig.resolve(parsed, 'specific')?.user, 'specific-user');
      expect(SshConfig.resolve(parsed, 'other')?.user, 'catch-all');
    });

    test('wildcard patterns match', () {
      expect(resolve('db-replica-3').user, 'postgres');
    });

    test('an unknown alias still inherits Host *', () {
      final unknown = resolve('never-heard-of-it');

      expect(unknown.serverAliveInterval, 60);
      expect(unknown.hostName, isNull);
    });

    test('a negated pattern excludes a host', () {
      final parsed = SshConfig.parse('''
Host !secret.example.com *.example.com
    User general
''');

      expect(SshConfig.resolve(parsed, 'ok.example.com')?.user, 'general');
      expect(SshConfig.resolve(parsed, 'secret.example.com')?.user, isNull);
    });
  });

  group('importability', () {
    test('a literal alias is importable', () {
      expect(
        hosts.firstWhere((h) => h.patterns.first == 'build-01').isImportable,
        isTrue,
      );
    });

    test('a wildcard block is not', () {
      expect(
        hosts.firstWhere((h) => h.patterns.first == 'db-*').isImportable,
        isFalse,
      );
      expect(
        hosts.firstWhere((h) => h.patterns.first == '*').isImportable,
        isFalse,
      );
    });
  });
}
