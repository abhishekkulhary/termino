import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/repositories/secret_store.dart';
import 'package:termino/infrastructure/storage/database.dart';

/// An in-memory secret store, so tests never touch the real keystore.
class InMemorySecretStore implements SecretStore {
  /// Everything written, for assertions.
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

/// A container wired to an in-memory database and secret store.
///
/// Nothing here touches the user's real database or keystore, which matters
/// beyond hygiene: a test that wrote to the platform keychain would leave
/// credentials behind on the developer's machine.
/// Riverpod 3 does not export its `Override` type, so a helper cannot take a
/// list of them. The overrides that tests actually need are named instead.
ProviderContainer testContainer({
  TerminoDatabase? database,
  SecretStore? secrets,
  PlatformCapabilities? capabilities,
}) {
  final db = database ?? TerminoDatabase.withExecutor(NativeDatabase.memory());
  final store = secrets ?? InMemorySecretStore();

  return ProviderContainer.test(
    overrides: [
      databaseProvider.overrideWithValue(db),
      secretStoreProvider.overrideWithValue(store),
      if (capabilities != null)
        platformCapabilitiesProvider.overrideWithValue(capabilities),
    ],
  );
}
