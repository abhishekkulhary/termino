/// Subsequence matching for the command palette.
///
/// The rule people expect from this kind of search is not "contains": typing
/// `bsv` should find "Build server", and `hst` should find "Hosts". So a
/// candidate matches when the query's characters appear in it in order, and
/// the score rewards the matches a human would call obvious — at the start of
/// a word, adjacent to the previous match, in the same case.
///
/// Pure, so it is tested directly rather than through a widget.
abstract final class FuzzyMatch {
  /// How well [query] matches [candidate], or null when it does not match.
  ///
  /// Higher is better. An empty query matches everything with score zero,
  /// which lets the palette show its full list before anything is typed.
  static int? score(String query, String candidate) {
    final needle = query.trim();
    if (needle.isEmpty) return 0;
    if (candidate.isEmpty) return null;

    final lowerNeedle = needle.toLowerCase();
    final lowerHay = candidate.toLowerCase();

    var total = 0;
    var hayIndex = 0;
    var previousMatch = -2;

    for (var i = 0; i < lowerNeedle.length; i++) {
      final wanted = lowerNeedle.codeUnitAt(i);
      if (wanted == _space) continue; // Spaces in a query mean "then".

      final found = _indexOf(lowerHay, wanted, hayIndex);
      if (found < 0) return null;

      var points = 1;
      if (found == previousMatch + 1) points += 5; // Runs read as intentional.
      if (found == 0) {
        points += 10;
      } else if (_isBoundary(lowerHay.codeUnitAt(found - 1))) {
        points += 8; // Start of a word.
      }
      if (candidate.codeUnitAt(found) == needle.codeUnitAt(i)) {
        points += 1; // Same case: a weak signal, but free.
      }

      total += points;
      previousMatch = found;
      hayIndex = found + 1;
    }

    // A short candidate that matched is a better answer than a long one that
    // happened to contain the same letters.
    return total - (candidate.length ~/ 12);
  }

  /// The best score of [query] against any of [candidates], or null.
  ///
  /// Lets an entry be findable by more than its title — a host by its
  /// hostname, a command by a word nobody put in its label.
  static int? scoreAny(String query, Iterable<String> candidates) {
    int? best;
    for (final candidate in candidates) {
      final result = score(query, candidate);
      if (result == null) continue;
      if (best == null || result > best) best = result;
    }
    return best;
  }

  static const _space = 0x20;

  static int _indexOf(String haystack, int unit, int from) {
    for (var i = from; i < haystack.length; i++) {
      if (haystack.codeUnitAt(i) == unit) return i;
    }
    return -1;
  }

  /// Whether [unit] is the sort of character a new word starts after.
  static bool _isBoundary(int unit) =>
      unit == _space ||
      unit == 0x2D || // -
      unit == 0x5F || // _
      unit == 0x2E || // .
      unit == 0x2F || // /
      unit == 0x3A || // :
      unit == 0x40; // @
}
