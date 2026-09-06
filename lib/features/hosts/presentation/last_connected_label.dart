/// How a host card says when it was last reached.
///
/// Its own file because relative time is all edge cases — plurals, boundaries,
/// and a clock that has moved backwards — and those are worth testing without
/// a widget in the way.
library;

/// "Connected 3 days ago", or the short form where the row is narrow.
///
/// A host that has never been reached says so rather than showing a blank: the
/// absence is information, and it is the one row where "connect" is a guess.
String lastConnectedLabel(DateTime? at, {required bool long, DateTime? now}) {
  if (at == null) return 'Never connected';

  final elapsed = (now ?? DateTime.now()).difference(at);

  // A clock that has moved backwards — a timezone change, an NTP step, a
  // restored backup — must not produce "connected in 3 hours".
  if (elapsed.isNegative || elapsed.inSeconds < 45) {
    return long ? 'Connected just now' : 'just now';
  }

  String phrase(int count, String unit, String short) {
    final plural = count == 1 ? '' : 's';
    return long
        ? 'Connected $count $unit$plural ago'
        : '$count $short$plural ago';
  }

  if (elapsed.inMinutes < 60) return phrase(elapsed.inMinutes, 'minute', 'min');
  if (elapsed.inHours < 24) return phrase(elapsed.inHours, 'hour', 'hr');
  if (elapsed.inDays < 30) return phrase(elapsed.inDays, 'day', 'day');
  if (elapsed.inDays < 365) return phrase(elapsed.inDays ~/ 30, 'month', 'mo');
  return phrase(elapsed.inDays ~/ 365, 'year', 'yr');
}
