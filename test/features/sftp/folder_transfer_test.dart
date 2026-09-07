import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/sftp/application/folder_transfer.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';

/// Copying a folder is a walk over someone else's filesystem, which is exactly
/// the kind of thing that goes wrong quietly: a link that points at an
/// ancestor, a tree far bigger than anyone meant to touch, an empty directory
/// that silently vanishes on the way across.
void main() {
  RemoteEntry dir(String path) => RemoteEntry(
    name: path.split('/').last,
    path: path,
    isDirectory: true,
    isLink: false,
    size: 0,
  );

  RemoteEntry file(String path, {int size = 10}) => RemoteEntry(
    name: path.split('/').last,
    path: path,
    isDirectory: false,
    isLink: false,
    size: size,
  );

  RemoteEntry symlink(String path, {bool toDirectory = false}) => RemoteEntry(
    name: path.split('/').last,
    path: path,
    isDirectory: toDirectory,
    isLink: true,
    size: 0,
  );

  /// A remote tree, as a map of directory to what is in it.
  Future<List<RemoteEntry>> Function(String) remote(
    Map<String, List<RemoteEntry>> tree,
  ) =>
      (path) async => tree[path] ?? const [];

  group('planning a folder download', () {
    test('queues every file, with its path on both sides', () async {
      final plan = await FolderTransfer.planDownload(
        root: dir('/srv/logs'),
        destination: '/Users/me',
        list: remote({
          '/srv/logs': [dir('/srv/logs/2026'), file('/srv/logs/latest.log')],
          '/srv/logs/2026': [file('/srv/logs/2026/january.log', size: 40)],
        }),
      );

      expect(plan.files, hasLength(2));
      expect(
        plan.files.map((f) => f.remotePath),
        containsAll(['/srv/logs/latest.log', '/srv/logs/2026/january.log']),
      );
      expect(
        plan.files.map((f) => f.localPath),
        containsAll([
          '/Users/me/logs/latest.log',
          '/Users/me/logs/2026/january.log',
        ]),
      );
      expect(plan.totalBytes, 50);
    });

    test('the folder lands inside the destination, not on top of it', () async {
      final plan = await FolderTransfer.planDownload(
        root: dir('/srv/logs'),
        destination: '/Users/me',
        list: remote({'/srv/logs': []}),
      );

      expect(plan.directories, ['/Users/me/logs']);
    });

    test('an empty directory is still created', () async {
      // A folder that arrives with a directory missing is not the folder that
      // was copied.
      final plan = await FolderTransfer.planDownload(
        root: dir('/srv/logs'),
        destination: '/tmp',
        list: remote({
          '/srv/logs': [dir('/srv/logs/empty')],
          '/srv/logs/empty': [],
        }),
      );

      expect(plan.directories, ['/tmp/logs', '/tmp/logs/empty']);
      expect(plan.files, isEmpty);
    });

    test('directories come out parents first', () async {
      // They are created in this order, and a child cannot be made before its
      // parent exists.
      final plan = await FolderTransfer.planDownload(
        root: dir('/a'),
        destination: '/tmp',
        list: remote({
          '/a': [dir('/a/b')],
          '/a/b': [dir('/a/b/c')],
          '/a/b/c': [],
        }),
      );

      expect(plan.directories, ['/tmp/a', '/tmp/a/b', '/tmp/a/b/c']);
    });

    test('a symbolic link is skipped and counted', () async {
      // Following one is how a copy walks in a circle, or spends the evening
      // reading /dev/zero.
      final plan = await FolderTransfer.planDownload(
        root: dir('/srv/app'),
        destination: '/tmp',
        list: remote({
          '/srv/app': [
            file('/srv/app/real.txt'),
            symlink('/srv/app/current', toDirectory: true),
            symlink('/srv/app/alias.txt'),
          ],
        }),
      );

      expect(plan.files, hasLength(1));
      expect(plan.skippedLinks, 2);
    });

    test('a link pointing at an ancestor cannot make it loop', () async {
      // The tree here is genuinely circular; without the link check this walk
      // does not terminate.
      final plan = await FolderTransfer.planDownload(
        root: dir('/a'),
        destination: '/tmp',
        list: remote({
          '/a': [dir('/a/b')],
          '/a/b': [symlink('/a/b/up', toDirectory: true)],
        }),
      );

      expect(plan.skippedLinks, 1);
      expect(plan.truncated, isFalse);
    });

    test('a tree deeper than the limit stops and says so', () async {
      // Built deeper than the limit, so the walk has to be the thing that
      // stops it.
      final tree = <String, List<RemoteEntry>>{};
      var path = '/deep';
      for (var level = 0; level < 60; level++) {
        final child = '$path/level$level';
        tree[path] = [dir(child)];
        path = child;
      }
      tree[path] = [file('$path/bottom.txt')];

      final plan = await FolderTransfer.planDownload(
        root: dir('/deep'),
        destination: '/tmp',
        list: remote(tree),
        maxDepth: 5,
      );

      expect(plan.truncated, isTrue);
      expect(plan.files, isEmpty);
    });

    test('a tree wider than the limit stops and says so', () async {
      final plan = await FolderTransfer.planDownload(
        root: dir('/wide'),
        destination: '/tmp',
        list: remote({
          '/wide': [for (var i = 0; i < 50; i++) file('/wide/file$i.txt')],
        }),
        maxEntries: 10,
      );

      expect(plan.files, hasLength(10));
      expect(plan.truncated, isTrue);
    });

    test('a destination that already ends in a separator is not doubled', () {
      expect(
        FolderTransfer.planDownload(
          root: dir('/srv/logs'),
          destination: '/tmp/',
          list: remote({'/srv/logs': []}),
        ).then((plan) => plan.directories.single),
        completion('/tmp/logs'),
      );
    });
  });

  group('planning a folder upload', () {
    LocalEntry local(String path, {bool isDirectory = false, int size = 10}) =>
        LocalEntry(
          name: path.split('/').last,
          path: path,
          isDirectory: isDirectory,
          isLink: false,
          size: isDirectory ? 0 : size,
        );

    Future<List<LocalEntry>> Function(String) disk(
      Map<String, List<LocalEntry>> tree,
    ) =>
        (path) async => tree[path] ?? const [];

    test('queues every file into the current remote directory', () async {
      final plan = await FolderTransfer.planUpload(
        root: local('/Users/me/project', isDirectory: true),
        remoteParent: '/srv',
        list: disk({
          '/Users/me/project': [
            local('/Users/me/project/src', isDirectory: true),
            local('/Users/me/project/README.md', size: 5),
          ],
          '/Users/me/project/src': [
            local('/Users/me/project/src/main.dart', size: 7),
          ],
        }),
      );

      expect(
        plan.files.map((f) => f.remotePath),
        containsAll(['/srv/project/README.md', '/srv/project/src/main.dart']),
      );
      expect(plan.directories, ['/srv/project', '/srv/project/src']);
      expect(plan.totalBytes, 12);
    });

    test('the remote side always uses forward slashes', () async {
      // Uploading from Windows must not put backslashes in a remote path.
      final plan = await FolderTransfer.planUpload(
        root: const LocalEntry(
          name: 'project',
          path: r'C:\Users\me\project',
          isDirectory: true,
          isLink: false,
          size: 0,
        ),
        remoteParent: '/srv',
        separator: r'\',
        list: (path) async => path == r'C:\Users\me\project'
            ? [
                const LocalEntry(
                  name: 'notes.txt',
                  path: r'C:\Users\me\project\notes.txt',
                  isDirectory: false,
                  isLink: false,
                  size: 3,
                ),
              ]
            : const [],
      );

      expect(plan.files.single.remotePath, '/srv/project/notes.txt');
      expect(plan.files.single.localPath, r'C:\Users\me\project\notes.txt');
    });

    test('a symbolic link is skipped here too', () async {
      final plan = await FolderTransfer.planUpload(
        root: local('/Users/me/project', isDirectory: true),
        remoteParent: '/srv',
        list: disk({
          '/Users/me/project': [
            const LocalEntry(
              name: 'node_modules',
              path: '/Users/me/project/node_modules',
              isDirectory: true,
              isLink: true,
              size: 0,
            ),
            local('/Users/me/project/main.dart'),
          ],
        }),
      );

      expect(plan.files, hasLength(1));
      expect(plan.skippedLinks, 1);
    });

    test('an empty folder is a plan with one directory and no files', () async {
      final plan = await FolderTransfer.planUpload(
        root: local('/Users/me/empty', isDirectory: true),
        remoteParent: '/srv',
        list: disk({'/Users/me/empty': []}),
      );

      expect(plan.files, isEmpty);
      expect(plan.directories, ['/srv/empty']);
      expect(plan.isEmpty, isFalse, reason: 'the directory still gets made');
    });
  });
}
