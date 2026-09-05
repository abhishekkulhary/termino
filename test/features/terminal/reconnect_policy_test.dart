import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/reconnect_policy.dart';

/// A generator with no randomness, so jitter is testable.
class FixedRandom implements Random {
  new(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('delays', () {
    const policy = ReconnectPolicy(jitter: 0);

    test('the first attempt waits the initial delay', () {
      expect(policy.delayFor(1), const Duration(seconds: 1));
    });

    test('each attempt doubles', () {
      expect(policy.delayFor(2), const Duration(seconds: 2));
      expect(policy.delayFor(3), const Duration(seconds: 4));
      expect(policy.delayFor(4), const Duration(seconds: 8));
    });

    test('growth is capped', () {
      expect(policy.delayFor(20), const Duration(seconds: 30));
    });

    test('attempt zero waits not at all', () {
      expect(policy.delayFor(0), Duration.zero);
    });

    test('a custom multiplier is honoured', () {
      const gentle = ReconnectPolicy(multiplier: 1.5, jitter: 0);

      expect(gentle.delayFor(1), const Duration(seconds: 1));
      expect(gentle.delayFor(2), const Duration(milliseconds: 1500));
    });
  });

  group('jitter', () {
    const policy = ReconnectPolicy();

    test('shortens the delay rather than lengthening it', () {
      // Without this, a delay could exceed the cap the caller asked for.
      final full = policy.delayFor(3, random: FixedRandom(1));
      final none = policy.delayFor(3, random: FixedRandom(0));

      expect(none, const Duration(seconds: 4));
      expect(full, const Duration(seconds: 3));
      expect(full, lessThan(none));
    });

    test('stays inside the cap at every attempt', () {
      for (var attempt = 1; attempt <= 20; attempt++) {
        for (final value in [0.0, 0.5, 1.0]) {
          final delay = policy.delayFor(attempt, random: FixedRandom(value));
          expect(delay, lessThanOrEqualTo(policy.maxDelay));
          expect(delay, greaterThanOrEqualTo(Duration.zero));
        }
      }
    });

    test('real randomness stays inside the expected band', () {
      for (var i = 0; i < 100; i++) {
        final delay = policy.delayFor(3);
        expect(delay.inMilliseconds, lessThanOrEqualTo(4000));
        expect(delay.inMilliseconds, greaterThanOrEqualTo(3000));
      }
    });
  });

  group('attempt limit', () {
    test('retries up to the limit and then stops', () {
      const policy = ReconnectPolicy(maxAttempts: 3);

      expect(policy.shouldRetry(1), isTrue);
      expect(policy.shouldRetry(3), isTrue);
      expect(policy.shouldRetry(4), isFalse);
    });

    test('zero attempts disables reconnection', () {
      const policy = ReconnectPolicy(maxAttempts: 0);

      expect(policy.shouldRetry(1), isFalse);
    });
  });
}
