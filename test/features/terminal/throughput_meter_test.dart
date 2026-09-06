import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/throughput_meter.dart';

void main() {
  final start = DateTime.utc(2026, 9, 6, 12);

  group('rate', () {
    test('is zero before anything arrives', () {
      expect(ThroughputMeter().rate(now: start), 0);
    });

    test('reports what arrived over the window', () {
      final meter = ThroughputMeter()
        ..add(1000, at: start)
        ..add(1000, at: start.add(const Duration(milliseconds: 500)));

      expect(
        meter.rate(now: start.add(const Duration(milliseconds: 900))),
        2000,
      );
    });

    test('forgets what has fallen out of the window', () {
      final meter = ThroughputMeter()..add(5000, at: start);

      expect(
        meter.rate(now: start.add(const Duration(milliseconds: 500))),
        5000,
      );
      expect(
        meter.rate(now: start.add(const Duration(seconds: 3))),
        0,
        reason: 'a stream that went quiet should read as quiet',
      );
    });

    test('a longer window averages over more time', () {
      final meter = ThroughputMeter(window: const Duration(seconds: 4))
        ..add(4000, at: start);

      expect(
        meter.rate(now: start.add(const Duration(seconds: 2))),
        1000,
        reason: '4000 bytes spread over a four second window',
      );
    });

    test('a burst of tiny chunks is counted, not dropped', () {
      // `yes` delivers thousands of small chunks a second; the meter must not
      // grow a list per chunk, and must not lose them either.
      final meter = ThroughputMeter();
      for (var i = 0; i < 5000; i++) {
        meter.add(10, at: start.add(Duration(microseconds: i * 100)));
      }
      expect(meter.totalBytes, 50000);
      expect(
        meter.rate(now: start.add(const Duration(milliseconds: 600))),
        greaterThan(0),
      );
    });
  });

  group('totalBytes', () {
    test('keeps counting past the window', () {
      final meter = ThroughputMeter()
        ..add(100, at: start)
        ..add(100, at: start.add(const Duration(minutes: 5)));

      expect(meter.totalBytes, 200);
      expect(meter.rate(now: start.add(const Duration(minutes: 10))), 0);
    });

    test('ignores empty and negative chunks', () {
      final meter = ThroughputMeter()
        ..add(0, at: start)
        ..add(-5, at: start);
      expect(meter.totalBytes, 0);
    });
  });

  group('isActive', () {
    test('is true while bytes are arriving and false once they stop', () {
      final meter = ThroughputMeter()..add(1, at: start);
      expect(
        meter.isActive(now: start.add(const Duration(milliseconds: 200))),
        isTrue,
      );
      expect(
        meter.isActive(now: start.add(const Duration(seconds: 5))),
        isFalse,
      );
    });
  });

  group('formatBytes', () {
    test('uses binary units, as every other terminal tool does', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KiB');
      expect(formatBytes(1536), '1.5 KiB');
      expect(formatBytes(1024 * 1024), '1.0 MiB');
      expect(formatBytes(1024 * 1024 * 1024), '1.0 GiB');
    });

    test('drops the decimal once it is only noise', () {
      expect(formatBytes(1024 * 9), '9.0 KiB');
      expect(formatBytes(1024 * 42), '42 KiB');
    });

    test('a rate is the same number per second', () {
      expect(formatRate(2048), '2.0 KiB/s');
    });
  });
}
