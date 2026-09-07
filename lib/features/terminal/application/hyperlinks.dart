import 'package:termino/domain/terminal/link_detector.dart';
import 'package:xterm/xterm.dart';

/// What tapping a cell should do.
///
/// A decision, separated from the gesture that triggers it, because the gesture
/// belongs to xterm and cannot be driven from a widget test — a bare
/// `TerminalView` does not report a tap under the test binding, which was
/// checked directly. The choice between opening, asking, and doing nothing is
/// the part with consequences, and it is testable here.
sealed class LinkAction {
  const new();
}

/// There is no link under that cell.
class NoLink extends LinkAction {
  /// Creates the empty action.
  const new();
}

/// Text that reads as a URL. The words on screen *are* the destination, so
/// there is nothing to disagree about and nothing to confirm.
class OpenLink extends LinkAction {
  /// Creates an action opening [uri].
  const new(this.uri);

  /// Where it goes.
  final Uri uri;
}

/// A link declared with OSC 8, whose visible text need not resemble where it
/// points. Shown to the user before anything is opened.
class ConfirmLink extends LinkAction {
  /// Creates an action proposing [uri].
  const new(this.uri);

  /// Where it actually goes.
  final Uri uri;
}

/// A run of cells on one line that carry a URL declared with OSC 8.
class LinkSpan {
  /// Creates a span covering `[start, end)` on one line.
  const new({required this.start, required this.end, required this.url});

  /// The first column, inclusive.
  final int start;

  /// One past the last column.
  final int end;

  /// Where the program says these cells point.
  final String url;

  /// Whether [column] is inside this span.
  bool contains(int column) => column >= start && column < end;
}

/// Tracks OSC 8 hyperlinks and which cells they cover.
///
/// OSC 8 is how a program says "these characters are a link to *this*, whatever
/// they happen to read as" — `ls --hyperlink`, `gcc`'s diagnostic URLs, `gh`.
/// It is the difference between a terminal that can link the word "docs" and
/// one that can only link text that already looks like a URL.
///
/// ## Why this is possible without changing xterm
///
/// xterm.dart has no per-cell URL attribution and its escape handler exposes
/// only `setTitle` and `unknownOSC`, which is why v1 shipped regex
/// linkification instead. But `Terminal.onPrivateOSC` fires **synchronously
/// while the sequence is being parsed**, so at that moment the buffer's cursor
/// is exactly where the link begins and, later, exactly where it ends. That is
/// enough to attribute the cells between them without touching the emulator.
///
/// Spans hang off the `BufferLine` objects themselves, in an [Expando]. A line
/// object travels with its content as the screen scrolls, so a link stays on
/// its text with no bookkeeping; and when a line is trimmed off the top of the
/// scrollback the whole entry becomes garbage with it.
///
/// ## What it does not cover
///
/// A line that is erased and rewritten in place — which a full-screen program
/// on the alternate buffer does constantly — keeps its `BufferLine` object, so
/// a span recorded before the erase can outlive the text it described. The
/// consequence is a stray underline, never a wrong destination: the URL is
/// still whatever the program declared for those cells, and every link is
/// confirmed before it opens.
class TerminalHyperlinks {
  final _spans = Expando<List<LinkSpan>>('osc8');

  BufferLine? _openLine;
  int _openColumn = 0;
  String? _openUrl;

  /// Handles one OSC sequence. Anything but OSC 8 is ignored.
  ///
  /// The shape is `OSC 8 ; params ; URI ST`: a URI opens a link, an empty one
  /// closes it.
  void handleOsc(String code, List<String> args, Terminal terminal) {
    if (code != '8') return;

    // params come first, then the URI. A sequence with neither is a close.
    final url = args.length >= 2 ? args[1] : '';
    if (url.isEmpty) {
      _close(terminal);
      return;
    }

    // A link opened while one is already open closes the first: that is what
    // `ls --hyperlink` emits between entries when it omits the explicit close.
    _close(terminal);

    if (!_isOpenable(url)) return;
    _openLine = terminal.buffer.currentLine;
    _openColumn = terminal.buffer.cursorX;
    _openUrl = url;
  }

  /// The URL covering [column] on the line at [line], or null.
  String? urlAt(Terminal terminal, int line, int column) {
    final buffer = terminal.buffer;
    if (line < 0 || line >= buffer.height) return null;

    final spans = _spans[buffer.lines[line]];
    if (spans == null) return null;

    for (final span in spans) {
      if (span.contains(column)) return span.url;
    }
    return null;
  }

  /// What tapping the cell at [line], [column] should do.
  ///
  /// A declared link always asks. That is not caution for its own sake: OSC 8
  /// separates the words from the destination, so the only way a person can
  /// judge where a link goes is to be shown.
  LinkAction actionAt(Terminal terminal, int line, int column) {
    final buffer = terminal.buffer;
    if (line < 0 || line >= buffer.height) return const NoLink();

    final declared = urlAt(terminal, line, column);
    if (declared != null) {
      final uri = Uri.tryParse(declared);
      // Re-checked at the point of action, not trusted from where it was
      // recorded: this is where output from a remote machine becomes an
      // action on the local one.
      if (uri == null || !LinkDetector.schemes.contains(uri.scheme)) {
        return const NoLink();
      }
      return ConfirmLink(uri);
    }

    final found = LinkDetector.at(buffer.lines[line].getText(), column);
    if (found == null) return const NoLink();

    final uri = Uri.tryParse(found.url);
    if (uri == null || !LinkDetector.schemes.contains(uri.scheme)) {
      return const NoLink();
    }
    return OpenLink(uri);
  }

  /// Every span on the line at [line], for painting.
  List<LinkSpan> spansOn(Terminal terminal, int line) {
    final buffer = terminal.buffer;
    if (line < 0 || line >= buffer.height) return const [];
    return _spans[buffer.lines[line]] ?? const [];
  }

  /// Forgets an unterminated link. Used when the terminal is reset.
  void clearOpen() {
    _openLine = null;
    _openUrl = null;
  }

  void _close(Terminal terminal) {
    final startLine = _openLine;
    final url = _openUrl;
    clearOpen();
    if (startLine == null || url == null) return;

    // The line the link started on may have scrolled off the top entirely
    // while the link's own text was being written.
    if (!startLine.attached) return;

    final buffer = terminal.buffer;
    final startIndex = startLine.index;
    final endIndex = buffer.absoluteCursorY;
    final endColumn = buffer.cursorX;
    if (endIndex < startIndex) return;

    for (
      var index = startIndex;
      index <= endIndex && index < buffer.height;
      index++
    ) {
      final start = index == startIndex ? _openColumn : 0;
      final end = index == endIndex ? endColumn : buffer.viewWidth;
      if (end <= start) continue;

      final line = buffer.lines[index];
      final existing = _spans[line] ?? const <LinkSpan>[];
      _spans[line] = [
        // A span written over is replaced rather than layered: the newer
        // declaration is the one the program means.
        for (final span in existing)
          if (span.end <= start || span.start >= end) span,
        LinkSpan(start: start, end: end, url: url),
      ];
    }
  }

  /// Whether a URL a remote program declared may be opened at all.
  ///
  /// The same scheme allow-list the visible-text detector uses. OSC 8 makes
  /// this matter more, not less: the text on screen need not resemble the
  /// destination, so `file://`, `javascript:` and the rest must be refused
  /// here rather than judged by eye.
  static bool _isOpenable(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && LinkDetector.schemes.contains(uri.scheme);
  }
}
