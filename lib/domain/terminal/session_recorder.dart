import 'dart:convert';

import 'package:meta/meta.dart';

/// One chunk of recorded output, with when it arrived.
@immutable
class RecordedEvent {
  /// Creates an event [elapsed] after the recording started.
  const new({required this.elapsed, required this.data});

  /// Time since the recording began.
  final Duration elapsed;

  /// The text that arrived.
  final String data;
}

/// Records a terminal session for later replay or reading.
///
/// Exports two formats. Plain text is what someone wants when they are pasting
/// output into a bug report; asciicast is what they want when the *timing*
/// matters — it replays at the original speed in `asciinema` and in every web
/// player that reads the format.
///
/// Only output is recorded. Keystrokes are not: they routinely contain
/// passwords typed at a `sudo` prompt, and a recording is a file that gets
/// shared. See SECURITY.md.
class SessionRecorder {
  /// Creates a recorder for a terminal [columns] by [rows].
  new({required this.columns, required this.rows, DateTime? startedAt})
    : startedAt = startedAt ?? DateTime.now();

  /// Terminal width when recording started.
  final int columns;

  /// Terminal height when recording started.
  final int rows;

  /// When recording started.
  final DateTime startedAt;

  final List<RecordedEvent> _events = [];
  Duration _elapsed = Duration.zero;

  /// Everything recorded so far.
  List<RecordedEvent> get events => List.unmodifiable(_events);

  /// Whether anything has been recorded.
  bool get isEmpty => _events.isEmpty;

  /// How long the recording runs.
  Duration get duration => _events.isEmpty ? Duration.zero : _elapsed;

  /// Records [data] arriving [elapsed] after the start.
  ///
  /// The caller supplies the time so that tests are deterministic and so the
  /// recorder does not need a clock of its own.
  void record(String data, Duration elapsed) {
    if (data.isEmpty) return;
    _elapsed = elapsed;
    _events.add(RecordedEvent(elapsed: elapsed, data: data));
  }

  /// Forgets everything recorded.
  void clear() {
    _events.clear();
    _elapsed = Duration.zero;
  }

  /// The session as plain text, with escape sequences stripped.
  ///
  /// Colour codes and cursor movement make a transcript unreadable when it is
  /// pasted somewhere that does not interpret them, which is the whole reason
  /// someone asks for text rather than asciicast.
  String toPlainText() {
    final buffer = StringBuffer();
    for (final event in _events) {
      buffer.write(event.data);
    }
    return _stripEscapes(buffer.toString());
  }

  /// The session as asciicast v2 — a JSON header then one JSON array per line.
  String toAsciicast({String title = 'Termino session'}) {
    final buffer = StringBuffer()
      ..writeln(
        jsonEncode({
          'version': 2,
          'width': columns,
          'height': rows,
          'timestamp': startedAt.millisecondsSinceEpoch ~/ 1000,
          'title': title,
          'env': {'TERM': 'xterm-256color'},
        }),
      );

    for (final event in _events) {
      // Times are seconds with fractional precision, which is what the format
      // specifies and what players expect.
      final seconds =
          event.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      buffer.writeln(jsonEncode([seconds, 'o', event.data]));
    }

    return buffer.toString();
  }

  /// Removes ANSI escape sequences from [text].
  static String _stripEscapes(String text) => text
      // CSI sequences: colour, cursor movement, erase.
      .replaceAll(RegExp(r'\x1b\[[0-9;?]*[ -/]*[@-~]'), '')
      // OSC sequences: window titles and hyperlinks, terminated by BEL or ST.
      .replaceAll(RegExp(r'\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)'), '')
      // Two-character escapes such as ESC ( B.
      .replaceAll(RegExp(r'\x1b[()][0-9A-Za-z]'), '')
      .replaceAll(RegExp(r'\x1b[=>]'), '')
      // Carriage returns that only redraw the current line.
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
}
