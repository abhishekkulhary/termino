import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/entities/port_forward.dart';

/// A tunnel that is running, or trying to.
@immutable
class ActiveForward {
  /// Creates a record of a running tunnel.
  const new({
    required this.forward,
    required this.status,
    this.error,
    this.connectionCount = 0,
  });

  /// What is being forwarded.
  final PortForward forward;

  /// Whether it is up.
  final PortForwardStatus status;

  /// Why it stopped, when it failed.
  final String? error;

  /// How many connections it has carried, for the live status in the list.
  final int connectionCount;

  /// Returns a copy with the given changes.
  ActiveForward copyWith({
    PortForwardStatus? status,
    String? error,
    int? connectionCount,
    bool clearError = false,
  }) => ActiveForward(
    forward: forward,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
    connectionCount: connectionCount ?? this.connectionCount,
  );
}

/// Starts and stops port forwards over an SSH connection.
///
/// Local and dynamic forwards listen on a socket on this device, so they need
/// `dart:io` and are unavailable on the web; remote forwards are asked for over
/// the SSH channel and work anywhere. The manager reports which is which rather
/// than failing at the moment the user presses start.
class ForwardManager extends ChangeNotifier {
  /// Creates a manager driving an authenticated SSH client.
  new(this._client);

  final SSHClient _client;

  final Map<String, ActiveForward> _forwards = {};
  final Map<String, ServerSocket> _listeners = {};
  final Map<String, SSHRemoteForward> _remotes = {};
  final Map<String, SSHDynamicForward> _dynamics = {};
  var _disposed = false;

  /// Every tunnel the manager knows about.
  List<ActiveForward> get forwards => List.unmodifiable(_forwards.values);

  /// The state of one tunnel.
  ActiveForward? statusOf(String id) => _forwards[id];

  /// Starts [forward], replacing any previous run of the same id.
  Future<void> start(PortForward forward) async {
    if (!forward.isValid) {
      _set(
        forward,
        PortForwardStatus.failed,
        error: 'The tunnel is incomplete.',
      );
      return;
    }

    await stop(forward.id);
    _set(forward, PortForwardStatus.starting, clearError: true);

    try {
      switch (forward.kind) {
        case PortForwardKind.local:
          await _startLocal(forward);
        case PortForwardKind.remote:
          await _startRemote(forward);
        case PortForwardKind.dynamic:
          await _startDynamic(forward);
      }
      _set(forward, PortForwardStatus.active);
    } on Object catch (error) {
      Loggers.ssh.warning('Forward ${forward.summary} failed', error);
      _set(forward, PortForwardStatus.failed, error: _describe(error));
    }
  }

  /// Stops [id], if it is running.
  Future<void> stop(String id) async {
    await _listeners.remove(id)?.close();
    _remotes.remove(id)?.close();
    unawaited(_dynamics.remove(id)?.close());

    final existing = _forwards[id];
    if (existing != null && !_disposed) {
      _forwards[id] = existing.copyWith(status: PortForwardStatus.stopped);
      notifyListeners();
    }
  }

  /// Stops everything.
  Future<void> stopAll() async {
    for (final id in _forwards.keys.toList()) {
      await stop(id);
    }
  }

  /// Stops everything and waits for it, before the connection goes away.
  ///
  /// [dispose] cannot await, so a caller that disposes and then immediately
  /// closes the SSH connection races the cancellation of a remote forward —
  /// which surfaces as `SSHStateError(SSH client closed)` from the middle of
  /// teardown. Anything that owns both should await this first.
  Future<void> shutdown() async {
    final hadRemote = _remotes.isNotEmpty;
    await stopAll();

    // `SSHRemoteForward.close()` returns void: dartssh2 sends the
    // cancel-tcpip-forward request without awaiting the server's reply. Close
    // the client immediately afterwards and that pending request is rejected,
    // which surfaces as `SSHStateError(SSH client closed)` escaping from
    // teardown. There is nothing to await, so the only option is to let it
    // land.
    if (hadRemote) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    _disposed = true;
  }

