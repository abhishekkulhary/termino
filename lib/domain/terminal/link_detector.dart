import 'package:meta/meta.dart';

/// A URL found in a line of terminal output.
@immutable
class DetectedLink {
  /// Creates a link spanning [start] to [end], inclusive.
  const new({required this.url, required this.start, required this.end});

  /// The URL as written.
  final String url;

  /// Column of the first character.
  final int start;

  /// Column of the last character, inclusive.
  final int end;

  /// Whether [column] falls inside this link.
  bool contains(int column) => column >= start && column <= end;

  @override
  bool operator ==(Object other) =>
      other is DetectedLink &&
      other.url == url &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(url, start, end);
}

/// Finds URLs in terminal output so they can be opened.
///
/// This is the pragmatic half of the OSC 8 decision recorded in DECISIONS.md:
/// `xterm` has no per-cell URL attribution, so a real hyperlink — text with a
/// hidden target — cannot be rendered. What can be done, and covers the common
/// case of a URL printed by `curl`, `npm` or `git`, is to recognise one in the
/// visible text.
abstract final class LinkDetector {
  /// Schemes worth making clickable.
  ///
  /// Deliberately short. `file:` is excluded because a remote session printing
  /// one would open a path on the *local* machine, which is misleading at
  /// best; anything that could execute is excluded outright.
  static const schemes = {'http', 'https', 'ftp', 'ssh', 'mailto'};

  static final _pattern = RegExp(
    r'\b(?:https?|ftp|ssh|mailto):(?://)?[^\s<>"'
    "'"
    r'`\\^{}|]+',
    caseSensitive: false,
  );

  /// Every URL in [line].
  static List<DetectedLink> find(String line) {
    final links = <DetectedLink>[];

    for (final match in _pattern.allMatches(line)) {
      var url = match.group(0)!;
      var end = match.end - 1;

      // Trailing punctuation is almost always the sentence, not the URL:
      // "see https://example.com." should not include the full stop. Brackets
      // are only trimmed when unbalanced, so a Wikipedia-style URL survives.
      while (url.isNotEmpty && _isTrailingPunctuation(url)) {
        url = url.substring(0, url.length - 1);
        end--;
      }

      if (url.isEmpty) continue;
      final scheme = url.split(':').first.toLowerCase();
      if (!schemes.contains(scheme)) continue;
      // A bare scheme with nothing after it is not a link. The separator may
      // be `scheme:` or `scheme://`, and both must be followed by something.
      var remainder = url.substring(scheme.length + 1);
      if (remainder.startsWith('//')) remainder = remainder.substring(2);
      if (remainder.isEmpty) continue;

      links.add(DetectedLink(url: url, start: match.start, end: end));
    }

    return links;
  }

  /// The link at [column] in [line], if there is one.
  static DetectedLink? at(String line, int column) {
    for (final link in find(line)) {
      if (link.contains(column)) return link;
    }
    return null;
  }

  static bool _isTrailingPunctuation(String url) {
    final last = url[url.length - 1];
    if ('.,;:!?'.contains(last)) return true;
    if (last == ')') return _unbalanced(url, '(', ')');
    if (last == ']') return _unbalanced(url, '[', ']');
    if (last == '}') return _unbalanced(url, '{', '}');
    return false;
  }

  static bool _unbalanced(String url, String open, String close) {
    final opens = open.allMatches(url).length;
    final closes = close.allMatches(url).length;
    return closes > opens;
  }
}
