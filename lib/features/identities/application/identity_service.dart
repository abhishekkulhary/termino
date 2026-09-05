import 'dart:convert';
import 'dart:math';

import 'package:dartssh2/dartssh2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/repositories/secret_store.dart';
import 'package:termino/domain/repositories/ssh_identity_repository.dart';
import 'package:termino/domain/ssh/known_hosts_file.dart';
import 'package:termino/infrastructure/ssh/key_generator.dart';

part 'identity_service.g.dart';

/// Why an imported key could not be used.
enum KeyImportFailure {
  /// The text is not a private key in any format we understand.
  unreadable,

  /// The key is encrypted and the passphrase was wrong or not given.
  wrongPassphrase,
}

/// Thrown when importing a key fails, with a reason the UI can explain.
class KeyImportException implements Exception {
  /// Creates an import failure.
  const new(this.reason);

  /// What went wrong.
  final KeyImportFailure reason;

  /// A sentence for the user. Never contains key material.
  String get message => switch (reason) {
    KeyImportFailure.unreadable =>
      'That does not look like an SSH private key. Termino reads OpenSSH and '
          'PEM keys — Ed25519, RSA and ECDSA.',
    KeyImportFailure.wrongPassphrase =>
      'The key is encrypted and the passphrase did not decrypt it.',
  };
}

/// Creates, imports and deletes SSH identities.
///
/// Private keys pass through here on their way to the keystore and are never
/// held afterwards: nothing on this class or in provider state retains them.
class IdentityService {
  /// Creates a service.
  const new({
    required this.repository,
    required this.secrets,
    required this.generator,
  });

  /// Where key metadata lives.
  final SshIdentityRepository repository;

  /// Where the private keys live.
  final SecretStore secrets;

  /// Makes new keys.
  final SshKeyGenerator generator;

  /// Generates a key and stores it.
  ///
  /// [passphrase] encrypts the key at rest, on top of the keystore's own
  /// protection. It is not remembered unless [rememberPassphrase] is set.
  Future<SshIdentity> generate({
    required String name,
    required SshKeyType keyType,
    String? passphrase,
    bool rememberPassphrase = false,
    bool requiresBiometrics = false,
    String comment = '',
  }) async {
    final generated = switch (keyType) {
      SshKeyType.ed25519 => generator.generateEd25519(
        comment: comment,
        passphrase: passphrase,
      ),
      SshKeyType.rsa => generator.generateRsa(
        comment: comment,
        passphrase: passphrase,
      ),
      SshKeyType.ecdsa => throw ArgumentError.value(
        keyType,
        'keyType',
        'ECDSA keys can be imported but are not generated: there is no reason '
            'to create one when Ed25519 exists.',
      ),
    };

    final identity = SshIdentity(
      id: _newId(),
      name: name,
      keyType: generated.keyType,
      publicKey: generated.publicKeyLine,
      fingerprint: generated.fingerprint,
      createdAt: DateTime.now(),
      hasPassphrase: passphrase != null && passphrase.isNotEmpty,
      requiresBiometrics: requiresBiometrics,
      comment: comment.isEmpty ? null : comment,
    );

    await _store(
      identity,
      generated.privateKeyPem,
      passphrase,
      rememberPassphrase: rememberPassphrase,
    );
    return identity;
  }

  /// Imports an existing private key given as PEM text.
  ///
  /// Throws [KeyImportException] with a reason the UI can show.
  Future<SshIdentity> import({
    required String name,
    required String pem,
    String? passphrase,
    bool rememberPassphrase = false,
    bool requiresBiometrics = false,
  }) async {
    final encrypted = SSHKeyPair.isEncryptedPem(pem);

    final List<SSHKeyPair> parsed;
    try {
      parsed = SSHKeyPair.fromPem(pem, passphrase);
    } on SSHKeyDecryptError {
      throw const KeyImportException(KeyImportFailure.wrongPassphrase);
    } on Object {
      throw const KeyImportException(KeyImportFailure.unreadable);
    }
    if (parsed.isEmpty) {
      throw const KeyImportException(KeyImportFailure.unreadable);
    }

    final pair = parsed.first;
    final blob = pair.toPublicKey().encode();
    final blobType = SSHHostKey.getType(blob);

    final identity = SshIdentity(
      id: _newId(),
      name: name,
      keyType: _keyTypeFor(blobType),
      publicKey: '$blobType ${base64Encode(blob)}',
      fingerprint: KnownHostsFile.fingerprintOf(blob),
      createdAt: DateTime.now(),
      hasPassphrase: encrypted,
      requiresBiometrics: requiresBiometrics,
    );

    await _store(
      identity,
      pem,
      passphrase,
      rememberPassphrase: rememberPassphrase,
    );
    return identity;
  }

  /// Deletes an identity and its key material.
  Future<void> delete(String id) => repository.delete(id);

  Future<void> _store(
    SshIdentity identity,
    String pem,
    String? passphrase, {
    required bool rememberPassphrase,
  }) async {
    // The private key goes to the keystore first. If that fails, no metadata
    // is written, so the app never lists an identity whose key is missing.
    await secrets.write(identity.secretRef, pem);
    if (rememberPassphrase && passphrase != null && passphrase.isNotEmpty) {
      await secrets.write(identity.passphraseRef, passphrase);
    }
    await repository.save(identity);
  }

  static SshKeyType _keyTypeFor(String blobType) => switch (blobType) {
    'ssh-ed25519' => SshKeyType.ed25519,
    'ssh-rsa' => SshKeyType.rsa,
    _ => SshKeyType.ecdsa,
  };

  static String _newId() =>
      'id-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';
}

/// The identity service for the current scope.
@Riverpod(keepAlive: true)
IdentityService identityService(Ref ref) => IdentityService(
  repository: ref.watch(sshIdentityRepositoryProvider),
  secrets: ref.watch(secretStoreProvider),
  generator: ref.watch(sshKeyGeneratorProvider),
);
