import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
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

  @override
  SessionsState build() {
    ref.onDispose(() {
      for (final session in _owned) {
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
  }) async {
    final session = TerminalSession(
      id: 'session-${_nextId++}',
      backend: backend,
      initialTitle: title,
    );

    _owned.add(session);
    state = state.copyWith(
      sessions: [...state.sessions, session],
      activeId: session.id,
    );

    try {
      await session.start();
    } on TerminalBackendFailure {
      // Already reflected in session.connectionState.
    }
    return session;
  }

  /// Brings the session with [id] to the front. Unknown ids are ignored.
  void activate(String id) {
    if (!state.sessions.any((session) => session.id == id)) return;
    state = state.copyWith(activeId: id);
  }

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

    _owned.remove(session);
    state = SessionsState(sessions: remaining, activeId: nextActive);
    await session.dispose();
  }

  /// Closes every open session.
  Future<void> closeAll() async {
    final sessions = state.sessions;
    _owned.clear();
    state = const SessionsState();
    for (final session in sessions) {
      await session.dispose();
    }
  }
}
