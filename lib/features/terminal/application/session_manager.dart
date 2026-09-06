import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/terminal/application/reconnect_policy.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';

part 'session_manager.freezed.dart';
part 'session_manager.g.dart';

/// The set of open terminal sessions and which one is in front.
///
/// Immutable so that Riverpod can tell states apart; the [TerminalSession]
/// objects it holds are themselves mutable and long-lived, and are compared by
/// identity, which is what tab management wants.
@freezed
abstract class SessionsState with _$SessionsState {
  /// Creates a snapshot of the open sessions.
  const factory({
    @Default(<TerminalSession>[]) List<TerminalSession> sessions,
    String? activeId,

    /// The session shown beside the active one, when the window is split.
    ///
    /// Null means a single pane. Only ever set on window sizes that can
    /// actually show two, which the UI enforces — a split on a phone would
    /// leave two terminals too narrow to use.
    String? secondaryId,
  }) = _SessionsState;

  const new _();

  /// The session currently in front, or null when none are open.
  TerminalSession? get active {
    final id = activeId;
    if (id == null) return null;
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// The session in the second pane, or null when not split.
  TerminalSession? get secondary {
    final id = secondaryId;
    if (id == null) return null;
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Whether two panes are showing.
  bool get isSplit => secondary != null;

  /// Whether any session is open.
  bool get isEmpty => sessions.isEmpty;
}

/// Owns every open session: creation, activation, closing and disposal.
///
/// Sessions outlive the widgets showing them — switching tabs must not kill a
/// running command — so they are held here rather than in widget state, and
/// disposed deterministically when closed or when the app shuts down.
@Riverpod(keepAlive: true)
class SessionManager extends _$SessionManager {
  var _nextId = 0;

  /// Mirrors the sessions held in [state], purely so that they can be disposed
  /// when the provider goes away. Riverpod forbids reading `state` inside an
  /// `onDispose` callback, so the list has to be captured outside it.
  final _owned = <TerminalSession>[];

  /// How to rebuild a backend for a session that dropped, by session id.
  ///
  /// Backends are single-use, so reconnecting means making a new one. The
  /// session keeps its id and its place in the tab strip, which is what makes
  /// it feel like the same session coming back rather than a new one.
  final _reconnectors = <String, Future<TerminalBackend> Function()>{};
  final _policies = <String, ReconnectPolicy>{};
  final _attempts = <String, int>{};
  final _timers = <String, Timer>{};
  final _watchers = <String, VoidCallback>{};

  @override
  SessionsState build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
      for (final session in _owned) {
        _detach(session);
        // Fire and forget: the container is going away regardless, and
        // onDispose cannot await.
        unawaited(session.dispose());
      }
      _owned.clear();
    });
    return const SessionsState();
  }

  /// Opens a session driving [backend], activates it, and starts it.
  ///
  /// A backend that fails to start still produces a session: the failure is
  /// reported through [TerminalSession.connectionState] so the UI can explain
  /// it in place, which is far better than a tab that never appears.
  Future<TerminalSession> open({
    required TerminalBackend backend,
    String title = 'Terminal',
    String? hostId,
    Future<TerminalBackend> Function()? reconnect,
    ReconnectPolicy policy = const ReconnectPolicy(),
  }) async {
    final id = 'session-${_nextId++}';
    if (reconnect != null) {
      _reconnectors[id] = reconnect;
      _policies[id] = policy;
    }

    final session = TerminalSession(
      id: id,
      backend: backend,
      hostId: hostId,
      initialTitle: title,
    );

    _owned.add(session);
    state = state.copyWith(
      sessions: [...state.sessions, session],
      activeId: session.id,
    );

    try {
      await session.start();
      _attempts.remove(id);
    } on TerminalBackendFailure {
      // Already reflected in session.connectionState.
    }
    _watchForDrop(session);
    return session;
  }

  /// Watches a session and schedules a reconnection if it drops.
  ///
  /// Only [BackendConnectionState.error] triggers a retry. A session that
  /// closed cleanly — the user typed `exit` — must stay closed; reconnecting
  /// it would be the app arguing with them.
  void _watchForDrop(TerminalSession session) {
    if (!_reconnectors.containsKey(session.id)) return;

    void listener() {
      if (session.connectionState.value != BackendConnectionState.error) return;
      _scheduleReconnect(session.id);
    }

    session.connectionState.addListener(listener);
    _watchers[session.id] = listener;
    listener();
  }

  void _scheduleReconnect(String id) {
    if (_timers.containsKey(id)) return;

    final policy = _policies[id] ?? const ReconnectPolicy();
    final attempt = (_attempts[id] ?? 0) + 1;
    if (!policy.shouldRetry(attempt)) return;

    _attempts[id] = attempt;
    _timers[id] = Timer(policy.delayFor(attempt), () async {
      _timers.remove(id);
      await _reconnect(id);
    });
  }

  Future<void> _reconnect(String id) async {
    final make = _reconnectors[id];
    final index = state.sessions.indexWhere((session) => session.id == id);
    if (make == null || index < 0) return;

    final old = state.sessions[index];
    final TerminalBackend backend;
    try {
      backend = await make();
    } on Object {
      _scheduleReconnect(id);
      return;
    }

    final replacement = TerminalSession(
      id: id,
      backend: backend,
      hostId: old.hostId,
      initialTitle: old.title.value,
    );

    _detach(old);
    _owned
      ..remove(old)
      ..add(replacement);

    final sessions = [...state.sessions]..[index] = replacement;
    state = state.copyWith(sessions: sessions);
    await old.dispose();

    try {
      await replacement.start();
      _attempts.remove(id);
    } on TerminalBackendFailure {
      // Reflected in the new session's state; the watcher retries.
    }
    _watchForDrop(replacement);
  }

  void _detach(TerminalSession session) {
    final listener = _watchers.remove(session.id);
    if (listener != null) session.connectionState.removeListener(listener);
  }

  void _forget(String id) {
    _timers.remove(id)?.cancel();
    _reconnectors.remove(id);
    _policies.remove(id);
    _attempts.remove(id);
  }

  /// Brings the session with [id] to the front. Unknown ids are ignored.
  void activate(String id) {
    if (!state.sessions.any((session) => session.id == id)) return;
    // Activating the session already in the second pane would show it twice.
    if (state.secondaryId == id) {
      state = state.copyWith(activeId: id, secondaryId: null);
      return;
    }
    state = state.copyWith(activeId: id);
  }

  /// Shows the session with [id] in a second pane beside the active one.
  ///
  /// Ignored if it is already the active session: splitting a terminal against
  /// itself shows the same buffer twice, which is confusing rather than useful.
  void splitWith(String id) {
    if (id == state.activeId) return;
    if (!state.sessions.any((session) => session.id == id)) return;
    state = state.copyWith(secondaryId: id);
  }

  /// Returns to a single pane.
  void unsplit() => state = state.copyWith(secondaryId: null);

  /// Closes and disposes the session with [id].
  ///
  /// When the active session is closed, the neighbour to its left becomes
  /// active, matching what every tabbed interface does.
  Future<void> close(String id) async {
    final index = state.sessions.indexWhere((session) => session.id == id);
    if (index < 0) return;

    final session = state.sessions[index];
    final remaining = [...state.sessions]..removeAt(index);

    var nextActive = state.activeId;
    if (state.activeId == id) {
      nextActive = remaining.isEmpty
          ? null
          : remaining[(index - 1).clamp(0, remaining.length - 1)].id;
    }

    _detach(session);
    _forget(id);
    _owned.remove(session);
    state = SessionsState(
      sessions: remaining,
      activeId: nextActive,
      // A closed session must not stay in the second pane.
      secondaryId: state.secondaryId == id ? null : state.secondaryId,
    );
    await session.dispose();
  }

  /// Closes every open session.
  Future<void> closeAll() async {
    final sessions = state.sessions;
    for (final session in sessions) {
      _detach(session);
      _forget(session.id);
    }
    _owned.clear();
    state = const SessionsState();
    for (final session in sessions) {
      await session.dispose();
    }
  }
}
