import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/hosts/presentation/last_connected_label.dart';

void main() {
  final now = DateTime.utc(2026, 9, 6, 12);
  String at(Duration ago, {bool long = true}) =>
      lastConnectedLabel(now.subtract(ago), long: long, now: now);

  group('long form', () {
    test('a host never reached says so', () {
      expect(lastConnectedLabel(null, long: true), 'Never connected');
    });

    test('rounds the last minute to "just now"', () {
      expect(at(const Duration(seconds: 5)), 'Connected just now');
      expect(at(const Duration(seconds: 44)), 'Connected just now');
    });

    test('counts minutes, hours, days, months and years', () {
      expect(at(const Duration(minutes: 7)), 'Connected 7 minutes ago');
      expect(at(const Duration(hours: 5)), 'Connected 5 hours ago');
      expect(at(const Duration(days: 3)), 'Connected 3 days ago');
      expect(at(const Duration(days: 70)), 'Connected 2 months ago');
      expect(at(const Duration(days: 800)), 'Connected 2 years ago');
    });

    test('says one, not 1s', () {
      expect(at(const Duration(minutes: 1)), 'Connected 1 minute ago');
      expect(at(const Duration(hours: 1)), 'Connected 1 hour ago');
      expect(at(const Duration(days: 1)), 'Connected 1 day ago');
      expect(at(const Duration(days: 400)), 'Connected 1 year ago');
    });
  });

  group('short form, for a narrow row', () {
    test('abbreviates and still pluralises', () {
      expect(at(const Duration(minutes: 7), long: false), '7 mins ago');
      expect(at(const Duration(hours: 5), long: false), '5 hrs ago');
      expect(at(const Duration(days: 3), long: false), '3 days ago');
      expect(at(const Duration(days: 1), long: false), '1 day ago');
    });

    test('a host never reached still says so in full', () {
      // "never" abbreviated is not shorter and is not clearer.
      expect(lastConnectedLabel(null, long: false), 'Never connected');
    });
  });

  test('a timestamp in the future does not read as a prediction', () {
    // A restored backup, a timezone change, or an NTP step can put the stored
    // time ahead of the clock. "Connected in 3 hours" would be nonsense.
    final future = now.add(const Duration(hours: 3));
    expect(
      lastConnectedLabel(future, long: true, now: now),
      'Connected just now',
    );
  });

  test('boundaries fall on the larger unit', () {
    expect(at(const Duration(minutes: 59)), 'Connected 59 minutes ago');
    expect(at(const Duration(minutes: 60)), 'Connected 1 hour ago');
    expect(at(const Duration(hours: 23)), 'Connected 23 hours ago');
    expect(at(const Duration(hours: 24)), 'Connected 1 day ago');
  });
}
