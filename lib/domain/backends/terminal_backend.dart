import 'dart:typed_data';

/// The lifecycle of a [TerminalBackend].
///
/// Named `BackendConnectionState` rather than `ConnectionState` because Flutter
/// already exports a `ConnectionState` (from `AsyncSnapshot`) that presentation
/// code uses constantly; two identically named enums in one file is a recipe
/// for a confusing import shadow.
///
/// The legal transitions are:
///
/// ```text
/// idle ──▶ connecting ──▶ connected ──▶ closed
///   │           │             │
///   └───────────┴─────────────┴────────▶ error
/// ```
///
/// [closed] and [error] are terminal: a backend is never reused after either.
enum BackendConnectionState {
  /// Created but [TerminalBackend.start] has not been called.
  idle,

  /// [TerminalBackend.start] is in progress. For SSH this covers the TCP
  /// connection, the key exchange, host key verification and authentication.
  connecting,

  /// Attached and exchanging bytes.
  connected,

  /// Finished normally. The child exited, or the session was closed.
  closed,

  /// Finished abnormally. [TerminalBackend.failure] explains why.
  error;

  /// Whether no further state change can occur.
  bool get isTerminal =>
      this == BackendConnectionState.closed ||
      this == BackendConnectionState.error;

  /// Whether the backend can currently accept [TerminalBackend.write].
  bool get canWrite => this == BackendConnectionState.connected;
}

/// Why a backend ended up in [BackendConnectionState.error].
///
/// Backends never surface a raw exception to the UI. Every failure is mapped
/// into this taxonomy so that presentation code can show something a human can
/// act on, and so that an error message cannot leak internal state or secrets.
/// The [cause] is retained for logs only.
class TerminalBackendFailure implements Exception {
  /// Creates a failure of [kind], with a human-readable [message].
  const new(this.kind, this.message, {this.cause});

  /// What sort of failure this is.
  final TerminalBackendFailureKind kind;

  /// A message safe to show to a user. Never contains credentials.
  final String message;

  /// The underlying error, for logging only. Never shown to a user.
  final Object? cause;

  @override
  String toString() => 'TerminalBackendFailure(${kind.name}: $message)';
}

/// The categories of [TerminalBackendFailure].
enum TerminalBackendFailureKind {
  /// The platform cannot provide this backend at all — a local shell on iOS,
  /// for example.
  unsupported,

  /// The host could not be reached.
  network,

  /// The host was reached but rejected our credentials.
  authentication,

  /// The host key did not match the one we have on record. This is never
  /// recoverable without explicit user action.
  hostKeyMismatch,

  /// A local shell could not be spawned.
  spawn,

  /// The peer closed the connection unexpectedly.
  disconnected,

  /// Anything else.
  unknown,
}

/// A bidirectional byte stream attached to a terminal, plus resize control.
///
/// This is the central abstraction of the application: a local PTY, a remote
/// SSH session and a replayed test fixture are all implementations of it, so
/// the terminal UI never knows what it is attached to.
///
/// Lifecycle: construct, [start], exchange bytes, [close]. A backend is
/// single-use — once it reaches a terminal state it is discarded rather than
/// restarted. Reconnection creates a new backend.
///
/// Implementations should extend `TerminalBackendBase`, which provides the
/// state machine and stream plumbing.
abstract class TerminalBackend {
  /// Raw bytes from the remote host or child process.
  ///
  /// This is deliberately bytes and not text: a UTF-8 sequence can be split
  /// across two reads, so decoding belongs downstream where it can be done
  /// statefully.
  Stream<Uint8List> get output;

  /// Completes when the session ends. The value is the child's exit code where
  /// one is known, and null otherwise (a dropped connection, or a peer that
  /// never reported one).
  ///
  /// Completes with an error only if the session ended in a way the caller must
  /// handle; ordinary failures are reported through [states] and [failure].
  Future<int?> get exitCode;

  /// The current lifecycle state.
  BackendConnectionState get state;

  /// Lifecycle changes, starting with the current [state].
  ///
  /// Broadcast: several listeners (the session, a status banner, logging) all
  /// observe it.
  Stream<BackendConnectionState> get states;

  /// Why the backend failed, if [state] is [BackendConnectionState.error].
  TerminalBackendFailure? get failure;

  /// Attaches the backend. Completes once the session is usable.
  ///
  /// Throws [TerminalBackendFailure] if the session could not be established.
  /// Calling this more than once is a programming error.
  Future<void> start();

  /// Sends [data] to the remote host or child process.
  ///
  /// Ignored when the backend is not [BackendConnectionState.connected]: input
  /// racing against a disconnect is normal and must not throw at the caller,
  /// which is usually a keystroke handler.
  void write(Uint8List data);

  /// Tells the peer the terminal is now [columns] by [rows].
  ///
  /// The pixel dimensions are optional and only some programs use them; pass 0
  /// when unknown.
  void resize(int columns, int rows, {int pixelWidth = 0, int pixelHeight = 0});

  /// Ends the session and releases every resource it holds.
  ///
  /// Safe to call more than once, and safe to call before [start].
  Future<void> close();
}
