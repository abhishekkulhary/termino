import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/application/ssh_connector.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

part 'connection_pool.g.dart';

/// A hold on a shared connection.
///
/// The connection stays open while at least one lease is outstanding, and is
/// closed when the last one is released. Holding a lease is the only way to
/// use a pooled connection, so there is no way to use one that has already
/// been let go.
class SshConnectionLease implements SshConnectionHold {
  new _(this._entry, this._pool);

  final _PooledConnection _entry;
  final SshConnectionPool _pool;
  var _released = false;

  /// The connection this lease holds open.
  @override
  SshConnection get connection => _entry.connection;

  /// The SSH client, for opening a channel.
  SSHClient get client => _entry.connection.client;

  /// Whether this lease has been given up.
  bool get isReleased => _released;

  /// Gives up this hold. Releasing twice is harmless.
  ///
  /// Closes the connection only if nothing else is holding it — which is the
  /// whole point: closing the file browser must not kill a shell someone has
  /// work in progress in.
  @override
  Future<void> release() async {
    if (_released) return;
    _released = true;
    await _pool._release(_entry);
  }
}

class _PooledConnection {
  new(this.hostId, this.connection);

  final String hostId;
  final SshConnection connection;
  int leases = 0;
}

/// One authenticated connection per host, shared by everything that needs it.
///
/// SSH multiplexes: a single connection carries an interactive shell, an SFTP
/// subsystem and any number of forwarded ports at the same time. That is what
/// OpenSSH's `ControlMaster` does, and it is why opening the file browser for
/// a host you already have a shell on should not ask for a password again.
///
/// ## What this gives up
///
/// Each feature used to authenticate separately, and that isolation was real:
/// a transfer that killed its connection could not disturb a shell. Sharing
/// means one dropped TCP connection now takes the shell, the browser and the
/// forwards together. That is the same trade `ControlMaster` makes, and it is
/// the one the user asked for — authenticating three times to work on one
/// machine is a worse problem than a shared failure mode.
///
/// Reference counting keeps the part of the isolation that mattered: closing
/// the browser closes nothing while a shell is still open.
class SshConnectionPool {
  /// Creates a pool that opens connections with [open].
  new({required this.open});

  /// How to authenticate a new connection. Injected so the pool can be tested
  /// without a server, and so it never needs to know about keys or prompts.
  final Future<SshConnection> Function(SshHost host) open;

  final _entries = <String, _PooledConnection>{};
  final _pending = <String, Future<_PooledConnection>>{};

  /// Takes a hold on the connection to [host], authenticating if necessary.
  ///
  /// Two callers asking at once share one authentication: the second awaits
  /// the first attempt rather than starting another. Without that, opening the
  /// terminal and the file browser together would prompt twice — which is the
  /// thing this exists to stop.
  Future<SshConnectionLease> acquire(SshHost host) async {
    final entry = await _entryFor(host);
    entry.leases++;
    return SshConnectionLease._(entry, this);
  }

  /// Whether [hostId] has a live connection right now.
  bool isConnected(String hostId) => _entries.containsKey(hostId);

  /// How many holds are out on [hostId]. Zero when it is not connected.
  int leaseCount(String hostId) => _entries[hostId]?.leases ?? 0;

  /// Closes [hostId]'s connection whatever is holding it.
  ///
  /// For a user who explicitly disconnects, and for a host whose credentials
  /// changed. Existing leases become unusable, which their holders will see as
  /// their own channel closing.
  Future<void> disconnect(String hostId) async {
    final entry = _entries.remove(hostId);
    if (entry == null) return;
    await _close(entry);
  }

  /// Closes everything. For app shutdown.
  Future<void> disconnectAll() async {
    final entries = _entries.values.toList();
    _entries.clear();
    for (final entry in entries) {
      await _close(entry);
    }
  }

  Future<_PooledConnection> _entryFor(SshHost host) async {
    final existing = _entries[host.id];
    if (existing != null) {
      // A connection that dropped without its `done` handler having run yet
      // would otherwise be handed out and fail on first use.
      if (!existing.connection.client.isClosed) return existing;
      _entries.remove(host.id);
    }

    final inFlight = _pending[host.id];
    if (inFlight != null) return await inFlight;

    final attempt = _connect(host);
    _pending[host.id] = attempt;
    try {
      return await attempt;
    } finally {
      // Already awaited above; dropping the map entry discards a future whose
      // result is in hand either way.
      _pending.remove(host.id)?.ignore();
    }
  }

  Future<_PooledConnection> _connect(SshHost host) async {
    // A failed attempt is deliberately not cached: the next try should be a
    // real one, not the same exception handed out again.
    final connection = await open(host);
    final entry = _PooledConnection(host.id, connection);
    _entries[host.id] = entry;

    // When the transport dies, forget it. Otherwise the next acquire returns a
    // corpse and the user sees a session that fails instead of one that
    // reconnects.
    unawaited(
      connection.client.done
          .then((_) => _forget(entry))
          .catchError((Object _) => _forget(entry)),
    );

    return entry;
  }

  void _forget(_PooledConnection entry) {
    if (identical(_entries[entry.hostId], entry)) {
      _entries.remove(entry.hostId);
    }
  }

  Future<void> _release(_PooledConnection entry) async {
    entry.leases--;
    if (entry.leases > 0) return;

    _forget(entry);
    await _close(entry);
  }

  Future<void> _close(_PooledConnection entry) async {
    try {
      await entry.connection.close();
    } on Object catch (error) {
      // Closing a connection that has already gone is not worth failing over,
      // and the caller is usually in a dispose that cannot handle it anyway.
      Loggers.ssh.fine('Closing the connection to ${entry.hostId}: $error');
    }
  }
}

/// The app's shared connections.
///
/// Kept alive for the life of the app: a connection outlives every screen that
/// uses it, which is the entire point of pooling it.
@Riverpod(keepAlive: true)
SshConnectionPool sshConnectionPool(Ref ref) {
  final connector = ref.watch(sshConnectorProvider);
  final pool = SshConnectionPool(open: connector.open);
  ref.onDispose(pool.disconnectAll);
  return pool;
}
