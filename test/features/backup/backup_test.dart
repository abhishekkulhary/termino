import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/backup/application/backup_file.dart';
import 'package:termino/features/backup/application/backup_service.dart';
import 'package:termino/features/settings/application/settings_controller.dart';

import '../../support/test_database.dart';

/// A backup is a file people email to themselves and forget about. What it
/// must never contain matters more than what it does.
void main() {
  final host = SshHost(
    id: 'h1',
    label: 'Build server',
    hostname: 'build-01.example.com',
    username: 'deploy',
    identityId: 'k1',
    hasSavedPassword: true,
    lastConnectedAt: DateTime.utc(2026, 9),
  );

  final snippet = Snippet(
    id: 's1',
    name: 'Tail the log',
    body: 'tail -f app.log',
    createdAt: DateTime.utc(2026),
  );

  const forward = PortForward(
    id: 'f1',
    hostId: 'h1',
    kind: PortForwardKind.local,
    listenPort: 8080,
    destinationHost: 'localhost',
    destinationPort: 80,
  );

  group('what a backup carries', () {
    test('holds hosts, snippets, tunnels and settings', () {
      final file = BackupFile(
        hosts: [host],
        snippets: [snippet],
        forwards: const [forward],
        settings: const TerminalSettings(fontSize: 18),
      );

      final restored = BackupFile.decode(file.encode());

      expect(restored.hosts.single.label, 'Build server');
      expect(restored.snippets.single.name, 'Tail the log');
      expect(restored.forwards.single.listenPort, 8080);
      expect(restored.settings?.fontSize, 18);
    });

    test('never claims a password it does not have', () {
      // The password itself was never in the file — it is in the keystore —
      // but carrying the flag would make a restored host claim a saved
      // password and then fail to connect without ever offering a prompt.
      final encoded = BackupFile(
        hosts: [host],
        snippets: const [],
        forwards: const [],
      ).encode();

      expect(BackupFile.decode(encoded).hosts.single.hasSavedPassword, isFalse);
    });

    test('contains nothing that looks like key material', () {
      final encoded = BackupFile(
        hosts: [host],
        snippets: [snippet],
        forwards: const [forward],
        settings: const TerminalSettings(),
      ).encode();

      expect(encoded, isNot(contains('PRIVATE KEY')));

      // Not a substring search: the words appear in the file's own list of
      // what it excludes. What matters is that no *field* carries them.
      final fields = <String>{};
      void collect(Object? node) {
        if (node is Map<String, dynamic>) {
          fields.addAll(node.keys);
          node.values.forEach(collect);
        } else if (node is List) {
          node.forEach(collect);
        }
      }

      collect(jsonDecode(encoded));

      for (final forbidden in [
        'passphrase',
        'password',
        'privateKey',
        'secret',
      ]) {
        expect(
          fields.map((f) => f.toLowerCase()),
          isNot(contains(forbidden.toLowerCase())),
          reason: 'a backup must carry no field called $forbidden',
        );
      }

      expect(
        encoded,
        contains('private keys'),
        reason: 'the file names its own exclusions, for whoever reads it',
      );
    });

    test('carries no trusted host keys', () {
      // Those are decisions someone made by checking a fingerprint. Carrying
      // them would mean the first connection on a new device silently skips
      // the check that mattered.
      final decoded = jsonDecode(
        BackupFile(
          hosts: [host],
          snippets: const [],
          forwards: const [],
        ).encode(),
      ) as Map<String, dynamic>;

      expect(decoded.keys, isNot(contains('knownHosts')));
      expect(decoded.keys, isNot(contains('trustedKeys')));
    });
  });

  group('reading a file that is not one', () {
    test('rejects arbitrary JSON with a sentence', () {
      expect(
        () => BackupFile.decode('{"hello":"world"}'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('not a Termino backup'),
          ),
        ),
      );
    });

    test('rejects text that is not JSON at all', () {
      expect(
        () => BackupFile.decode('not json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('refuses a format from the future rather than guessing', () {
      final future = jsonEncode({
        'kind': 'termino.backup',
        'version': BackupFile.currentVersion + 1,
      });

      expect(
        () => BackupFile.decode(future),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
    });

    test('a damaged section is reported, not silently dropped', () {
      final damaged = jsonEncode({
        'kind': 'termino.backup',
        'version': 1,
        'hosts': 'not a list',
      });

      expect(() => BackupFile.decode(damaged), throwsA(isA<FormatException>()));
    });
  });

  group('restoring', () {
    test('merges rather than replacing', () async {
      final container = testContainer();
      addTearDown(container.dispose);

      // Something already here that the backup does not mention.
      await container
          .read(sshHostRepositoryProvider)
          .save(
            const SshHost(
              id: 'existing',
              label: 'Already here',
              hostname: 'local',
              username: 'me',
            ),
          );

      final backup = BackupFile(
        hosts: [host],
        snippets: const [],
        forwards: const [],
      ).encode();

      final summary = await container
          .read(backupServiceProvider.notifier)
          .restore(backup);

      final hosts = await container.read(sshHostRepositoryProvider).all();
      expect(hosts.map((h) => h.id), containsAll(['existing', 'h1']));
      expect(summary.hosts, 1);
      expect(summary.description, contains('1 host'));
    });

    test('does not send a set-up device back through onboarding', () async {
      final container = testContainer();
      addTearDown(container.dispose);
      await container.read(settingsProvider.notifier).completeOnboarding();

      const backup = BackupFile(
        hosts: [],
        snippets: [],
        forwards: [],
        // A backup taken before onboarding was finished.
        settings: TerminalSettings(fontSize: 20),
      );

      await container
          .read(backupServiceProvider.notifier)
          .restore(backup.encode());

      final settings = container.read(currentSettingsProvider);
      expect(settings.fontSize, 20, reason: 'the preference came across');
      expect(
        settings.onboardingComplete,
        isTrue,
        reason: 'the first-run flag is not a preference and must not travel',
      );
    });

    test('an empty backup says so rather than looking broken', () async {
      final container = testContainer();
      addTearDown(container.dispose);

      final summary = await container
          .read(backupServiceProvider.notifier)
          .restore(
            const BackupFile(hosts: [], snippets: [], forwards: []).encode(),
          );

      expect(summary.isEmpty, isTrue);
      expect(summary.description, 'That backup was empty.');
    });
  });

  test('export and restore round-trips through the repositories', () async {
    final source = testContainer();
    addTearDown(source.dispose);
    await source.read(sshHostRepositoryProvider).save(host);
    await source.read(snippetRepositoryProvider).save(snippet);
    await source.read(portForwardRepositoryProvider).save(forward);

    final contents = await source.read(backupServiceProvider.notifier).export();

    final destination = testContainer();
    addTearDown(destination.dispose);
    await destination.read(backupServiceProvider.notifier).restore(contents);

    expect(
      (await destination.read(sshHostRepositoryProvider).all()).single.label,
      'Build server',
    );
    expect(
      (await destination.read(snippetRepositoryProvider).all()).single.name,
      'Tail the log',
    );
    expect(
      (await destination.read(portForwardRepositoryProvider).all())
          .single
          .listenPort,
      8080,
    );
  });
}
