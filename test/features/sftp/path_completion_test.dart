import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/sftp/application/path_completion.dart';

/// Completing a path is all edge cases: the root, a trailing slash, a relative
/// fragment, and a name that is the prefix of another. None of them is worth
/// finding out about through a text field and a live server.
void main() {
  group('splitting what has been typed', () {
    test('an absolute path splits at its last separator', () {
      final (:directory, :prefix) = PathCompletion.split(
        '/srv/log',
        current: '/home/me',
      );

      expect(directory, '/srv');
      expect(prefix, 'log');
    });

    test('a trailing slash means the directory itself, with nothing typed', () {
      final (:directory, :prefix) = PathCompletion.split(
        '/srv/logs/',
        current: '/home/me',
      );

      expect(directory, '/srv/logs');
      expect(prefix, '');
    });

    test('inside the root, the directory is the root', () {
      // The one case where cutting at the last slash leaves nothing, and the
      // empty string is not a path.
      final (:directory, :prefix) = PathCompletion.split(
        '/sr',
        current: '/home/me',
      );

      expect(directory, '/');
      expect(prefix, 'sr');
    });

    test('the bare root has nothing typed in it', () {
      final (:directory, :prefix) = PathCompletion.split(
        '/',
        current: '/home/me',
      );

      expect(directory, '/');
      expect(prefix, '');
    });

    test('a fragment with no separator completes where you are', () {
      final (:directory, :prefix) = PathCompletion.split(
        'pro',
        current: '/srv',
      );

      expect(directory, '/srv');
      expect(prefix, 'pro');
    });

    test('an empty field offers the current directory', () {
      final (:directory, :prefix) = PathCompletion.split('', current: '/srv');

      expect(directory, '/srv');
      expect(prefix, '');
    });
  });

  group('narrowing the candidates', () {
    const names = ['projects', 'project-notes', 'public', 'Photos'];

    test('keeps the ones the fragment could grow into', () {
      expect(PathCompletion.matching(names, 'pro'), [
        'projects',
        'project-notes',
      ]);
    });

    test('an empty fragment matches everything', () {
      expect(PathCompletion.matching(names, ''), names);
    });

    test('is case-sensitive, because the server is', () {
      // Offering `Photos` for `pho` completes to a path that does not exist.
      expect(PathCompletion.matching(names, 'pho'), isEmpty);
      expect(PathCompletion.matching(names, 'Pho'), ['Photos']);
    });
  });

  group('the common prefix', () {
    test('is as far as every candidate agrees', () {
      expect(
        PathCompletion.commonPrefix(['projects', 'project-notes']),
        'project',
      );
    });

    test('of one name is that name', () {
      expect(PathCompletion.commonPrefix(['projects']), 'projects');
    });

    test('of names that share nothing is empty', () {
      expect(PathCompletion.commonPrefix(['alpha', 'beta']), '');
    });

    test('of nothing is empty', () {
      expect(PathCompletion.commonPrefix(const []), '');
    });

    test('handles one name being a prefix of another', () {
      expect(PathCompletion.commonPrefix(['log', 'logs', 'logging']), 'log');
    });
  });

  group('completing', () {
    test('a single match is filled in, with a separator to descend', () {
      expect(
        PathCompletion.complete(
          '/srv/pub',
          names: ['public', 'private'],
          current: '/',
        ),
        '/srv/public/',
      );
    });

    test('several matches fill in as far as they agree', () {
      // What a shell does: as far as the answer is certain, no further.
      expect(
        PathCompletion.complete(
          '/srv/pro',
          names: ['projects', 'project-notes'],
          current: '/',
        ),
        '/srv/project',
      );
    });

    test('no match leaves what was typed alone', () {
      // Deleting somebody's typing because it does not exist yet would be
      // worse than doing nothing.
      expect(
        PathCompletion.complete('/srv/zzz', names: ['projects'], current: '/'),
        '/srv/zzz',
      );
    });

    test('an empty directory offers nothing and changes nothing', () {
      expect(
        PathCompletion.complete('/srv/', names: const [], current: '/'),
        '/srv/',
      );
    });

    test('a relative fragment stays relative', () {
      // Rewriting `pro` as `/srv/projects` would be correct and would also
      // move the cursor somewhere the typist did not put it.
      expect(
        PathCompletion.complete('pro', names: ['projects'], current: '/srv'),
        'projects/',
      );
    });

    test('completing inside the root does not double the separator', () {
      expect(
        PathCompletion.complete('/sr', names: ['srv'], current: '/'),
        '/srv/',
      );
    });

    test('a trailing slash with one child descends into it', () {
      expect(
        PathCompletion.complete('/srv/', names: ['only'], current: '/'),
        '/srv/only/',
      );
    });
  });
}
