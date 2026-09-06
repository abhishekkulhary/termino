import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Saved SSH connections.
///
/// Holds no secrets. Passwords live in the platform keystore, keyed by the
/// host's id; see `SecretStore`. A test asserts that no secret string ever
/// appears in this file.
@DataClassName('SshHostRow')
class SshHostRows extends Table {
  /// Stable identifier, also used to derive the keystore key.
  TextColumn get id => text()();

  /// What the user calls this connection.
  TextColumn get label => text()();

  /// The address to connect to.
  TextColumn get hostname => text()();

  /// The account to log in as.
  TextColumn get username => text()();

  /// The TCP port.
  IntColumn get port => integer().withDefault(const Constant(22))();

  /// The identity to authenticate with, if any.
  TextColumn get identityId => text().nullable()();

  /// Auth methods to offer, comma separated, in order. Empty means "all".
  TextColumn get authMethods => text().withDefault(const Constant(''))();

  /// Another host to tunnel through, as OpenSSH's ProxyJump.
  TextColumn get jumpHostId => text().nullable()();

  /// Keepalive period in seconds. Zero disables it.
  IntColumn get keepAliveSeconds => integer().withDefault(const Constant(30))();

  /// A command to run once the shell opens.
  TextColumn get startupCommand => text().nullable()();

  /// Tab colour, as an ARGB value.
  IntColumn get colorValue => integer().nullable()();

  /// Grouping shown as a folder in the host list.
  TextColumn get folder => text().nullable()();

  /// When this host was last connected to, as epoch milliseconds.
  ///
  /// Worth naming as a deliberate choice: it is the only column here that
  /// records what the user actually did, and it exists so the host list can
  /// lead with what they use rather than with the alphabet.
  IntColumn get lastConnectedAt => integer().nullable()();

  /// Whether a password for this host exists in the keystore.
  BoolColumn get hasSavedPassword =>
      boolean().withDefault(const Constant(false))();

  /// Whether to forward the key to the remote host.
  BoolColumn get forwardAgent => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Host keys the user has accepted.
@DataClassName('KnownHostRow')
class KnownHostRows extends Table {
  /// Surrogate key; the meaningful uniqueness is the triple below.
  IntColumn get rowId => integer().autoIncrement()();

  /// The host as the user connects to it.
  TextColumn get host => text()();

  /// The port.
  IntColumn get port => integer()();

  /// The key type, e.g. `ssh-ed25519`.
  TextColumn get keyType => text()();

  /// OpenSSH-style `SHA256:...` fingerprint.
  TextColumn get fingerprint => text()();

  /// The base64 key blob, when known. Present for imported entries.
  TextColumn get publicKey => text().nullable()();

  /// When this key was accepted.
  DateTimeColumn get addedAt => dateTime()();

  /// `trustOnFirstUse` or `imported`.
  TextColumn get source => text()();
}

/// Metadata for SSH keys. **The private key is never stored here.**
@DataClassName('SshIdentityRow')
class SshIdentityRows extends Table {
  /// Stable identifier, also used to derive the keystore key.
  TextColumn get id => text()();

  /// What the user calls this key.
  TextColumn get name => text()();

  /// `ed25519`, `rsa` or `ecdsa`.
  TextColumn get keyType => text()();

  /// The public key, which is not secret.
  TextColumn get publicKey => text()();

  /// OpenSSH-style fingerprint of the public key.
  TextColumn get fingerprint => text()();

  /// Whether the stored private key is passphrase-encrypted.
  BoolColumn get hasPassphrase =>
      boolean().withDefault(const Constant(false))();

  /// Whether using this key requires a biometric check.
  BoolColumn get requiresBiometrics =>
      boolean().withDefault(const Constant(false))();

  /// Usually `user@host` from the original key.
  TextColumn get comment => text().nullable()();

  /// When the key was imported or generated.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Application settings, as a key-value store.
///
/// A table rather than typed columns because settings are added constantly and
/// each new one would otherwise be a schema migration. The typed view over it
/// lives in `TerminoSettings`.
@DataClassName('SettingRow')
class SettingRows extends Table {
  /// The setting's name.
  TextColumn get key => text()();

  /// Its value, encoded as text.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// A saved port forward.
@DataClassName('PortForwardRow')
class PortForwardRows extends Table {
  /// Stable identifier.
  TextColumn get id => text()();

  /// The host this tunnel runs through.
  TextColumn get hostId => text()();

  /// `local`, `remote` or `dynamic`.
  TextColumn get kind => text()();

  /// The port listened on.
  IntColumn get listenPort => integer()();

  /// Where traffic goes, for local and remote tunnels.
  TextColumn get destinationHost => text().nullable()();

  /// The port traffic goes to.
  IntColumn get destinationPort => integer().nullable()();

  /// The address bound locally.
  TextColumn get bindAddress =>
      text().withDefault(const Constant('127.0.0.1'))();

  /// What the user calls it.
  TextColumn get label => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A saved command the user can send with one tap.
@DataClassName('SnippetRow')
class SnippetRows extends Table {
  /// Stable identifier.
  TextColumn get id => text()();

  /// What the user calls it.
  TextColumn get name => text()();

  /// The text sent to the terminal.
  TextColumn get body => text()();

  /// When set, the snippet only appears for that host.
  TextColumn get hostId => text().nullable()();

  /// Whether a newline is appended, running the command immediately.
  BoolColumn get runImmediately =>
      boolean().withDefault(const Constant(false))();

  /// When it was created, for ordering.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Termino's local database.
///
/// Connection profiles, trusted host keys and key *metadata*. Nothing in here
/// is secret, by design: the file is not encrypted, and treating it as though
/// it were would be a mistake waiting to happen.
@DriftDatabase(
  tables: [
    SshHostRows,
    KnownHostRows,
    SshIdentityRows,
    SettingRows,
    PortForwardRows,
    SnippetRows,
  ],
)
class TerminoDatabase extends _$TerminoDatabase {
  /// Opens the database in the app's documents directory.
  new() : super(driftDatabase(name: 'termino'));

  /// Opens a database on a caller-supplied connection, for tests.
  new withExecutor(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(sshHostRows, sshHostRows.forwardAgent);
      }
      if (from < 3) {
        await m.createTable(settingRows);
        await m.createTable(portForwardRows);
        await m.createTable(snippetRows);
      }
      if (from < 4) {
        await m.addColumn(sshHostRows, sshHostRows.lastConnectedAt);
      }
    },
    beforeOpen: (details) async {
      // Foreign keys are off by default in SQLite and must be enabled per
      // connection, not once per database.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
