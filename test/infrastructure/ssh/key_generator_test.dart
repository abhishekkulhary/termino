@Timeout(Duration(seconds: 180))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/key_generator.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_sshd.dart';

/// Writes [key] to a temporary file with the permissions ssh-keygen expects.
Future<File> writePrivateKey(GeneratedKey key, Directory dir) async {
  final file = File('${dir.path}/key');
  await file.writeAsString(key.privateKeyPem);
  await Process.run('chmod', ['600', file.path]);
  return file;
}

void main() {
  final generator = SshKeyGenerator();
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('termino-keygen-');
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  group('Ed25519', () {
    test('produces a key ssh-keygen accepts', () async {
      final key = generator.generateEd25519(comment: 'termino@test');
      final file = await writePrivateKey(key, temp);

      final result = await Process.run('ssh-keygen', ['-y', '-f', file.path]);

      expect(
        result.exitCode,
        0,
        reason: 'ssh-keygen rejected the key: ${result.stderr}',
      );
      expect(result.stdout.toString(), startsWith('ssh-ed25519 '));
    });

    test('its fingerprint matches what ssh-keygen computes', () async {
      final key = generator.generateEd25519(comment: 'termino@test');
      final file = await writePrivateKey(key, temp);

      final result = await Process.run('ssh-keygen', ['-lf', file.path]);
      final reported = result.stdout.toString().split(' ')[1];

      expect(key.fingerprint, reported);
    });

    test('the public key line derives from the private key', () async {
      final key = generator.generateEd25519(comment: 'termino@test');
      final file = await writePrivateKey(key, temp);

      // `ssh-keygen -y` recomputes the public half from the private one.
      final derived = (await Process.run('ssh-keygen', [
        '-y',
        '-f',
        file.path,
      ])).stdout.toString().trim();

      expect(key.publicKeyLine, startsWith(derived));
      expect(key.publicKeyLine, endsWith('termino@test'));
    });

    test('dartssh2 can parse the key it generated', () {
      final key = generator.generateEd25519();

      final parsed = SSHKeyPair.fromPem(key.privateKeyPem);

      expect(parsed, hasLength(1));
      expect(parsed.single.type, 'ssh-ed25519');
    });

    test('a passphrase encrypts the key at rest', () async {
      final key = generator.generateEd25519(passphrase: 'a-good-passphrase');

      expect(SSHKeyPair.isEncryptedPem(key.privateKeyPem), isTrue);
      expect(
        () => SSHKeyPair.fromPem(key.privateKeyPem),
        throwsA(isA<Object>()),
        reason: 'the wrong passphrase must not decrypt it',
      );
      expect(
        SSHKeyPair.fromPem(key.privateKeyPem, 'a-good-passphrase'),
        hasLength(1),
      );
    });

    test('an encrypted key is accepted by ssh-keygen too', () async {
      final key = generator.generateEd25519(passphrase: 'a-good-passphrase');
      final file = await writePrivateKey(key, temp);

      final result = await Process.run('ssh-keygen', [
        '-y',
        '-P',
        'a-good-passphrase',
        '-f',
        file.path,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
    });

    test('two keys are different', () {
      expect(
        generator.generateEd25519().publicKeyLine,
        isNot(generator.generateEd25519().publicKeyLine),
      );
    });

    test('reports its type', () {
      expect(generator.generateEd25519().keyType, SshKeyType.ed25519);
    });
  });

  group('RSA', () {
    test('produces a 2048-bit key ssh-keygen accepts', () async {
      // 2048 rather than 4096 so the suite stays quick; the 4096 path is
      // exercised below.
      final key = generator.generateRsa(bits: 2048, comment: 'termino@test');
      final file = await writePrivateKey(key, temp);

      final result = await Process.run('ssh-keygen', ['-lf', file.path]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString(), startsWith('2048 '));
      expect(result.stdout.toString().split(' ')[1], key.fingerprint);
    });

    test('generates 4096 bits by default', () async {
      final key = generator.generateRsa(comment: 'termino@test');
      final file = await writePrivateKey(key, temp);

      final result = await Process.run('ssh-keygen', ['-lf', file.path]);

      expect(result.stdout.toString(), startsWith('4096 '));
    }, timeout: const Timeout(Duration(seconds: 180)));

    test('refuses weak key sizes outright', () {
      expect(
        () => generator.generateRsa(bits: 1024),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('dartssh2 can parse the key it generated', () {
      final key = generator.generateRsa(bits: 2048);

      // dartssh2 reports the modern signature algorithm here, not the legacy
      // `ssh-rsa` blob type — SHA-1 RSA signatures are deprecated.
      expect(
        SSHKeyPair.fromPem(key.privateKeyPem).single.type,
        startsWith('rsa-sha2-'),
      );
    });

    test('the public key line uses the blob type, not the signature type', () {
      final key = generator.generateRsa(bits: 2048);

      expect(
        key.publicKeyLine,
        startsWith('ssh-rsa '),
        reason: 'an authorized_keys line starting with rsa-sha2-256 is invalid',
      );
    });

    test('the public key line matches what ssh-keygen derives', () async {
      final key = generator.generateRsa(bits: 2048, comment: 'termino@test');
      final file = await writePrivateKey(key, temp);

      final derived = (await Process.run('ssh-keygen', [
        '-y',
        '-f',
        file.path,
      ])).stdout.toString().trim();

      expect(key.publicKeyLine, startsWith(derived));
    });
  });

  group('end to end', () {
    test('a generated key can actually authenticate to a server', () async {
      if (!TestSshd.isSupported) {
        markTestSkipped('needs sshd');
        return;
      }

      // Generate a key, authorise it on the server, and log in with it. This
      // is the only test that proves the whole chain — generation, OpenSSH
      // encoding, and the public key line — is correct rather than merely
      // self-consistent.
      final key = generator.generateEd25519(comment: 'generated@termino');

      final server = await TestSshd.start(authorizedKey: key.publicKeyLine);
      addTearDown(server.stop);

      final knownHosts = InMemoryKnownHostsRepository();
      final backend = SshBackend(
        host: SshHost(
          id: 'generated',
          label: 'generated',
          hostname: '127.0.0.1',
          username: TestSshd.username,
          port: server.port,
        ),
        verifier: HostKeyVerifier(knownHosts),
        onHostKeyPrompt: (check) async => true,
        prompts: SshAuthPrompts(
          identities: SSHKeyPair.fromPem(key.privateKeyPem),
        ),
      );

      final output = StringBuffer();
      backend.output.listen(
        (chunk) => output.write(utf8.decode(chunk, allowMalformed: true)),
      );

      await backend.start();
      expect(backend.state, BackendConnectionState.connected);

      backend.write(Uint8List.fromList(utf8.encode('echo GENERATED-KEY-OK\n')));
      for (
        var i = 0;
        i < 100 && !output.toString().contains('GENERATED-KEY-OK');
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(output.toString(), contains('GENERATED-KEY-OK'));
      await backend.close();
    });
  });
}
