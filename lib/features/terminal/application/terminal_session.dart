import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
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

  /// The emulator holding the screen and scrollback.
  final Terminal terminal;

  /// The window title, as set by the program via OSC 0 or OSC 2.
  final ValueNotifier<String> title;

  /// The backend's lifecycle, mirrored for the UI.
  final ValueNotifier<BackendConnectionState> connectionState;

  /// Increments every time the program rings the bell. A counter rather than an
  /// event so a widget can react with `ValueListenableBuilder`.
  final ValueNotifier<int> bellCount;

  /// How backend output is coalesced before reaching the emulator.
  final TerminalOutputBatcher batcher;

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
    _output = _decoder
        .bind(batcher.bind(backend.output))
        .listen(terminal.write);

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
