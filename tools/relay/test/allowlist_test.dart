import 'package:termino_relay/allowlist.dart';
import 'package:test/test.dart';

void main() {
  group('parsing', () {
    test('a bare host allows port 22 only', () {
      final allowlist = Allowlist.parse(['build-01.example.com']);

      expect(allowlist.allows('build-01.example.com', 22), isTrue);
      expect(
        allowlist.allows('build-01.example.com', 2222),
        isFalse,
        reason:
            'a rule written without a port means the SSH server, not '
            'every port on the machine',
      );
    });

    test('an explicit port is honoured', () {
      final allowlist = Allowlist.parse(['build-01:2222']);

      expect(allowlist.allows('build-01', 2222), isTrue);
      expect(allowlist.allows('build-01', 22), isFalse);
    });

    test('several entries are all allowed', () {
      final allowlist = Allowlist.parse([
        'a.example.com',
        'b.example.com:2222',
      ]);

      expect(allowlist.allows('a.example.com', 22), isTrue);
      expect(allowlist.allows('b.example.com', 2222), isTrue);
    });

    test('blank entries are ignored', () {
      expect(Allowlist.parse(['', '   ']).isEmpty, isTrue);
    });

    test('a malformed port is refused rather than ignored', () {
      // Silently dropping a bad rule would leave the operator believing a
      // host was allowed when it was not — or worse, the reverse.
      expect(
        () => Allowlist.parse(['host:not-a-port']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Allowlist.parse(['host:70000']),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('matching', () {
    test('is case-insensitive', () {
      final allowlist = Allowlist.parse(['Build-01.Example.COM']);

      expect(allowlist.allows('build-01.example.com', 22), isTrue);
    });

    test('an unlisted host is refused', () {
      final allowlist = Allowlist.parse(['a.example.com']);

      expect(allowlist.allows('b.example.com', 22), isFalse);
      expect(allowlist.allows('example.com', 22), isFalse);
    });

    test('a wildcard covers one subdomain level', () {
      final allowlist = Allowlist.parse(['*.example.com']);

      expect(allowlist.allows('build.example.com', 22), isTrue);
      expect(
        allowlist.allows('a.b.example.com', 22),
        isFalse,
        reason: 'a wildcard that spans dots stops meaning anything',
      );
      expect(
        allowlist.allows('example.com', 22),
        isFalse,
        reason: 'the apex is not a subdomain of itself',
      );
    });

    test('a wildcard cannot be defeated by a suffix trick', () {
      final allowlist = Allowlist.parse(['*.example.com']);

      // `notexample.com` ends with `example.com` as a string but is a
      // different domain entirely.
      expect(allowlist.allows('evil.notexample.com', 22), isFalse);
      expect(allowlist.allows('exampleXcom', 22), isFalse);
    });

    test('an empty allowlist allows nothing', () {
      expect(const Allowlist([]).allows('anything', 22), isFalse);
      expect(const Allowlist([]).isEmpty, isTrue);
    });
  });
}
