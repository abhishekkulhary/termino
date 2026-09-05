import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/terminal/session_recorder.dart';

void main() {
  late SessionRecorder recorder;

  setUp(() {
    recorder = SessionRecorder(
      columns: 80,
      rows: 24,
      startedAt: DateTime.utc(2026, 9, 6, 12),
    );
  });

  group('recording', () {
    test('starts empty', () {
      expect(recorder.isEmpty, isTrue);
      expect(recorder.duration, Duration.zero);
    });

    test('captures output with its timing', () {
      recorder
        ..record('first', const Duration(milliseconds: 100))
        ..record('second', const Duration(milliseconds: 350));

      expect(recorder.events, hasLength(2));
      expect(recorder.events.first.data, 'first');
      expect(recorder.duration, const Duration(milliseconds: 350));
    });

    test('ignores empty writes', () {
      recorder.record('', const Duration(milliseconds: 10));

      expect(recorder.isEmpty, isTrue);
    });

    test('clear forgets everything', () {
      recorder
        ..record('x', const Duration(milliseconds: 10))
        ..clear();

      expect(recorder.isEmpty, isTrue);
      expect(recorder.duration, Duration.zero);
    });
  });

  group('plain text', () {
    test('joins the output', () {
      recorder
        ..record('hello ', Duration.zero)
        ..record('world', const Duration(milliseconds: 5));

      expect(recorder.toPlainText(), 'hello world');
    });

    test('strips colour codes', () {
      recorder.record('\x1b[31mred\x1b[0m plain', Duration.zero);

      expect(recorder.toPlainText(), 'red plain');
    });

    test('strips cursor movement and erase sequences', () {
      recorder.record('a\x1b[2K\x1b[1;1Hb\x1b[?25l', Duration.zero);

      expect(recorder.toPlainText(), 'ab');
    });

    test('strips OSC titles and hyperlinks', () {
      recorder.record('\x1b]0;a title\x07visible', Duration.zero);

      expect(recorder.toPlainText(), 'visible');
    });

    test('normalises line endings', () {
      recorder.record('one\r\ntwo\r', Duration.zero);

      expect(recorder.toPlainText(), 'one\ntwo\n');
    });
  });

  group('asciicast', () {
    test('starts with a version 2 header', () {
      recorder.record('x', Duration.zero);

      final header = jsonDecode(
        recorder.toAsciicast().split('\n').first,
      ) as Map<String, dynamic>;

      expect(header['version'], 2);
      expect(header['width'], 80);
      expect(header['height'], 24);
      expect(header['env'], {'TERM': 'xterm-256color'});
    });

    test('writes one event array per chunk, with seconds', () {
      recorder
        ..record('a', const Duration(milliseconds: 500))
        ..record('b', const Duration(milliseconds: 1500));

      final lines = recorder
          .toAsciicast()
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();

      expect(lines, hasLength(3), reason: 'header plus two events');

      final first = jsonDecode(lines[1]) as List<dynamic>;
      expect(first[0], 0.5);
      expect(first[1], 'o');
      expect(first[2], 'a');

      final second = jsonDecode(lines[2]) as List<dynamic>;
      expect(second[0], 1.5);
    });

    test('preserves escape sequences, which is the point of the format', () {
      recorder.record('\x1b[31mred\x1b[0m', Duration.zero);

      final event =
          jsonDecode(recorder.toAsciicast().split('\n')[1]) as List<dynamic>;

      expect(event[2], '\x1b[31mred\x1b[0m');
    });

    test('escapes control characters as valid JSON', () {
      recorder.record('line\r\n"quoted"\\', Duration.zero);

      // Every line must parse; a player reads this with a JSON parser.
      for (final line in recorder.toAsciicast().split('\n')) {
        if (line.isEmpty) continue;
        expect(() => jsonDecode(line), returnsNormally);
      }
    });

    test('carries the start time as unix seconds', () {
      recorder.record('x', Duration.zero);

      final header = jsonDecode(
        recorder.toAsciicast().split('\n').first,
      ) as Map<String, dynamic>;

      expect(
        header['timestamp'],
        DateTime.utc(2026, 9, 6, 12).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('an empty recording still produces a valid header', () {
      final lines = recorder
          .toAsciicast()
          .split('\n')
          .where((line) => line.isNotEmpty);

      expect(lines, hasLength(1));
      expect(() => jsonDecode(lines.first), returnsNormally);
    });
  });
}
