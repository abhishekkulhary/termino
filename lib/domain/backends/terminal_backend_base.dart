import 'dart:async';
import 'dart:typed_data';

import 'package:termino/domain/backends/terminal_backend.dart';

/// Shared plumbing for every [TerminalBackend]: the lifecycle state machine,
/// the output stream, and deterministic teardown.
///
/// Local PTY, SSH and mock backends differ only in where their bytes come
/// from. Everything else — legal state transitions, refusing to start twice,
/// completing [exitCode] exactly once, releasing resources on [close] — is
/// identical, easy to get subtly wrong, and therefore lives here and is tested
/// once.
///
/// Subclasses implement [connect] and [disconnect], and push bytes with
/// [emitOutput] or [pipeOutput].
abstract class TerminalBackendBase implements TerminalBackend {
  /// Output is deliberately a **single-subscription** stream.
  ///
  /// A broadcast stream cannot apply backpressure: pausing one listener does
  /// not pause the source, so a process writing faster than the terminal can
  /// render would grow an unbounded queue. Keeping one subscriber means a
  /// paused terminal pauses the socket, which is the entire point. Anything
  /// that wants to observe output as well — session recording, for instance —
  /// taps the session downstream, not the backend.
  final StreamController<Uint8List> _output = StreamController<Uint8List>();

  final StreamController<BackendConnectionState> _states =
      StreamController<BackendConnectionState>.broadcast();

  final Completer<int?> _exitCode = Completer<int?>();

  BackendConnectionState _state = BackendConnectionState.idle;
  TerminalBackendFailure? _failure;
  StreamSubscription<Uint8List>? _pipe;
  bool _startCalled = false;
  bool _closeCalled = false;

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  Future<int?> get exitCode => _exitCode.future;

  @override
  BackendConnectionState get state => _state;

  @override
  TerminalBackendFailure? get failure => _failure;

  @override
  Stream<BackendConnectionState> get states {
    // Every subscriber must see the current state first, otherwise a listener
    // that attaches after the backend connected would sit forever on `idle`.
    // The replay and the subscription happen in the same synchronous block, so
    // no transition can slip between them.
    final controller = StreamController<BackendConnectionState>();
    controller.onListen = () {
      controller.add(_state);
      if (_state.isTerminal) {
        unawaited(controller.close());
        return;
      }
      final subscription = _states.stream.listen(
        controller.add,
        onDone: () => unawaited(controller.close()),
      );
      controller.onCancel = subscription.cancel;
    };
    return controller.stream;
  }

  @override
  Future<void> start() async {
    if (_startCalled) {
      throw StateError(
        'start() was called twice on $runtimeType. Backends are single-use; '
        'create a new one to reconnect.',
      );
    }
    _startCalled = true;

    _transitionTo(BackendConnectionState.connecting);
    try {
      await connect();
    } on TerminalBackendFailure catch (failure) {
      setFailed(failure);
      rethrow;
    } on Object catch (error, stackTrace) {
      final failure = TerminalBackendFailure(
        TerminalBackendFailureKind.unknown,
        'The session could not be started.',
        cause: error,
      );
      setFailed(failure);
      Error.throwWithStackTrace(failure, stackTrace);
    }

    // A backend may have completed during connect() — a fixture that replays
    // nothing, or a child that exited immediately.
    if (_state == BackendConnectionState.connecting) {
      _transitionTo(BackendConnectionState.connected);
    }
  }

  @override
  void write(Uint8List data) {
    // Deliberately silent when not connected. The caller is usually a keystroke
    // handler, and a key pressed as a connection drops must not throw at it.
    if (!_state.canWrite) return;
    send(data);
  }

  @override
  Future<void> close() async {
    if (_closeCalled) return;
    _closeCalled = true;

    await _pipe?.cancel();
    _pipe = null;

    try {
      await disconnect();
    } on Object {
      // Teardown failures are not actionable: the session is over either way.
      // Swallowing here keeps close() safe to call from a dispose path.
    }

    setClosed();

    // Deliberately not awaited. `_output` is single-subscription, and closing
    // such a controller returns a future that only completes once its done
    // event has been delivered — which never happens if nothing ever listened.
    // A session torn down before the UI attached would hang here forever.
    unawaited(_output.close());
    unawaited(_states.close());
  }

  // --- For subclasses -------------------------------------------------------

  /// Establishes the session. Called exactly once, by [start].
  ///
  /// Throw a [TerminalBackendFailure] to fail with a specific reason; any other
  /// exception is mapped to [TerminalBackendFailureKind.unknown].
  Future<void> connect();

  /// Tears the session down. Called exactly once, by [close]. Must not throw.
  Future<void> disconnect();

  /// Sends [data] to the peer. Only called while connected.
  void send(Uint8List data);

  /// Called when the source passed to [pipeOutput] completes.
  ///
  /// The default is the obvious one: the stream ending *is* the session
  /// ending. A local PTY overrides this, because its output and its exit
  /// status arrive on separate channels and closing here would report a null
  /// exit code a moment before the real one lands.
  void handleOutputDone() {
    if (!_state.isTerminal) setClosed();
  }

  /// Whether output is currently paused by the downstream consumer. Subclasses
  /// that push manually should respect it.
  bool get isOutputPaused => _output.isPaused;

  /// Emits [data] to the terminal.
  void emitOutput(Uint8List data) {
    if (_output.isClosed) return;
    _output.add(data);
  }

  /// Binds [source] to the output stream, propagating backpressure: when the
  /// terminal pauses, [source] is paused too.
  ///
  /// This is the preferred way for a backend to publish bytes, because the
  /// pause propagation is what keeps a flood of output from growing an
  /// unbounded queue.
  void pipeOutput(Stream<Uint8List> source) {
    _pipe = source.listen(
      emitOutput,
      onError: (Object error, StackTrace stackTrace) {
        setFailed(
          TerminalBackendFailure(
            TerminalBackendFailureKind.disconnected,
            'The connection was lost.',
            cause: error,
          ),
        );
      },
      onDone: handleOutputDone,
    );
    _output
      ..onPause = _pipe!.pause
      ..onResume = _pipe!.resume;
  }

  /// Marks the session finished normally, optionally reporting [code].
  void setClosed([int? code]) {
    if (_state.isTerminal) return;
    _transitionTo(BackendConnectionState.closed);
    if (!_exitCode.isCompleted) _exitCode.complete(code);
  }

  /// Marks the session finished abnormally.
  void setFailed(TerminalBackendFailure failure) {
    if (_state.isTerminal) return;
    _failure = failure;
    _transitionTo(BackendConnectionState.error);
    if (!_exitCode.isCompleted) _exitCode.complete(null);
  }

  void _transitionTo(BackendConnectionState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
