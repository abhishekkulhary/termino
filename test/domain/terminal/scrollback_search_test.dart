import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/terminal/scrollback_search.dart';

List<SearchLine> lines(List<String> texts, {Set<int> wrapped = const {}}) => [
  for (var i = 0; i < texts.length; i++)
    (text: texts[i], wrapped: wrapped.contains(i)),
];

void main() {
  group('literal search', () {
    test('finds a match and reports its cells', () {
      final matches = ScrollbackSearch.find(lines(['hello world']), 'world');

      expect(matches, hasLength(1));
      expect(matches.single.startX, 6);
      expect(matches.single.startY, 0);
      expect(matches.single.endX, 10);
      expect(matches.single.endY, 0);
    });

    test('finds every occurrence, in order', () {
      final matches = ScrollbackSearch.find(
        lines(['abc', 'xxabcxx', 'abc']),
        'abc',
      );

      expect(matches, hasLength(3));
      expect(matches.map((m) => m.startY), [0, 1, 2]);
      expect(matches[1].startX, 2);
    });

    test('is case-insensitive by default', () {
      expect(ScrollbackSearch.find(lines(['Hello']), 'hello'), hasLength(1));
    });

    test('honours case sensitivity when asked', () {
      expect(
        ScrollbackSearch.find(
          lines(['Hello']),
          'hello',
          options: const SearchOptions(caseSensitive: true),
        ),
        isEmpty,
      );
    });

    test('treats the query as literal text, not a pattern', () {
      // A user searching for a path or a glob should not need to escape it.
      expect(
        ScrollbackSearch.find(lines(['a.c and abc']), 'a.c'),
        hasLength(1),
      );
      expect(
        ScrollbackSearch.find(lines(['a.c and abc']), 'a.c').single.startX,
        0,
      );
    });

    test('an empty query matches nothing', () {
      expect(ScrollbackSearch.find(lines(['anything']), ''), isEmpty);
    });

    test('an empty buffer yields nothing', () {
      expect(ScrollbackSearch.find(const [], 'anything'), isEmpty);
    });

    test('does not match across two unrelated lines', () {
      // "lo" ends line 0 and "wo" starts line 1; they are separate lines and
      // must not join into one match.
      expect(ScrollbackSearch.find(lines(['hello', 'world']), 'lowo'), isEmpty);
    });
  });

  group('wrapped lines', () {
    test('a match spanning a wrap is found', () {
      // The user sees one long line; the buffer holds two rows.
      final matches = ScrollbackSearch.find(
        lines(['configur', 'ation'], wrapped: {1}),
        'configuration',
      );

      expect(matches, hasLength(1));
      expect(matches.single.startY, 0);
      expect(matches.single.startX, 0);
      expect(matches.single.endY, 1, reason: 'the match ends on the next row');
      expect(matches.single.endX, 4);
      expect(matches.single.spansRows, isTrue);
    });

    test('an unwrapped neighbour still blocks a join', () {
      expect(
        ScrollbackSearch.find(lines(['configur', 'ation']), 'configuration'),
        isEmpty,
      );
    });
  });

  group('regex search', () {
    test('matches a pattern', () {
      final matches = ScrollbackSearch.find(
        lines(['error 404', 'error 500']),
        r'error \d+',
        options: const SearchOptions(useRegex: true),
      );

      expect(matches, hasLength(2));
    });

    test('reports an invalid pattern rather than throwing something raw', () {
      expect(
        () => ScrollbackSearch.find(
          lines(['x']),
          '[unclosed',
          options: const SearchOptions(useRegex: true),
        ),
        throwsA(isA<InvalidSearchPattern>()),
      );
    });

    test('an invalid pattern carries a message worth showing', () {
      try {
        ScrollbackSearch.find(
          lines(['x']),
          '(',
          options: const SearchOptions(useRegex: true),
        );
        fail('expected a failure');
      } on InvalidSearchPattern catch (failure) {
        expect(failure.message, isNotEmpty);
      }
    });

    test('a zero-width match is ignored', () {
      // `x*` matches the empty string everywhere; highlighting each one would
      // be meaningless.
      final matches = ScrollbackSearch.find(
        lines(['abc']),
        'x*',
        options: const SearchOptions(useRegex: true),
      );

      expect(matches, isEmpty);
    });

    test('anchors work per line', () {
      final matches = ScrollbackSearch.find(
        lines(['start here', 'not start']),
        '^start',
        options: const SearchOptions(useRegex: true),
      );

      expect(matches, hasLength(1));
      expect(matches.single.startY, 0);
    });
  });

  group('whole word', () {
    test('matches only complete words', () {
      final matches = ScrollbackSearch.find(
        lines(['cat concatenate cat']),
        'cat',
        options: const SearchOptions(wholeWord: true),
      );

      expect(matches, hasLength(2));
      expect(matches.first.startX, 0);
      expect(matches.last.startX, 16);
    });

    test('combines with regex', () {
      final matches = ScrollbackSearch.find(
        lines(['id42 and 42']),
        r'\d+',
        options: const SearchOptions(useRegex: true, wholeWord: true),
      );

      expect(matches, hasLength(1), reason: 'id42 is not a whole-word match');
      expect(matches.single.startX, 9);
    });
  });

  group('SearchMatch', () {
    test('compares by value', () {
      const a = SearchMatch(startX: 1, startY: 2, endX: 3, endY: 4);
      const b = SearchMatch(startX: 1, startY: 2, endX: 3, endY: 4);
      const c = SearchMatch(startX: 9, startY: 2, endX: 3, endY: 4);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
