import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/repositories/known_hosts_repository.dart';
import 'package:termino/domain/repositories/port_forward_repository.dart';
import 'package:termino/domain/repositories/secret_store.dart';
import 'package:termino/domain/repositories/ssh_host_repository.dart';
import 'package:termino/domain/repositories/ssh_identity_repository.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/key_generator.dart';
import 'package:termino/infrastructure/storage/database.dart';
import 'package:termino/infrastructure/storage/drift_repositories.dart';
import 'package:termino/infrastructure/storage/keychain_secret_store.dart';
import 'package:termino/infrastructure/storage/settings_store.dart';

part 'providers.g.dart';

/// The local database.
///
/// Overridden in tests with an in-memory connection, which is why nothing
/// constructs `TerminoDatabase` directly.
@Riverpod(keepAlive: true)
TerminoDatabase database(Ref ref) {
  final db = TerminoDatabase();
  ref.onDispose(db.close);
  return db;
}

/// The platform keystore. The only place a secret is ever written.
@Riverpod(keepAlive: true)
SecretStore secretStore(Ref ref) => const KeychainSecretStore();

/// Saved SSH connections.
@Riverpod(keepAlive: true)
SshHostRepository sshHostRepository(Ref ref) => DriftSshHostRepository(
  ref.watch(databaseProvider),
  ref.watch(secretStoreProvider),
);

/// Trusted host keys.
@Riverpod(keepAlive: true)
KnownHostsRepository knownHostsRepository(Ref ref) =>
    DriftKnownHostsRepository(ref.watch(databaseProvider));

/// SSH key metadata.
@Riverpod(keepAlive: true)
SshIdentityRepository sshIdentityRepository(Ref ref) =>
    DriftSshIdentityRepository(
      ref.watch(databaseProvider),
      ref.watch(secretStoreProvider),
    );

/// Decides whether a host key may be trusted.
@Riverpod(keepAlive: true)
HostKeyVerifier hostKeyVerifier(Ref ref) =>
    HostKeyVerifier(ref.watch(knownHostsRepositoryProvider));

/// Configured tunnels.
@Riverpod(keepAlive: true)
PortForwardRepository portForwardRepository(Ref ref) =>
    DriftPortForwardRepository(ref.watch(databaseProvider));

/// Reads and writes the user's settings.
@Riverpod(keepAlive: true)
SettingsStore settingsStore(Ref ref) =>
    SettingsStore(ref.watch(databaseProvider));

/// Generates new SSH keys.
@Riverpod(keepAlive: true)
SshKeyGenerator sshKeyGenerator(Ref ref) => SshKeyGenerator();

/// The saved connections, as a live list.
@riverpod
Stream<List<SshHost>> sshHosts(Ref ref) =>
    ref.watch(sshHostRepositoryProvider).watch();

/// The stored identities, as a live list.
@riverpod
Stream<List<SshIdentity>> sshIdentities(Ref ref) =>
    ref.watch(sshIdentityRepositoryProvider).watch();
