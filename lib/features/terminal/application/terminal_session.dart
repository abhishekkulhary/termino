import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/terminal/session_recorder.dart';
import 'package:termino/features/terminal/application/throughput_meter.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';
import 'package:xterm/xterm.dart';

/// A terminal attached to a backend: the emulator, the byte stream feeding it,
/// and the metadata the UI needs to label a tab.
///
/// The wiring is deliberately small, and all of it lives here so that no widget
/// ever talks to a backend directly:
///
/// ```text
/// backend.output ─▶ batcher ─▶ UTF-8 decoder ─▶ terminal.write
/// terminal.onOutput ─▶ UTF-8 encoder ─▶ backend.write
/// terminal.onResize ─▶ backend.resize
/// terminal.onTitleChange ─▶ title
/// ```
///
/// A session owns its backend and closes it on [dispose].
class TerminalSession {
  /// Creates a session driving [backend].
  ///
  /// The terminal callbacks are wired immediately, before [start], so that
  /// nothing emitted during connection is missed.
  new({
    required this.id,
    required this.backend,
    this.hostId,
    String initialTitle = 'Terminal',
    int maxLines = 10000,
    this.batcher = const TerminalOutputBatcher(),
    Terminal? terminal,
  }) : title = ValueNotifier<String>(initialTitle),
       connectionState = ValueNotifier<BackendConnectionState>(backend.state),
       bellCount = ValueNotifier<int>(0),
       terminal = terminal ?? Terminal(maxLines: maxLines) {
    _attach();
  }

  /// Identifies this session for the lifetime of the app run.
  final String id;

  /// The byte stream this terminal is attached to.
  final TerminalBackend backend;

  /// The saved host this session connects to, when it is an SSH session.
  ///
  /// Null for a local shell. Snippets use it to decide which of
  /// them apply here.
  final String? hostId;

  /// The emulator holding the screen and scrollback.
  final Terminal terminal;

  /// The window title, as set by the program via OSC 0 or OSC 2.
  final ValueNotifier<String> title;

  /// The backend's lifecycle, mirrored for the UI.
  final ValueNotifier<BackendConnectionState> connectionState;

  /// Increments every time the program rings the bell. A counter rather than an
  /// event so a widget can react with `ValueListenableBuilder`.
  final ValueNotifier<int> bellCount;

  /// How fast output is arriving, and how much has arrived in total.
  ///
  /// Measured in bytes, before decoding: what the user wants to know is what
  /// the connection is doing, and a multi-byte character is not two events.
  final ThroughputMeter throughput = ThroughputMeter();

  /// How backend output is coalesced before reaching the emulator.
  final TerminalOutputBatcher batcher;

  /// Records output when the user asks for it. Null until then.
  ///
  /// The tap sits on the session rather than the backend because the backend's
  /// output stream is single-subscription — that is what preserves
  /// backpressure — so a second listener is not possible there.
  SessionRecorder? get recorder => _recorder;
  SessionRecorder? _recorder;
  Stopwatch? _recordingClock;

  /// Starts recording, replacing any recording in progress.
  SessionRecorder startRecording() {
    final recorder = SessionRecorder(
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    _recorder = recorder;
    _recordingClock = Stopwatch()..start();
    return recorder;
  }

  /// Stops recording and returns what was captured, or null if none was in
  /// progress.
  SessionRecorder? stopRecording() {
    final recorder = _recorder;
    _recordingClock?.stop();
    _recordingClock = null;
    _recorder = null;
    return recorder;
  }

  /// Whether output is currently being recorded.
  bool get isRecording => _recorder != null;

  /// Malformed input is replaced rather than thrown on: a terminal is a byte
  /// pipe and will occasionally carry binary that is not valid UTF-8. Killing
  /// the session over it would be absurd.
  static const _decoder = Utf8Decoder(allowMalformed: true);

  StreamSubscription<String>? _output;
  StreamSubscription<BackendConnectionState>? _states;
  var _disposed = false;

  void _attach() {
    terminal
      ..onOutput = _handleTerminalOutput
      ..onResize = _handleTerminalResize
      ..onTitleChange = (value) {
        if (value.trim().isNotEmpty) title.value = value;
      }
      ..onBell = () => bellCount.value++;
  }

  void _handleTerminalOutput(String data) {
    backend.write(Uint8List.fromList(utf8.encode(data)));
  }

  void _handleTerminalResize(
    int width,
    int height,
    int pixelWidth,
    int pixelHeight,
  ) {
    backend.resize(
      width,
      height,
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
    );
  }

  /// Connects the backend and begins feeding the terminal.
  ///
  /// Rethrows the [TerminalBackendFailure] if the backend could not start; the
  /// session stays usable so the failure can be shown in the terminal itself.
  Future<void> start() async {
    _states = backend.states.listen((_) => _syncConnectionState());

    // Batch first, then decode: coalescing before decoding means far fewer
    // decoder invocations, and the decoder carries any partial UTF-8 sequence
    // across chunk boundaries so a split multi-byte character still renders.
    // Counted between the batcher and the decoder, so the measurement is of
    // bytes off the wire rather than of characters after they are assembled.
    final counted = batcher.bind(backend.output).map((chunk) {
      throughput.add(chunk.length);
      return chunk;
    });

    _output = _decoder.bind(counted).listen((data) {
      _recorder?.record(data, _recordingClock?.elapsed ?? Duration.zero);
      terminal.write(data);
    });

    try {
      await backend.start();
    } finally {
      // The states stream delivers asynchronously, so without this the session
      // would still report `idle` for a microtask after start() has already
      // failed — long enough for a caller to read a stale value and show the
      // wrong thing.
      _syncConnectionState();
    }
  }

  void _syncConnectionState() {
    if (!_disposed) connectionState.value = backend.state;
  }

  /// Writes [text] to the backend as if the user had typed it.
  ///
  /// Used by snippets and the key accessory bar.
  void sendText(String text) => _handleTerminalOutput(text);

  /// Closes the backend and releases everything this session owns.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _output?.cancel();
    await _states?.cancel();
    await backend.close();

    terminal
      ..onOutput = null
      ..onResize = null
      ..onTitleChange = null
      ..onBell = null;

    title.dispose();
    connectionState.dispose();
    bellCount.dispose();
  }
}
