import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/infrastructure/ssh/import/ssh_config_import.dart';

void main() {
  late Directory home;
  late Directory ssh;

  setUp(() async {
    home = await Directory.systemTemp.createTemp('termino-home-');
    ssh = await Directory('${home.path}/.ssh').create();
  });

  tearDown(() async {
    if (home.existsSync()) await home.delete(recursive: true);
  });

  SshConfigImporter importer() => SshConfigImporter(homeDirectory: home.path);

  test('reports availability from the directory', () async {
    expect(importer().isAvailable, isTrue);

    await ssh.delete(recursive: true);
    expect(importer().isAvailable, isFalse);
  });

  test('returns nothing when there is no config file', () async {
    expect(await importer().readConfig(), isEmpty);
  });

  test('parses the user config', () async {
    await File('${ssh.path}/config').writeAsString('''
Host build-01
    HostName build-01.example.com
    User deploy
    Port 2222
''');

    final hosts = await importer().readConfig();

    expect(hosts, hasLength(1));
    expect(hosts.single.hostName, 'build-01.example.com');
    expect(hosts.single.user, 'deploy');
    expect(hosts.single.port, 2222);
  });

  test('follows a literal Include', () async {
    await File('${ssh.path}/extra').writeAsString('''
Host included
    HostName included.example.com
''');
    await File('${ssh.path}/config').writeAsString('''
Include extra

Host main
    HostName main.example.com
''');

    final hosts = await importer().readConfig();

    expect(
      hosts.map((h) => h.patterns.first),
      containsAll(['included', 'main']),
    );
  });

  test('ignores a glob Include rather than failing', () async {
    await File('${ssh.path}/config').writeAsString('''
Include conf.d/*.conf

Host main
    HostName main.example.com
''');

    final hosts = await importer().readConfig();

    expect(hosts.map((h) => h.patterns.first), contains('main'));
  });

  group('known_hosts', () {
    setUp(() async {
      final source = File('test/fixtures/keys/known_hosts').readAsStringSync();
      await File('${ssh.path}/known_hosts').writeAsString(source);
    });

    test('imports only keys for hosts the user actually has', () async {
      final imported = await importer().readKnownHosts(
        hosts: [(host: 'build-01', port: 22)],
      );

      expect(imported, isNotEmpty);
      expect(imported.every((entry) => entry.host == 'build-01'), isTrue);
      expect(
        imported.map((entry) => entry.keyType),
        containsAll(['ssh-ed25519', 'ssh-rsa']),
      );
    });

    test('matches a wildcard entry for a host under it', () async {
      final imported = await importer().readKnownHosts(
        hosts: [(host: 'anything.example.com', port: 22)],
      );

      expect(imported, isNotEmpty);
    });

    test('imports nothing for an unrelated host', () async {
      final imported = await importer().readKnownHosts(
        hosts: [(host: 'not-in-the-file', port: 22)],
      );

      expect(imported, isEmpty);
    });

    test('marks entries as imported', () async {
      final imported = await importer().readKnownHosts(
        hosts: [(host: 'build-01', port: 22)],
      );

      expect(
        imported.every((entry) => entry.publicKey != null),
        isTrue,
        reason: 'the file has the key blob, so it is kept',
      );
    });

    test('returns nothing when there is no known_hosts file', () async {
      await File('${ssh.path}/known_hosts').delete();

      expect(
        await importer().readKnownHosts(hosts: [(host: 'build-01', port: 22)]),
        isEmpty,
      );
    });
  });
}
