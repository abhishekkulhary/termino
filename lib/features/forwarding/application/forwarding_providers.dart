import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/features/forwarding/application/forward_manager.dart';
import 'package:termino/features/hosts/application/connection_pool.dart';

part 'forwarding_providers.g.dart';

/// The configured tunnels, persisted so they survive a restart.
@Riverpod(keepAlive: true)
class PortForwards extends _$PortForwards {
  @override
  List<PortForward> build() {
    unawaited(_load());
    return const [];
  }

  Future<void> _load() async {
    state = await ref.read(portForwardRepositoryProvider).all();
  }

  /// Adds or updates a tunnel.
  Future<void> save(PortForward forward) async {
    await ref.read(portForwardRepositoryProvider).save(forward);
    await _load();
  }

  /// Removes a tunnel, stopping it first.
  Future<void> remove(String id) async {
    await ref.read(forwardRunnerProvider.notifier).stop(id);
    await ref.read(portForwardRepositoryProvider).delete(id);
    await _load();
  }

  /// Starts a tunnel.
  Future<void> start(PortForward forward) =>
      ref.read(forwardRunnerProvider.notifier).start(forward);

  /// Stops a tunnel.
  Future<void> stop(PortForward forward) =>
      ref.read(forwardRunnerProvider.notifier).stop(forward.id);
}

/// The live state of one tunnel.
@riverpod
ActiveForward? forwardStatus(Ref ref, String id) =>
    ref.watch(forwardRunnerProvider)[id];

/// Runs tunnels, opening one connection per host as needed.
@Riverpod(keepAlive: true)
class ForwardRunner extends _$ForwardRunner {
  final Map<String, ForwardManager> _managers = {};
  final Map<String, SshConnectionLease> _leases = {};

  @override
  Map<String, ActiveForward> build() {
    ref.onDispose(() {
      for (final manager in _managers.values) {
        manager.dispose();
      }
      // Released rather than closed: a shell or the file browser may still be
      // on the same connection.
      for (final lease in _leases.values) {
        unawaited(lease.release());
      }
    });
    return const {};
  }

  /// Starts [forward], connecting to its host if nothing is connected yet.
  Future<void> start(PortForward forward) async {
    try {
      final manager = await _managerFor(forward.hostId);
      await manager.start(forward);
    } on Object catch (error) {
      Loggers.ssh.warning('Could not start ${forward.summary}', error);
      state = {
        ...state,
        forward.id: ActiveForward(
          forward: forward,
          status: PortForwardStatus.failed,
          error: 'Could not connect to the host.',
        ),
      };
    }
  }

  /// Stops [id] wherever it is running.
  Future<void> stop(String id) async {
    for (final manager in _managers.values) {
      await manager.stop(id);
    }
  }

  Future<ForwardManager> _managerFor(String hostId) async {
    final existing = _managers[hostId];
    if (existing != null) return existing;

    final host = await ref.read(sshHostRepositoryProvider).byId(hostId);
    if (host == null) throw StateError('Host $hostId no longer exists');

    // A lease on the host's shared connection: a forward on a host you already
    // have a shell on costs no second authentication.
    final lease = await ref.read(sshConnectionPoolProvider).acquire(host);
    _leases[hostId] = lease;

    final manager = ForwardManager(lease.client)..addListener(_publish);
    _managers[hostId] = manager;
    return manager;
  }

  void _publish() {
    state = {
      for (final manager in _managers.values)
        for (final forward in manager.forwards) forward.forward.id: forward,
    };
  }
}
