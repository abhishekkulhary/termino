import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/terminal/session_recorder.dart';
import 'package:termino/features/terminal/application/recording_export.dart';

/// A recording is a file that gets shared, so what ends up in it — and what it
/// is called — matters more than the usual formatting detail. The name comes
/// from the terminal title, which comes from the remote host.
void main() {
  final at = DateTime.utc(2026, 9, 7, 14, 5, 9);

  SessionRecorder recorderWith(List<(String, Duration)> events) {
    final recorder = SessionRecorder(columns: 80, rows: 24);
    for (final (data, elapsed) in events) {
      recorder.record(data, elapsed);
    }
    return recorder;
  }

  group('recordingFileName', () {
    test('uses the session title and the time', () {
      expect(
        recordingFileName('build server', RecordingFormat.text, at),
        'termino-build-server-20260907-140509.txt',
      );
    });

    test('gives asciicast its own extension', () {
      expect(
        recordingFileName('pi', RecordingFormat.asciicast, at),
        endsWith('.cast'),
      );
    });

    test('refuses a title that would escape the directory', () {
      // A program on the far end sets the title with OSC 2. It can say
      // anything, including this.
      final name = recordingFileName(
        '../../etc/passwd',
        RecordingFormat.text,
        at,
      );

      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('..')));
      expect(name, 'termino-etc-passwd-20260907-140509.txt');
    });

    test('survives a title of nothing usable', () {
      expect(
        recordingFileName('///', RecordingFormat.text, at),
        'termino-session-20260907-140509.txt',
      );
      expect(
        recordingFileName('', RecordingFormat.text, at),
        'termino-session-20260907-140509.txt',
      );
    });

    test('strips characters a filesystem would refuse', () {
      final name = recordingFileName(
        'root@host:~/work *?"<>|',
        RecordingFormat.text,
        at,
      );
      expect(
        RegExp(r'^termino-[a-z0-9_-]+-\d{8}-\d{6}\.txt$').hasMatch(name),
        isTrue,
        reason: name,
      );
    });
  });

  group('writeRecording', () {
    late Directory workspace;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp('termino-recording-');
    });

    tearDown(() {
      if (workspace.existsSync()) workspace.deleteSync(recursive: true);
    });

    test('writes the plain text of what was printed', () async {
      final recorder = recorderWith([
        ('hello ', Duration.zero),
        ('world\n', const Duration(milliseconds: 500)),
      ]);

      final file = await writeRecording(
        recorder,
        format: RecordingFormat.text,
        sessionTitle: 'pi',
        now: at,
        directory: workspace,
      );

      expect(file.readAsStringSync(), 'hello world\n');
      expect(file.path, endsWith('.txt'));
    });

    test('writes asciicast v2, header first', () async {
      final recorder = recorderWith([
        ('hi', const Duration(milliseconds: 250)),
      ]);

      final file = await writeRecording(
        recorder,
        format: RecordingFormat.asciicast,
        sessionTitle: 'pi',
        now: at,
        directory: workspace,
      );

      final lines = file.readAsLinesSync();
      final header = jsonDecode(lines.first) as Map<String, dynamic>;

      expect(header['version'], 2);
      expect(header['width'], 80);
      expect(header['height'], 24);
      expect(header['title'], 'pi');

      final event = jsonDecode(lines[1]) as List<dynamic>;
      expect(event[0], closeTo(0.25, 0.001));
      expect(event[1], 'o', reason: 'output, and only output');
      expect(event[2], 'hi');
    });

    test('two recordings a second apart do not collide', () async {
      final recorder = recorderWith([('x', Duration.zero)]);

      final first = await writeRecording(
        recorder,
        format: RecordingFormat.text,
        sessionTitle: 'pi',
        now: at,
        directory: workspace,
      );
      final second = await writeRecording(
        recorder,
        format: RecordingFormat.text,
        sessionTitle: 'pi',
        now: at.add(const Duration(seconds: 1)),
        directory: workspace,
      );

      expect(first.path, isNot(second.path));
    });
  });
}
