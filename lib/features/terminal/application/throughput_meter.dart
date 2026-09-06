/// Measures how fast bytes are arriving from a backend.
///
/// A terminal that is doing something and a terminal that has hung look
/// identical, and the difference matters most exactly when a user is worried —
/// a build that stopped, a `tail -f` that went quiet, a transfer that stalled.
/// A rate readout answers that without them typing anything.
///
/// Deliberately clock-injectable and timer-free. The rate is computed when
/// asked rather than pushed on a timer, so the whole thing is a pure function
/// of what arrived and when, and the widget decides how often to look.
class ThroughputMeter {
  /// Creates a meter averaging over [window].
  ///
  /// One second is short enough to feel live and long enough not to flicker
  /// between zero and a spike as chunks arrive in bursts.
  new({this.window = const Duration(seconds: 1)});

  /// How far back the rate is averaged over.
  final Duration window;

  /// Every byte seen since the session opened.
  int get totalBytes => _total;

  int _total = 0;

  /// Buckets of (end of bucket, bytes), oldest first. Bucketing rather than
  /// keeping every chunk keeps this bounded no matter how chatty the stream:
  /// `yes` delivers thousands of chunks a second and would otherwise grow an
  /// unbounded list purely to display a number.
  final _buckets = <(DateTime, int)>[];

  static const _bucketSize = Duration(milliseconds: 100);

  /// Records [bytes] arriving now, or at [at] in tests.
  void add(int bytes, {DateTime? at}) {
    if (bytes <= 0) return;
    final when = at ?? DateTime.now();
    _total += bytes;

    final bucketEnd = _bucketEndFor(when);
    if (_buckets.isNotEmpty && _buckets.last.$1 == bucketEnd) {
      _buckets[_buckets.length - 1] = (bucketEnd, _buckets.last.$2 + bytes);
    } else {
      _buckets.add((bucketEnd, bytes));
    }
    _prune(when);
  }

  /// Bytes per second over the last [window], as of now or [now] in tests.
  int rate({DateTime? now}) {
    final when = now ?? DateTime.now();
    _prune(when);
    if (_buckets.isEmpty) return 0;

    final total = _buckets.fold(0, (sum, bucket) => sum + bucket.$2);
    final seconds = window.inMicroseconds / Duration.microsecondsPerSecond;
    return (total / seconds).round();
  }

  /// Whether anything has arrived within [window].
  bool isActive({DateTime? now}) => rate(now: now) > 0;

  void _prune(DateTime now) {
    final cutoff = now.subtract(window);
    _buckets.removeWhere((bucket) => !bucket.$1.isAfter(cutoff));
  }

  DateTime _bucketEndFor(DateTime when) {
    final ms = when.millisecondsSinceEpoch;
    final size = _bucketSize.inMilliseconds;
    return DateTime.fromMillisecondsSinceEpoch(
      (ms ~/ size) * size + size,
      isUtc: when.isUtc,
    );
  }
}

/// Formats a byte count the way a transfer readout should.
///
/// Binary units, because that is what every other tool in a terminal reports,
/// and one decimal place only below 10 so the number stops jittering as soon
/// as it is large enough for the extra digit to be noise.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';

  const units = ['KiB', 'MiB', 'GiB', 'TiB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value < 10 ? 1 : 0;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// The same, per second.
String formatRate(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';