  /// `-L`: listen here, connect from the server.
  Future<void> _startLocal(PortForward forward) async {
    final socket = await ServerSocket.bind(
      forward.bindAddress,
      forward.listenPort,
    );
    _listeners[forward.id] = socket;

    socket.listen(
      (connection) async {
        _count(forward.id);
        try {
          final channel = await _client.forwardLocal(
            forward.destinationHost!,
            forward.destinationPort!,
          );
          unawaited(connection.cast<List<int>>().pipe(channel.sink));
          unawaited(channel.stream.cast<List<int>>().pipe(connection));
        } on Object catch (error) {
          Loggers.ssh.warning('Forwarded connection failed', error);
          connection.destroy();
        }
      },
      // Without a handler the stream's error escapes as an unhandled async
      // error the moment the connection drops, which takes down whatever is
      // listening rather than showing the tunnel as failed.
      onError: (Object error) => _fail(forward.id, error),
    );
  }

  /// `-R`: the server listens, connections come back to us.
  Future<void> _startRemote(PortForward forward) async {
    final remote = await _client.forwardRemote(port: forward.listenPort);
    if (remote == null) {
      throw StateError('The server refused to listen on ${forward.listenPort}');
    }
    _remotes[forward.id] = remote;

    remote.connections.listen((channel) async {
      _count(forward.id);
      try {
        final socket = await Socket.connect(
          forward.destinationHost,
          forward.destinationPort!,
        );
        unawaited(channel.stream.cast<List<int>>().pipe(socket));
        unawaited(socket.cast<List<int>>().pipe(channel.sink));
      } on Object catch (error) {
        Loggers.ssh.warning('Reverse connection failed', error);
        unawaited(channel.close());
      }
    });
  }

  /// `-D`: a SOCKS proxy here, dialled from the server.
  Future<void> _startDynamic(PortForward forward) async {
    _dynamics[forward.id] = await _client.forwardDynamic(
      bindHost: forward.bindAddress,
      bindPort: forward.listenPort,
    );
  }

  /// Marks a tunnel as failed because its underlying stream broke.
  void _fail(String id, Object error) {
    final existing = _forwards[id];
    if (existing == null || _disposed) return;
    if (existing.status == PortForwardStatus.stopped) return;

    Loggers.ssh.warning('Forward ${existing.forward.summary} dropped', error);
    _forwards[id] = existing.copyWith(
      status: PortForwardStatus.failed,
      error: _describe(error),
    );
    notifyListeners();
  }

  void _count(String id) {
    final existing = _forwards[id];
    if (existing == null || _disposed) return;
    _forwards[id] = existing.copyWith(
      connectionCount: existing.connectionCount + 1,
    );
    notifyListeners();
  }

  void _set(
    PortForward forward,
    PortForwardStatus status, {
    String? error,
    bool clearError = false,
  }) {
    if (_disposed) return;
    _forwards[forward.id] = ActiveForward(
      forward: forward,
      status: status,
      error: clearError ? null : (error ?? _forwards[forward.id]?.error),
      connectionCount: _forwards[forward.id]?.connectionCount ?? 0,
    );
    notifyListeners();
  }

  /// Turns an exception into something the user can act on.
  static String _describe(Object error) {
    final text = error.toString().toLowerCase();
    // The wording differs by platform: Linux says "address already in use",
    // macOS says the shared flag to bind() needs to be true. Both mean the
    // same thing to a user.
    if (text.contains('address already in use') ||
        text.contains('shared flag')) {
      return 'That port is already in use on this device.';
    }
    if (text.contains('permission')) {
      return 'Ports below 1024 need elevated privileges.';
    }
    if (text.contains('refused to listen')) {
      return 'The server refused to open that port. It may need '
          'GatewayPorts enabled.';
    }
    return 'The tunnel could not be started.';
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(stopAll());
    super.dispose();
  }
}
