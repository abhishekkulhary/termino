import 'package:drift/drift.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/repositories/known_hosts_repository.dart';
import 'package:termino/domain/repositories/secret_store.dart';
import 'package:termino/domain/repositories/ssh_host_repository.dart';
import 'package:termino/domain/repositories/ssh_identity_repository.dart';
import 'package:termino/infrastructure/storage/database.dart';

/// Saved connections, stored in drift.
class DriftSshHostRepository implements SshHostRepository {
  /// Creates a repository over the database, deleting any remembered
  /// password from the keystore when a host is removed.
  const new(this._db, this._secrets);

  final TerminoDatabase _db;
  final SecretStore _secrets;

  @override
  Future<List<SshHost>> all() async {
    final query = _db.select(_db.sshHostRows)
      ..orderBy([(row) => OrderingTerm(expression: row.label)]);
    return (await query.get()).map(_toDomain).toList();
  }

  @override
  Stream<List<SshHost>> watch() {
    final query = _db.select(_db.sshHostRows)
      ..orderBy([(row) => OrderingTerm(expression: row.label)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<SshHost?> byId(String id) async {
    final query = _db.select(_db.sshHostRows)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(SshHost host) =>
      _db.into(_db.sshHostRows).insertOnConflictUpdate(_toRow(host));

  @override
  Future<void> delete(String id) async {
    final host = await byId(id);
    await (_db.delete(_db.sshHostRows)..where((row) => row.id.equals(id))).go();
    // A deleted host must not leave its password behind in the keystore.
    if (host != null) await _secrets.delete(host.passwordRef);
  }

  static SshHost _toDomain(SshHostRow row) => SshHost(
    id: row.id,
    label: row.label,
    hostname: row.hostname,
    username: row.username,
    port: row.port,
    identityId: row.identityId,
    authMethods: _decodeAuthMethods(row.authMethods),
    jumpHostId: row.jumpHostId,
    keepAliveInterval: Duration(seconds: row.keepAliveSeconds),
    startupCommand: row.startupCommand,
    colorValue: row.colorValue,
    folder: row.folder,
    hasSavedPassword: row.hasSavedPassword,
  );

  static SshHostRow _toRow(SshHost host) => SshHostRow(
    id: host.id,
    label: host.label,
    hostname: host.hostname,
    username: host.username,
    port: host.port,
    identityId: host.identityId,
    authMethods: host.authMethods.map((method) => method.name).join(','),
    jumpHostId: host.jumpHostId,
    keepAliveSeconds: host.keepAliveInterval.inSeconds,
    startupCommand: host.startupCommand,
    colorValue: host.colorValue,
    folder: host.folder,
    hasSavedPassword: host.hasSavedPassword,
  );

  static List<SshAuthMethod> _decodeAuthMethods(String encoded) {
    if (encoded.isEmpty) return const [];
    return encoded
        .split(',')
        .map(
          (name) => SshAuthMethod.values
              .where((method) => method.name == name)
              .firstOrNull,
        )
        .whereType<SshAuthMethod>()
        .toList(growable: false);
  }
}

/// Trusted host keys, stored in drift.
class DriftKnownHostsRepository implements KnownHostsRepository {
  /// Creates a repository over the database.
  const new(this._db);

  final TerminoDatabase _db;

  @override
  Future<List<KnownHost>> forHost({
    required String host,
    required int port,
  }) async {
    final query = _db.select(_db.knownHostRows)
      ..where((row) => row.host.equals(host) & row.port.equals(port));
    return (await query.get()).map(_toDomain).toList();
  }

  @override
  Future<List<KnownHost>> all() async {
    final query = _db.select(_db.knownHostRows)
      ..orderBy([(row) => OrderingTerm(expression: row.host)]);
    return (await query.get()).map(_toDomain).toList();
  }

  @override
  Future<void> add(KnownHost entry) =>
      _db.into(_db.knownHostRows).insert(_toCompanion(entry));

  @override
  Future<void> replace(KnownHost entry) async {
    await _db.transaction(() async {
      await (_db.delete(_db.knownHostRows)..where(
            (row) =>
                row.host.equals(entry.host) &
                row.port.equals(entry.port) &
                row.keyType.equals(entry.keyType),
          ))
          .go();
      await _db.into(_db.knownHostRows).insert(_toCompanion(entry));
    });
  }

  @override
  Future<void> remove({required String host, required int port}) => (_db.delete(
    _db.knownHostRows,
  )..where((row) => row.host.equals(host) & row.port.equals(port))).go();

  @override
  Future<int> addAll(Iterable<KnownHost> entries) async {
    var added = 0;
    await _db.transaction(() async {
      for (final entry in entries) {
        final existing = await forHost(host: entry.host, port: entry.port);
        final duplicate = existing.any(
          (row) =>
              row.keyType == entry.keyType &&
              row.fingerprint == entry.fingerprint,
        );
        if (duplicate) continue;
        await _db.into(_db.knownHostRows).insert(_toCompanion(entry));
        added++;
      }
    });
    return added;
  }

  static KnownHost _toDomain(KnownHostRow row) => KnownHost(
    host: row.host,
    port: row.port,
    keyType: row.keyType,
    fingerprint: row.fingerprint,
    publicKey: row.publicKey,
    addedAt: row.addedAt,
    source: KnownHostSource.values.firstWhere(
      (source) => source.name == row.source,
      orElse: () => KnownHostSource.imported,
    ),
  );

  static KnownHostRowsCompanion _toCompanion(KnownHost entry) =>
      KnownHostRowsCompanion.insert(
        host: entry.host,
        port: entry.port,
        keyType: entry.keyType,
        fingerprint: entry.fingerprint,
        publicKey: Value(entry.publicKey),
        addedAt: entry.addedAt,
        source: entry.source.name,
      );
}

/// Key metadata, stored in drift. Private keys never come near this class.
class DriftSshIdentityRepository implements SshIdentityRepository {
  /// Creates a repository over the database, deleting key material from the
  /// keystore when an identity is removed.
  const new(this._db, this._secrets);

  final TerminoDatabase _db;
  final SecretStore _secrets;

  @override
  Future<List<SshIdentity>> all() async {
    final query = _db.select(_db.sshIdentityRows)
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ]);
    return (await query.get()).map(_toDomain).toList();
  }

  @override
  Stream<List<SshIdentity>> watch() {
    final query = _db.select(_db.sshIdentityRows)
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<SshIdentity?> byId(String id) async {
    final query = _db.select(_db.sshIdentityRows)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(SshIdentity identity) =>
      _db.into(_db.sshIdentityRows).insertOnConflictUpdate(_toRow(identity));

  @override
  Future<void> delete(String id) async {
    final identity = await byId(id);
    await (_db.delete(
      _db.sshIdentityRows,
    )..where((row) => row.id.equals(id))).go();
    if (identity == null) return;
    // Deleting the metadata without the key material would leave an
    // unreachable private key in the keystore forever.
    await _secrets.delete(identity.secretRef);
    await _secrets.delete(identity.passphraseRef);
  }

  static SshIdentity _toDomain(SshIdentityRow row) => SshIdentity(
    id: row.id,
    name: row.name,
    keyType: SshKeyType.values.firstWhere(
      (type) => type.name == row.keyType,
      orElse: () => SshKeyType.ed25519,
    ),
    publicKey: row.publicKey,
    fingerprint: row.fingerprint,
    createdAt: row.createdAt,
    hasPassphrase: row.hasPassphrase,
    requiresBiometrics: row.requiresBiometrics,
    comment: row.comment,
  );

  static SshIdentityRow _toRow(SshIdentity identity) => SshIdentityRow(
    id: identity.id,
    name: identity.name,
    keyType: identity.keyType.name,
    publicKey: identity.publicKey,
    fingerprint: identity.fingerprint,
    hasPassphrase: identity.hasPassphrase,
    requiresBiometrics: identity.requiresBiometrics,
    comment: identity.comment,
    createdAt: identity.createdAt,
  );
}
