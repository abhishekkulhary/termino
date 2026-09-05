import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/features/forwarding/application/forward_manager.dart';
import 'package:termino/features/hosts/application/ssh_connector.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

part 'forwarding_providers.g.dart';

/// The configured tunnels.
///
/// Held in memory for now. Persisting them alongside their host is a small
/// change to the drift schema and belongs with the rest of the settings work
/// in Phase 6.
@Riverpod(keepAlive: true)
class PortForwards extends _$PortForwards {
  @override
  List<PortForward> build() => const [];

  /// Adds or updates a tunnel.
  void save(PortForward forward) {
    final existing = state.indexWhere((f) => f.id == forward.id);
    state = existing < 0 ? [...state, forward] : [...state]
      ..[existing < 0 ? state.length - 1 : existing] = forward;
  }

  /// Removes a tunnel, stopping it first.
  void remove(String id) {
    unawaited(ref.read(forwardRunnerProvider.notifier).stop(id));
    state = state.where((forward) => forward.id != id).toList();
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
  final Map<String, SshConnection> _connections = {};

  @override
  Map<String, ActiveForward> build() {
    ref.onDispose(() {
      for (final manager in _managers.values) {
        manager.dispose();
      }
      for (final connection in _connections.values) {
        unawaited(connection.close());
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

    final connection = await ref.read(sshConnectorProvider).open(host);
    _connections[hostId] = connection;

    final manager = ForwardManager(connection.client)..addListener(_publish);
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
