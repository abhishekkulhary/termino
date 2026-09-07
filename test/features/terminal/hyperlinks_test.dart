import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/hyperlinks.dart';
import 'package:xterm/xterm.dart';

/// OSC 8 is the sequence that says "these characters point at *this*", and the
/// characters need not resemble the destination at all. That makes correct
/// attribution a safety property, not only a feature: the app has to know
/// exactly which cells a program claimed, and exactly what it claimed for them.
void main() {
  late Terminal terminal;
  late TerminalHyperlinks links;

  setUp(() {
    links = TerminalHyperlinks();
    terminal = Terminal(maxLines: 200)
      ..onPrivateOSC = (code, args) => links.handleOsc(code, args, terminal);
    terminal.resize(20, 6);
  });

  /// Writes an OSC 8 link with [text] as its visible run.
  String link(String url, String text) => '\x1b]8;;$url\x07$text\x1b]8;;\x07';

  test('attributes exactly the cells the program marked', () {
    terminal.write('see ${link('https://example.com/a', 'this link')} end');

    // "see " is columns 0-3; "this link" is 4-12; " end" follows.
    expect(links.urlAt(terminal, 0, 3), isNull);
    expect(links.urlAt(terminal, 0, 4), 'https://example.com/a');
    expect(links.urlAt(terminal, 0, 12), 'https://example.com/a');
    expect(links.urlAt(terminal, 0, 13), isNull);
  });

  test('the visible text need not resemble the destination', () {
    // The whole point of OSC 8, and the whole reason a link is confirmed
    // before it opens.
    terminal.write(link('https://elsewhere.example/x', 'docs'));

    expect(links.urlAt(terminal, 0, 0), 'https://elsewhere.example/x');
  });

  test('follows a link that wraps across the edge of the screen', () {
    terminal.write('ab${link('https://example.com/a', '0' * 40)}');

    expect(links.urlAt(terminal, 0, 19), 'https://example.com/a');
    expect(links.urlAt(terminal, 1, 0), 'https://example.com/a');
    expect(links.urlAt(terminal, 1, 19), 'https://example.com/a');
    expect(links.urlAt(terminal, 2, 1), 'https://example.com/a');
    expect(links.urlAt(terminal, 2, 2), isNull);
  });

  test('stays on its text when the screen scrolls', () {
    // The reason spans hang off the line objects rather than off row numbers.
    terminal.write('${link('https://example.com/a', 'target')}\r\n');
    for (var i = 0; i < 4; i++) {
      terminal.write('filler\r\n');
    }

    expect(links.urlAt(terminal, 0, 0), 'https://example.com/a');
  });

  test('a link is dropped when its line falls out of the scrollback', () {
    final small = Terminal(maxLines: 40);
    final tracker = TerminalHyperlinks();
    small
      ..onPrivateOSC = ((code, args) => tracker.handleOsc(code, args, small))
      ..resize(20, 4)
      ..write('${link('https://example.com/a', 'target')}\r\n');
    for (var i = 0; i < 80; i++) {
      small.write('filler $i\r\n');
    }

    for (var line = 0; line < small.buffer.height; line++) {
      expect(tracker.urlAt(small, line, 0), isNull);
    }
  });

  test('two links on one line keep their own destinations', () {
    terminal.write(
      '${link('https://a.example/1', 'one')} '
      '${link('https://b.example/2', 'two')}',
    );

    expect(links.urlAt(terminal, 0, 0), 'https://a.example/1');
    expect(links.urlAt(terminal, 0, 3), isNull);
    expect(links.urlAt(terminal, 0, 4), 'https://b.example/2');
  });

  test('a link left open marks nothing', () {
    // An unterminated OSC 8 is malformed. Marking everything after it would
    // turn the rest of the session into one enormous link.
    terminal.write('\x1b]8;;https://example.com/a\x07never closed\r\nmore');

    expect(links.urlAt(terminal, 0, 0), isNull);
    expect(links.urlAt(terminal, 1, 0), isNull);
  });

  group('a scheme the app will not open', () {
    // The destination comes from a remote machine, and with OSC 8 nothing on
    // screen has to hint at what it is. The allow-list is the only thing
    // standing between a printed word and a local action.
    for (final url in [
      'file:///etc/passwd',
      'javascript:alert(1)',
      'vscode://ms-vscode.remote/x',
      'data:text/html,<script>',
    ]) {
      test('is never attributed: $url', () {
        terminal.write(link(url, 'harmless looking text'));
        expect(links.urlAt(terminal, 0, 0), isNull);
      });
    }

    test('but an ordinary https link is', () {
      terminal.write(link('https://example.com/', 'text'));
      expect(links.urlAt(terminal, 0, 0), 'https://example.com/');
    });
  });

  test('an OSC that is not 8 is left alone', () {
    terminal.write('\x1b]0;a title\x07hello');
    expect(links.urlAt(terminal, 0, 0), isNull);
  });

  test('reports its spans for painting', () {
    terminal.write('ab${link('https://example.com/a', 'link')}cd');

    final spans = links.spansOn(terminal, 0);
    expect(spans, hasLength(1));
    expect(spans.single.start, 2);
    expect(spans.single.end, 6);
  });

  group('what a tap should do', () {
    // The gesture itself belongs to xterm and cannot be driven from a widget
    // test — a bare `TerminalView` does not report a tap under the test
    // binding, which was checked directly before this was written this way.
    // The decision is the part with consequences, and it is all here.

    test('a declared link is confirmed, never opened on the spot', () {
      terminal.write(link('https://elsewhere.example/x', 'docs'));

      final action = links.actionAt(terminal, 0, 1);

      expect(action, isA<ConfirmLink>());
      expect(
        (action as ConfirmLink).uri.toString(),
        'https://elsewhere.example/x',
        reason: 'the destination, not the word on screen',
      );
    });

    test('text that is itself a URL opens without a question', () {
      // Nothing to disagree about: the words on screen are the destination.
      terminal
        ..resize(60, 6)
        ..write('see https://example.com/plain here');

      final action = links.actionAt(terminal, 0, 6);

      expect(action, isA<OpenLink>());
      expect((action as OpenLink).uri.toString(), 'https://example.com/plain');
    });

    test('a declared link with a refused scheme does nothing at all', () {
      terminal.write(link('file:///etc/passwd', 'harmless looking'));

      expect(links.actionAt(terminal, 0, 1), isA<NoLink>());
    });

    test('ordinary text does nothing', () {
      terminal.write(r'$ ls -la');

      expect(links.actionAt(terminal, 0, 2), isA<NoLink>());
    });

    test('a tap off the end of the buffer does nothing', () {
      terminal.write('hello');

      expect(links.actionAt(terminal, 9999, 0), isA<NoLink>());
      expect(links.actionAt(terminal, -1, 0), isA<NoLink>());
    });

    test('the declared link wins over the text under it', () {
      // A program can print one URL and point it at another. The declaration
      // is what the cells mean, and it is the one that gets confirmed.
      terminal.write(link('https://real.example/', 'https://decoy.example/'));

      final action = links.actionAt(terminal, 0, 3);

      expect(action, isA<ConfirmLink>());
      expect((action as ConfirmLink).uri.toString(), 'https://real.example/');
    });
  });
}
