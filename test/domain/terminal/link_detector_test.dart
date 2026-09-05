import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/terminal/link_detector.dart';

void main() {
  group('find', () {
    test('finds a plain URL and reports its columns', () {
      const line = 'see https://example.com now';

      final links = LinkDetector.find(line);

      expect(links, hasLength(1));
      expect(links.single.url, 'https://example.com');
      expect(links.single.start, 4);
      expect(
        line.substring(links.single.start, links.single.end + 1),
        'https://example.com',
      );
    });

    test('finds several links on one line', () {
      final links = LinkDetector.find('http://a.example and https://b.example');

      expect(links, hasLength(2));
      expect(links.first.url, 'http://a.example');
      expect(links.last.url, 'https://b.example');
    });

    test('keeps a path and query', () {
      final links = LinkDetector.find('https://example.com/a/b?c=1&d=2#frag');

      expect(links.single.url, 'https://example.com/a/b?c=1&d=2#frag');
    });

    test('recognises the schemes worth opening', () {
      for (final scheme in ['http', 'https', 'ftp', 'ssh', 'mailto']) {
        expect(
          LinkDetector.find('$scheme:something.example'),
          hasLength(1),
          reason: scheme,
        );
      }
    });

    test('ignores text with no URL in it', () {
      expect(LinkDetector.find('just some output'), isEmpty);
      expect(LinkDetector.find('a:b'), isEmpty);
    });

    test('ignores schemes that could execute something', () {
      // A remote host printing one of these must not become a way to run code
      // or open a local path on the user's own machine.
      for (final hostile in [
        'file:///etc/passwd',
        'javascript:alert(1)',
        'data:text/html,<script>',
        'vbscript:msgbox',
      ]) {
        expect(LinkDetector.find(hostile), isEmpty, reason: hostile);
      }
    });

    test('a bare scheme is not a link', () {
      expect(LinkDetector.find('https://'), isEmpty);
      expect(LinkDetector.find('mailto:'), isEmpty);
    });
  });

  group('trailing punctuation', () {
    test('a full stop belongs to the sentence, not the URL', () {
      expect(
        LinkDetector.find('go to https://example.com.').single.url,
        'https://example.com',
      );
    });

    test('so do commas, semicolons and question marks', () {
      for (final punctuation in [',', ';', ':', '!', '?']) {
        expect(
          LinkDetector.find('x https://example.com$punctuation').single.url,
          'https://example.com',
          reason: punctuation,
        );
      }
    });

    test('an unbalanced closing bracket is trimmed', () {
      expect(
        LinkDetector.find('(see https://example.com)').single.url,
        'https://example.com',
      );
    });

    test('a balanced bracket is part of the URL', () {
      // Wikipedia-style URLs really do contain brackets.
      expect(
        LinkDetector.find('https://example.com/a_(b)').single.url,
        'https://example.com/a_(b)',
      );
    });

    test('does not stop at whitespace-free punctuation inside the URL', () {
      expect(
        LinkDetector.find('https://example.com/a.b.c/d').single.url,
        'https://example.com/a.b.c/d',
      );
    });
  });

  group('at', () {
    const line = 'run https://example.com then';

    test('finds the link under a column inside it', () {
      expect(LinkDetector.at(line, 4)?.url, 'https://example.com');
      expect(LinkDetector.at(line, 10)?.url, 'https://example.com');
      expect(LinkDetector.at(line, 22)?.url, 'https://example.com');
    });

    test('returns nothing outside it', () {
      expect(LinkDetector.at(line, 0), isNull);
      expect(LinkDetector.at(line, 25), isNull);
    });
  });

  group('DetectedLink', () {
    test('compares by value', () {
      const a = DetectedLink(url: 'https://x', start: 0, end: 8);
      const b = DetectedLink(url: 'https://x', start: 0, end: 8);
      const c = DetectedLink(url: 'https://y', start: 0, end: 8);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
