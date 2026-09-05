import 'dart:math';

/// How long to wait before each reconnection attempt.
///
/// Exponential with jitter. The exponential part keeps a server that is down
/// from being hammered; the jitter matters more than it looks — without it,
/// every client that dropped at the same moment comes back at the same moment,
/// which is how a recovering server gets knocked over again.
class ReconnectPolicy {
  /// Creates a policy.
  const new({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.multiplier = 2.0,
    this.maxAttempts = 8,
    this.jitter = 0.25,
  });

  /// The wait before the first retry.
  final Duration initialDelay;

  /// The ceiling on the wait.
  final Duration maxDelay;

  /// How much each successive delay grows.
  final double multiplier;

  /// How many attempts before giving up. Zero means never retry.
  final int maxAttempts;

  /// The fraction of the delay that is randomised, from 0 to 1.
  final double jitter;

  /// Whether an [attempt] (one-based) should be made at all.
  bool shouldRetry(int attempt) => attempt <= maxAttempts;

  /// The delay before [attempt], which is one-based.
  ///
  /// [random] is injectable so the jitter can be tested.
  Duration delayFor(int attempt, {Random? random}) {
    if (attempt < 1) return Duration.zero;

    final growth = pow(multiplier, attempt - 1).toDouble();
    final base = initialDelay.inMilliseconds * growth;
    final capped = min(base, maxDelay.inMilliseconds.toDouble());

    if (jitter <= 0) return Duration(milliseconds: capped.round());

    // Jitter is applied downwards only, so a delay never exceeds the cap the
    // caller asked for.
    final spread = capped * jitter;
    final value = capped - (random ?? Random()).nextDouble() * spread;
    return Duration(milliseconds: value.round());
  }
}
