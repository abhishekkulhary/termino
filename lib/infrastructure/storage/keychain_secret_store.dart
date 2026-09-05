import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:termino/domain/repositories/secret_store.dart';

/// A [SecretStore] backed by the platform keystore.
class KeychainSecretStore implements SecretStore {
  /// Creates a store, optionally with custom platform options.
  const new([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  /// Namespaces Termino's keys so they cannot collide with another app's on
  /// platforms where the keystore is shared.
  static const _prefix = 'termino.';

  @override
  Future<String?> read(String key) => _storage.read(key: _prefix + key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _prefix + key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: _prefix + key);

  @override
  Future<bool> contains(String key) => _storage.containsKey(key: _prefix + key);
}
