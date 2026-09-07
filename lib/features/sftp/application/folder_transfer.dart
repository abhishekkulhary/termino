import 'package:meta/meta.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';

/// One file on this device, as a folder walk sees it.
///
/// A tiny mirror of `FileSystemEntity` so the planner can be tested without
/// touching a disk, and so it compiles on the web, which has neither.
@immutable
class LocalEntry {
  /// Creates an entry.
  const new({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.isLink,
    required this.size,
  });

  /// The last path segment.
  final String name;

  /// The full path.
  final String path;

  /// Whether it is a directory.
  final bool isDirectory;

  /// Whether it is a symbolic link.
  final bool isLink;

  /// Size in bytes.
  final int size;
}

/// One file a folder transfer will move.
@immutable
class PlannedFile {
  /// Creates a planned transfer.
  const new({
    required this.remotePath,
    required this.localPath,
    required this.size,
  });

  /// Where it is, or will be, on the server.
  final String remotePath;

  /// Where it is, or will be, on this device.
  final String localPath;

  /// How big it is, as far as the source says.
  final int size;
}

/// What moving a folder will actually do, worked out before anything moves.
///
/// Planned in full first rather than discovered while transferring, for three
/// reasons that all showed up as questions the UI could not otherwise answer:
/// how many files there are, how many bytes in total, and whether anything was
/// skipped. A walk that queued as it went could only say "still counting".
@immutable
class TransferPlan {
  /// Creates a plan.
  const new({
    required this.files,
    required this.directories,
    this.skippedLinks = 0,
    this.truncated = false,
  });

  /// The files to move.
  final List<PlannedFile> files;

  /// Directories to create first, parents before children.
  ///
  /// Listed even when empty of files: a folder someone copies should come out
  /// the same shape it went in.
  final List<String> directories;

  /// How many symbolic links were passed over.
  final int skippedLinks;

  /// Whether the walk stopped at its limit rather than at the end of the tree.
  final bool truncated;

  /// The total size of everything to move.
  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);

  /// Whether there is anything at all to do.
  bool get isEmpty => files.isEmpty && directories.isEmpty;
}

/// Plans folder transfers by walking a tree before moving any of it.
///
/// ## Why symbolic links are skipped
///
/// A link is a name pointing somewhere else, and following one while copying a
/// tree has two failure modes that are not hypothetical. A link to an ancestor
/// makes the walk recurse until it runs out of something; a link to `/dev/zero`
/// or a named pipe makes a "file" that never ends. Neither is what someone
/// means by "download this folder". They are counted and reported rather than
/// silently ignored.
///
/// ## Why there are limits
///
/// A mistaken tap on `/` should not spend twenty minutes listing a server's
/// entire filesystem before it does anything visible. The walk stops at
/// [defaultMaxEntries] or [defaultMaxDepth] and says it stopped.
abstract final class FolderTransfer {
  /// The most files one folder transfer will queue.
  static const defaultMaxEntries = 2000;

  /// How deep the walk will go.
  static const defaultMaxDepth = 32;

  /// Plans a download of the remote folder [root] into [destination].
  ///
  /// [destination] is the local directory that will *contain* the folder, so
  /// downloading `/srv/logs` into `/Users/me` produces `/Users/me/logs`.
  static Future<TransferPlan> planDownload({
    required RemoteEntry root,
    required String destination,
    required Future<List<RemoteEntry>> Function(String path) list,
    String separator = '/',
    int maxEntries = defaultMaxEntries,
    int maxDepth = defaultMaxDepth,
  }) async {
    final files = <PlannedFile>[];
    final directories = <String>[];
    var skipped = 0;
    var truncated = false;

    final localRoot = _join(destination, root.name, separator);
    directories.add(localRoot);

    Future<void> walk(String remote, String local, int depth) async {
      if (truncated) return;
      if (depth > maxDepth) {
        truncated = true;
        return;
      }

      final entries = await list(remote);
      for (final entry in entries) {
        if (files.length >= maxEntries) {
          truncated = true;
          return;
        }
        if (entry.isLink) {
          skipped++;
          continue;
        }

        final child = _join(local, entry.name, separator);
        if (entry.isDirectory) {
          directories.add(child);
          await walk(entry.path, child, depth + 1);
        } else {
          files.add(
            PlannedFile(
              remotePath: entry.path,
              localPath: child,
              size: entry.size,
            ),
          );
        }
      }
    }

    await walk(root.path, localRoot, 1);

    return TransferPlan(
      files: files,
      directories: directories,
      skippedLinks: skipped,
      truncated: truncated,
    );
  }

  /// Plans an upload of the local folder [root] into [remoteParent].
  ///
  /// [remoteParent] is the directory that will *contain* the folder, matching
  /// [planDownload].
  static Future<TransferPlan> planUpload({
    required LocalEntry root,
    required String remoteParent,
    required Future<List<LocalEntry>> Function(String path) list,
    String separator = '/',
    int maxEntries = defaultMaxEntries,
    int maxDepth = defaultMaxDepth,
  }) async {
    final files = <PlannedFile>[];
    final directories = <String>[];
    var skipped = 0;
    var truncated = false;

    final remoteRoot = _join(remoteParent, root.name, '/');
    directories.add(remoteRoot);

    Future<void> walk(String local, String remote, int depth) async {
      if (truncated) return;
      if (depth > maxDepth) {
        truncated = true;
        return;
      }

      final entries = await list(local);
      for (final entry in entries) {
        if (files.length >= maxEntries) {
          truncated = true;
          return;
        }
        if (entry.isLink) {
          skipped++;
          continue;
        }

        // The remote side always uses `/`, whatever this device uses.
        final child = _join(remote, entry.name, '/');
        if (entry.isDirectory) {
          directories.add(child);
          await walk(entry.path, child, depth + 1);
        } else {
          files.add(
            PlannedFile(
              remotePath: child,
              localPath: entry.path,
              size: entry.size,
            ),
          );
        }
      }
    }

    await walk(root.path, remoteRoot, 1);

    return TransferPlan(
      files: files,
      directories: directories,
      skippedLinks: skipped,
      truncated: truncated,
    );
  }

  static String _join(String directory, String name, String separator) =>
      directory.endsWith(separator)
      ? '$directory$name'
      : '$directory$separator$name';
}
