import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart' as nacl;
import 'package:pointycastle/api.dart' show KeyParameter, ParametersWithRandom;
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/ssh/known_hosts_file.dart';

/// A freshly generated key: the private half to store, the public half to
/// publish, and the metadata that describes both.
class GeneratedKey {
  /// Creates a generated key.
  const new({
    required this.privateKeyPem,
    required this.publicKeyLine,
    required this.fingerprint,
    required this.keyType,
  });

  /// The private key in OpenSSH format, ready for the platform keystore.
  ///
  /// This is the only place it exists outside the keystore, and callers are
  /// expected to write it and drop the reference immediately.
  final String privateKeyPem;

  /// The `authorized_keys` line, e.g. `ssh-ed25519 AAAA... comment`.
  final String publicKeyLine;

  /// The OpenSSH-style `SHA256:...` fingerprint.
  final String fingerprint;

  /// Which algorithm was used.
  final SshKeyType keyType;
}

/// Generates SSH key pairs.
///
/// `dartssh2` parses keys but does not create them, so this fills the gap:
/// Ed25519 through the same NaCl implementation dartssh2 verifies with, and
/// RSA through PointyCastle. Both are packaged into the OpenSSH private key
/// container that `dartssh2` and `ssh-keygen` both read, so a key generated
/// here works with any SSH server and can be exported to any other client.
class SshKeyGenerator {
  /// Creates a generator. [random] is injectable so tests can be deterministic.
  new({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Generates an Ed25519 key.
  ///
  /// The default for new keys: fixed-size, fast, and with no parameters to get
  /// wrong. Optionally encrypted at rest with [passphrase].
  GeneratedKey generateEd25519({String comment = '', String? passphrase}) {
    final seed = _randomBytes(32);
    final signing = nacl.SigningKey(seed: seed);

    final publicKey = Uint8List.fromList(signing.publicKey.asTypedList);
    // OpenSSH stores seed || public as the 64-byte "private key".
    final privateKey = Uint8List.fromList([...seed, ...publicKey]);

    final pair = OpenSSHEd25519KeyPair(publicKey, privateKey, comment);
    return _package(pair, SshKeyType.ed25519, comment, passphrase);
  }

  /// Generates an RSA key, 4096 bits by default.
  ///
  /// Offered for servers too old to accept Ed25519. Anything below 2048 bits is
  /// refused outright rather than being made available as a footgun.
  GeneratedKey generateRsa({
    int bits = 4096,
    String comment = '',
    String? passphrase,
  }) {
    if (bits < 2048) {
      throw ArgumentError.value(bits, 'bits', 'must be at least 2048');
    }

    final generator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), bits, 64),
          _secureRandom(),
        ),
      );

    final pair = generator.generateKeyPair();
    final public = pair.publicKey;
    final private = pair.privateKey;

    final p = private.p!;
    final q = private.q!;
    // OpenSSH stores the CRT coefficient q^-1 mod p.
    final iqmp = q.modInverse(p);

    final keyPair = OpenSSHRsaKeyPair(
      public.modulus!,
      public.exponent!,
      private.privateExponent!,
      iqmp,
      p,
      q,
      comment,
    );
    return _package(keyPair, SshKeyType.rsa, comment, passphrase);
  }

  GeneratedKey _package(
    OpenSSHKeyPair pair,
    SshKeyType type,
    String comment,
    String? passphrase,
  ) {
    final publicBlob = pair.toPublicKey().encode();
    final encoded = base64.encode(publicBlob);

    // The prefix on an authorized_keys line is the *key blob* type, which is
    // the first field inside the blob itself. It is not `pair.type`: for RSA
    // that reports the signature algorithm, `rsa-sha2-256`, and a line
    // starting with that is not a valid authorized_keys entry.
    final blobType = SSHHostKey.getType(publicBlob);
    final line = comment.isEmpty
        ? '$blobType $encoded'
        : '$blobType $encoded $comment';

    return GeneratedKey(
      privateKeyPem: pair.toPem(passphrase: passphrase),
      publicKeyLine: line,
      fingerprint: KnownHostsFile.fingerprintOf(publicBlob),
      keyType: type,
    );
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );

  FortunaRandom _secureRandom() =>
      FortunaRandom()..seed(KeyParameter(_randomBytes(32)));
}
