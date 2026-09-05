import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_identity.freezed.dart';
part 'ssh_identity.g.dart';

/// The kind of key material an identity holds.
enum SshKeyType {
  /// Ed25519. The default for new keys: small, fast, and without the parameter
  /// choices the others require you to get right.
  ed25519,

  /// RSA. Offered at 4096 bits for servers too old to accept Ed25519.
  rsa,

  /// ECDSA on a NIST curve. Supported for import; not offered for generation.
  ecdsa;

  /// A label for the UI.
  String get label => switch (this) {
    SshKeyType.ed25519 => 'Ed25519',
    SshKeyType.rsa => 'RSA',
    SshKeyType.ecdsa => 'ECDSA',
  };
}

/// An SSH key the user has imported or generated — **metadata only**.
///
/// The private key itself is never held here and never reaches the database.
/// It lives in the platform keystore under [secretRef], and is read only for
/// the moment an authentication attempt needs it. See SECURITY.md.
@freezed
abstract class SshIdentity with _$SshIdentity {
  /// Creates identity metadata.
  const factory({
    required String id,
    required String name,
    required SshKeyType keyType,

    /// The key that goes in `authorized_keys`. Public, so safe to store.
    required String publicKey,

    /// OpenSSH-style `SHA256:...` fingerprint of the public key.
    required String fingerprint,
    required DateTime createdAt,

    /// Whether the stored private key is itself passphrase-encrypted.
    @Default(false) bool hasPassphrase,

    /// Whether using this key requires a biometric or device-credential check.
    @Default(false) bool requiresBiometrics,

    /// Free-text comment, usually `user@host` from the original key.
    String? comment,
  }) = _SshIdentity;

  const new _();

  /// Restores identity metadata from stored JSON.
  factory fromJson(Map<String, dynamic> json) => _$SshIdentityFromJson(json);

  /// The key under which the private key is stored in the platform keystore.
  ///
  /// Deriving it from the id rather than storing it means the database never
  /// holds anything that looks like a pointer to a secret.
  String get secretRef => 'identity.$id.private-key';

  /// The keystore key for this identity's passphrase, when the user chose to
  /// remember it.
  String get passphraseRef => 'identity.$id.passphrase';
}
