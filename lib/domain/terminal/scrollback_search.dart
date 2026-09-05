import 'package:meta/meta.dart';

/// One line of scrollback, as the search sees it.
typedef SearchLine = ({String text, bool wrapped});

/// Where a match sits in the buffer, in absolute cell coordinates.
@immutable
class SearchMatch {
  /// Creates a match spanning from [startX] on [startY] to [endX] on [endY].
  const new({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  /// Column of the first cell of the match.
  final int startX;

  /// Absolute row of the first cell.
  final int startY;

  /// Column of the last cell of the match, inclusive.
  final int endX;

  /// Absolute row of the last cell.
  final int endY;

  /// Whether the match runs across more than one buffer row.
  bool get spansRows => startY != endY;

  @override
  bool operator ==(Object other) =>
      other is SearchMatch &&
      other.startX == startX &&
      other.startY == startY &&
      other.endX == endX &&
      other.endY == endY;

  @override
  int get hashCode => Object.hash(startX, startY, endX, endY);

  @override
  String toString() => 'SearchMatch($startX,$startY → $endX,$endY)';
}

/// How to interpret a search query.
class SearchOptions {
  /// Creates a set of options.
  const new({
    this.caseSensitive = false,
    this.useRegex = false,
    this.wholeWord = false,
  });

  /// Whether case must match.
  final bool caseSensitive;

  /// Whether the query is a regular expression rather than literal text.
  final bool useRegex;

  /// Whether a match must be bounded by word boundaries.
  final bool wholeWord;
}

/// Thrown when a regular expression the user typed does not compile.
class InvalidSearchPattern implements Exception {
  /// Creates a failure describing [message].
  const new(this.message);

  /// A short explanation, safe to show.
  final String message;
}

/// Finds text in terminal scrollback.
///
/// `xterm` has no search of its own, so this is ours. It works on the flattened
/// text of the buffer rather than line by line, which is what makes two things
/// fall out for free: a match that runs across a **wrapped** line is found (the
/// user sees one line, and so should the search), and a regular expression can
/// span that wrap.
///
/// Coordinates come back in absolute buffer rows, ready to become the anchors
/// of a highlight.
abstract final class ScrollbackSearch {
  /// Finds every match of [query] in [lines], first to last.
  ///
  /// An empty query matches nothing rather than everything: a search box the
  /// user has not typed into yet should not light up the whole screen.
  ///
  /// Throws [InvalidSearchPattern] if [SearchOptions.useRegex] is set and the
  /// query does not compile — half-typed expressions are normal, and the UI
  /// shows the problem rather than the app failing.
  static List<SearchMatch> find(
    List<SearchLine> lines,
    String query, {
    SearchOptions options = const SearchOptions(),
  }) {
    if (query.isEmpty || lines.isEmpty) return const [];

    final (flat, positions) = _flatten(lines);
    final pattern = _compile(query, options);

    final matches = <SearchMatch>[];
    for (final match in pattern.allMatches(flat)) {
      // A zero-width match — `a*` against an empty run — would otherwise
      // produce a highlight with nothing in it, once per character.
      if (match.end == match.start) continue;

      final start = positions[match.start];
      final end = positions[match.end - 1];
      if (start == null || end == null) continue;

      matches.add(
        SearchMatch(startX: start.x, startY: start.y, endX: end.x, endY: end.y),
      );
    }
    return matches;
  }

  /// Builds one string for the whole buffer, plus a map from each character
  /// back to the cell it came from.
  ///
  /// Wrapped lines are joined with nothing between them, because they are one
  /// logical line; unwrapped ones are separated by a newline, which belongs to
  /// no cell and so blocks a match from running across unrelated lines.
  static (String, List<({int x, int y})?>) _flatten(List<SearchLine> lines) {
    final buffer = StringBuffer();
    final positions = <({int x, int y})?>[];

    for (var y = 0; y < lines.length; y++) {
      final text = lines[y].text;
      for (var x = 0; x < text.length; x++) {
        buffer.write(text[x]);
        positions.add((x: x, y: y));
      }

      final continues = y + 1 < lines.length && lines[y + 1].wrapped;
      if (!continues && y + 1 < lines.length) {
        buffer.write('\n');
        positions.add(null);
      }
    }

    return (buffer.toString(), positions);
  }

  static RegExp _compile(String query, SearchOptions options) {
    var source = options.useRegex ? query : RegExp.escape(query);
    if (options.wholeWord) source = '\\b(?:$source)\\b';

    try {
      return RegExp(
        source,
        caseSensitive: options.caseSensitive,
        multiLine: true,
      );
    } on FormatException catch (error) {
      throw InvalidSearchPattern(
        error.message.isEmpty ? 'Invalid expression' : error.message,
      );
    }
  }
}
