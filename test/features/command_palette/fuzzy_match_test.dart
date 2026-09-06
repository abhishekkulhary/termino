import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/command_palette/application/fuzzy_match.dart';

/// Orders [candidates] the way the palette would for [query].
List<String> ranked(String query, List<String> candidates) {
  final scored = <(String, int)>[];
  for (final candidate in candidates) {
    final score = FuzzyMatch.score(query, candidate);
    if (score != null) scored.add((candidate, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.map((entry) => entry.$1).toList();
}

void main() {
  group('score', () {
    test('an empty query matches everything', () {
      expect(FuzzyMatch.score('', 'Hosts'), 0);
      expect(FuzzyMatch.score('   ', 'Hosts'), 0);
    });

    test('matches letters in order, not only substrings', () {
      expect(FuzzyMatch.score('bsv', 'Build server'), isNotNull);
      expect(FuzzyMatch.score('hst', 'Hosts'), isNotNull);
    });

    test('refuses letters that are out of order', () {
      expect(FuzzyMatch.score('vsb', 'Build server'), isNull);
    });

    test('refuses a letter that is not there at all', () {
      expect(FuzzyMatch.score('bzz', 'Build server'), isNull);
    });

    test('is case insensitive', () {
      expect(FuzzyMatch.score('BUILD', 'build server'), isNotNull);
      expect(FuzzyMatch.score('build', 'BUILD SERVER'), isNotNull);
    });

    test('spaces in the query mean "then", not a literal space', () {
      expect(FuzzyMatch.score('bu se', 'Build server'), isNotNull);
      expect(FuzzyMatch.score('bu se', 'Bundle segment'), isNotNull);
    });
  });

  group('ranking', () {
    test('a prefix beats a match in the middle', () {
      expect(ranked('ho', ['Hosts', 'Which host']).first, 'Hosts');
    });

    test('word starts beat scattered letters', () {
      expect(
        ranked('bs', ['Build server', 'Bits and sundry bobs']).first,
        'Build server',
      );
    });

    test('an adjacent run beats letters spread through a sentence', () {
      expect(ranked('serv', ['server', 'set every route via']).first, 'server');
    });

    test('a word boundary counts, which is what hostnames are made of', () {
      // Hyphens and dots start words: `w01` should find `web-01.example.com`
      // ahead of something that merely contains those letters.
      expect(
        ranked('we01', ['web-01.example.com', 'answer to 01 questions']).first,
        'web-01.example.com',
      );
    });

    test('a shorter candidate wins when the match is otherwise equal', () {
      // Both start with the query; the tighter answer is the better one.
      expect(
        ranked('conn', [
          'Connect to a host that has a very long descriptive label',
          'Connect',
        ]).first,
        'Connect',
      );
    });
  });

  group('scoreAny', () {
    test('takes the best of several searchable fields', () {
      // A host is findable by its label or by the user@host it connects to.
      final byLabel = FuzzyMatch.score('pi', 'Raspberry Pi')!;
      final best = FuzzyMatch.scoreAny('pi', ['Raspberry Pi', 'pi@10.0.0.4'])!;

      expect(
        best,
        greaterThan(byLabel),
        reason: 'the hostname starts with the query, so it scores higher',
      );
    });

    test('is null only when nothing matches', () {
      expect(FuzzyMatch.scoreAny('zzz', ['Hosts', 'Keys']), isNull);
      expect(FuzzyMatch.scoreAny('ke', ['Hosts', 'Keys']), isNotNull);
    });
  });
}
