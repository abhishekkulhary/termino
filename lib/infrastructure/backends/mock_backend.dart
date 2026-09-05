import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/backends/terminal_backend_base.dart';

/// One scripted chunk of output, emitted [delay] after the previous frame.
class MockOutputFrame {
  /// Creates a frame emitting [bytes] after [delay].
  const new(this.bytes, {this.delay = Duration.zero});

  /// Creates a frame emitting the UTF-8 encoding of [text] after [delay].
  factory text(String text, {Duration delay = Duration.zero}) =>
      MockOutputFrame(Uint8List.fromList(utf8.encode(text)), delay: delay);

  /// The bytes to emit.
  final Uint8List bytes;

  /// How long to wait before emitting them.
  final Duration delay;
}

/// A resize the terminal asked the backend to perform.
class MockResize {
  /// Creates a record of a resize request.
  const new(this.columns, this.rows, this.pixelWidth, this.pixelHeight);

  /// Width in character cells.
  final int columns;

  /// Height in character cells.
  final int rows;

  /// Width in pixels, or 0 when unknown.
  final int pixelWidth;

  /// Height in pixels, or 0 when unknown.
  final int pixelHeight;

  @override
  String toString() => 'MockResize(${columns}x$rows)';
}

/// A [TerminalBackend] that replays a scripted sequence instead of talking to
/// anything real.
///
/// It backs three things: unit tests of the session wiring, the widget
/// catalogue and golden tests (which need a terminal with deterministic
/// contents and no I/O), and manual UI work on platforms where a real backend
/// is unavailable.
///
/// Everything written to it is recorded in [writes] and every resize in
/// [resizes], so a test can assert that user input actually reached the far
/// end.
class MockBackend extends TerminalBackendBase {
  /// Replays [frames], then finishes with [exitStatus].
  ///
  /// When [echoInput] is true, anything written is echoed back as output, which
  /// makes the mock behave enough like a shell for interactive UI work.
  /// If [failWith] is given, [start] fails with it instead of connecting.
  new({
    this.frames = const [],
    this.exitStatus = 0,
    this.echoInput = false,
    this.closeWhenDrained = true,
    this.failWith,
  });

  /// Replays a single chunk of [text] and stays open.
  factory text(String text) => MockBackend(
    frames: [MockOutputFrame.text(text)],
    closeWhenDrained: false,
  );

  /// A backend whose [start] always fails with [failure].
  factory failing(TerminalBackendFailure failure) =>
      MockBackend(failWith: failure);

  /// The scripted output.
  final List<MockOutputFrame> frames;

  /// The exit code reported once the frames are exhausted.
  final int? exitStatus;

  /// Whether writes are echoed back as output.
  final bool echoInput;

  /// Whether the session ends once every frame has been replayed. False keeps
  /// it open, which is what a golden or a catalogue entry wants.
  final bool closeWhenDrained;

  /// When set, [start] fails with this instead of connecting.
  final TerminalBackendFailure? failWith;

  final List<Uint8List> _writes = [];
  final List<MockResize> _resizes = [];

  /// Frames are pushed through a controller rather than yielded from an
  /// `async*` generator. A generator parked on a future that never completes
  /// (which is how a session is held open) cannot be cancelled: the cancel
  /// waits for the generator to finish and deadlocks. A controller can simply
  /// be closed.
  final StreamController<Uint8List> _frames = StreamController<Uint8List>();

  /// Everything written to this backend, in order.
  List<Uint8List> get writes => List.unmodifiable(_writes);

  /// Everything written to this backend, decoded as UTF-8 and concatenated.
  String get writtenText =>
      _writes.map((bytes) => utf8.decode(bytes, allowMalformed: true)).join();

  /// Every resize requested of this backend, in order.
  List<MockResize> get resizes => List.unmodifiable(_resizes);

  @override
  Future<void> connect() async {
    final failure = failWith;
    if (failure != null) throw failure;
    pipeOutput(_frames.stream);
    unawaited(_replayFrames());
  }

  Future<void> _replayFrames() async {
    for (final frame in frames) {
      if (frame.delay > Duration.zero) await Future<void>.delayed(frame.delay);
      if (_frames.isClosed) return;
      _frames.add(frame.bytes);
    }
    // Leaving the controller open keeps the session connected, which is what a
    // golden test or a catalogue entry wants.
    if (closeWhenDrained && !_frames.isClosed) unawaited(_frames.close());
  }

  @override
  void send(Uint8List data) {
    _writes.add(data);
    if (echoInput) emitOutput(data);
  }

  @override
  void resize(
    int columns,
    int rows, {
    int pixelWidth = 0,
    int pixelHeight = 0,
  }) {
    _resizes.add(MockResize(columns, rows, pixelWidth, pixelHeight));
  }

  @override
  Future<void> disconnect() async {
    // Not awaited: by the time disconnect() runs the base class has already
    // cancelled its subscription, so this controller has no listener and its
    // close future would never complete.
    if (!_frames.isClosed) unawaited(_frames.close());
  }

  @override
  void setClosed([int? code]) => super.setClosed(code ?? exitStatus);
}
