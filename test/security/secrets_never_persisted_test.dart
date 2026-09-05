// The promise SECURITY.md makes, checked rather than asserted in prose:
// secrets live in the platform keystore and nowhere else.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/identities/application/identity_service.dart';
import 'package:termino/infrastructure/storage/database.dart';

import '../support/test_database.dart';

/// Strings that must never appear anywhere but the keystore.
const _password = 'correct-horse-battery-staple';
const _passphrase = 'a-very-secret-passphrase';

void main() {
  test('a generated private key never reaches the database file', () async {
    final file = File(
      '${Directory.systemTemp.createTempSync('termino-db-').path}/termino.sqlite',
    );
    addTearDown(() {
      if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
    });

    final database = TerminoDatabase.withExecutor(NativeDatabase(file));
    final secrets = InMemorySecretStore();
    final container = testContainer(database: database, secrets: secrets);
    addTearDown(container.dispose);

    // Generate a key with a passphrase and save a host with a password.
    final identity = await container
        .read(identityServiceProvider)
        .generate(
          name: 'Test key',
          keyType: SshKeyType.ed25519,
          passphrase: _passphrase,
          rememberPassphrase: true,
        );

    await container
        .read(sshHostRepositoryProvider)
        .save(
          SshHost(
            id: 'h1',
            label: 'Server',
            hostname: 'example.com',
            username: 'root',
            identityId: identity.id,
            hasSavedPassword: true,
          ),
        );
    await container
        .read(secretStoreProvider)
        .write('host.h1.password', _password);

    // Flush everything to disk before reading the file back.
    await database.close();

    final bytes = await file.readAsBytes();
    final contents = String.fromCharCodes(bytes);

    final privateKey = secrets.values[identity.secretRef]!;
    expect(
      privateKey,
      contains('PRIVATE KEY'),
      reason: 'the key really was stored in the keystore',
    );

    expect(
      contents,
      isNot(contains('PRIVATE KEY')),
      reason: 'no key material may reach the database file',
    );
    expect(contents, isNot(contains(_passphrase)));
    expect(contents, isNot(contains(_password)));

    // The public half, by contrast, is expected to be there.
    expect(
      contents,
      contains(identity.fingerprint),
      reason: 'metadata is stored, which is the point of the database',
    );
  });

  test('secrets do not survive the logger', () async {
    final logger = AppLogger()..attach(level: Level.ALL);
    addTearDown(logger.detach);

    logger.redactor
      ..registerSecret(_password)
      ..registerSecret(_passphrase);

    Loggers.ssh
      ..info('Authenticating with password $_password')
      ..warning('Key passphrase was $_passphrase')
      ..info(
        'Loaded key -----BEGIN OPENSSH PRIVATE KEY-----\n'
        'b3BlbnNzaC1rZXktdjEAAAAABG5vbmU\n'
        '-----END OPENSSH PRIVATE KEY-----',
      );

    await Future<void>.delayed(Duration.zero);

    final recorded = logger.recent.join('\n');
    expect(recorded, isNotEmpty, reason: 'the lines were logged at all');
    expect(recorded, isNot(contains(_password)));
    expect(recorded, isNot(contains(_passphrase)));
    expect(recorded, isNot(contains('b3BlbnNzaC1rZXktdjEAAAAABG5vbmU')));
  });

  test('deleting an identity removes its key material', () async {
    final secrets = InMemorySecretStore();
    final container = testContainer(secrets: secrets);
    addTearDown(container.dispose);

    final identity = await container
        .read(identityServiceProvider)
        .generate(
          name: 'Disposable',
          keyType: SshKeyType.ed25519,
          passphrase: _passphrase,
          rememberPassphrase: true,
        );

    expect(secrets.values, contains(identity.secretRef));
    expect(secrets.values, contains(identity.passphraseRef));

    await container.read(identityServiceProvider).delete(identity.id);

    expect(
      secrets.values,
      isNot(contains(identity.secretRef)),
      reason: 'an unreachable private key must not be left behind',
    );
    expect(secrets.values, isNot(contains(identity.passphraseRef)));
  });

  test('deleting a host removes its saved password', () async {
    final secrets = InMemorySecretStore();
    final container = testContainer(secrets: secrets);
    addTearDown(container.dispose);

    const host = SshHost(
      id: 'h2',
      label: 'Server',
      hostname: 'example.com',
      username: 'root',
      hasSavedPassword: true,
    );
    await container.read(sshHostRepositoryProvider).save(host);
    await container
        .read(secretStoreProvider)
        .write(host.passwordRef, _password);

    await container.read(sshHostRepositoryProvider).delete(host.id);

    expect(secrets.values, isNot(contains(host.passwordRef)));
  });
}
