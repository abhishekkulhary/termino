import 'package:termino/domain/entities/ssh_identity.dart';

/// Stores SSH key **metadata**. The private keys live in the platform keystore.
abstract class SshIdentityRepository {
  /// Every identity, newest first.
  Future<List<SshIdentity>> all();

  /// Emits the full list whenever it changes.
  Stream<List<SshIdentity>> watch();

  /// One identity by id, or null.
  Future<SshIdentity?> byId(String id);

  /// Records metadata for a key. The private key is stored separately.
  Future<void> save(SshIdentity identity);

  /// Deletes an identity and its stored private key.
  Future<void> delete(String id);
}
