import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:termino/domain/terminal/session_recorder.dart';

/// The two shapes a recording can be handed over in.
enum RecordingFormat {
  /// Just the text, for pasting into a bug report or an issue.
  text,

  /// asciicast v2 — replays at the original speed in `asciinema` and in every
  /// web player that reads the format.
  asciicast;

  /// What the file is called.
  String get extension => switch (this) {
    RecordingFormat.text => 'txt',
    RecordingFormat.asciicast => 'cast',
  };

  /// How the option reads in the sheet.
  String get label => switch (this) {
    RecordingFormat.text => 'Plain text',
    RecordingFormat.asciicast => 'asciicast',
  };

  /// What it is for.
  String get detail => switch (this) {
    RecordingFormat.text =>
      'Everything that was printed, with no timing. For pasting somewhere.',
    RecordingFormat.asciicast =>
      'Replays at the original speed in asciinema and web players.',
  };
}

/// Writes a recording to a file the user can be handed.
///
/// A file rather than a string, because the interesting formats are files:
/// asciicast is a `.cast` a player opens, and a long session is not something
/// anyone wants on a clipboard.
///
/// Deliberately writes to the app's temporary directory. The file exists to be
/// shared or saved somewhere the user chooses; keeping copies of terminal
/// output around by default is not this app's business — a recording is
/// exactly the kind of file that quietly accumulates secrets.
Future<File> writeRecording(
  SessionRecorder recorder, {
  required RecordingFormat format,
  required String sessionTitle,
  DateTime? now,
  Directory? directory,
}) async {
  final target = directory ?? await getTemporaryDirectory();
  final at = now ?? DateTime.now();

  final file = File(
    '${target.path}/${recordingFileName(sessionTitle, format, at)}',
  );
  final contents = switch (format) {
    RecordingFormat.text => recorder.toPlainText(),
    RecordingFormat.asciicast => recorder.toAsciicast(title: sessionTitle),
  };

  return await file.writeAsString(contents, flush: true);
}

/// A filename built from the session and the time.
///
/// The title comes from the terminal, which means it comes from the remote
/// host — a program can set it to anything with OSC 2, including a path
/// traversal or a name the filesystem will not take. Everything but letters,
/// digits, dash and underscore is replaced.
String recordingFileName(
  String sessionTitle,
  RecordingFormat format,
  DateTime at,
) {
  final safe = sessionTitle
      .replaceAll(RegExp('[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .toLowerCase();

  final stamp = [
    at.year.toString().padLeft(4, '0'),
    at.month.toString().padLeft(2, '0'),
    at.day.toString().padLeft(2, '0'),
    '-',
    at.hour.toString().padLeft(2, '0'),
    at.minute.toString().padLeft(2, '0'),
    at.second.toString().padLeft(2, '0'),
  ].join();

  final name = safe.isEmpty ? 'session' : safe;
  return 'termino-$name-$stamp.${format.extension}';
}
