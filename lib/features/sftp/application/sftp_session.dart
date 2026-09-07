import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/transfer_task.dart';
import 'package:termino/features/sftp/application/folder_transfer.dart';
import 'package:termino/features/sftp/application/transfer_queue.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

/// A live SFTP browsing session: one connection, the current directory, and
/// the transfer queue.
///
/// The connection is its own, separate from any terminal session on the same
/// host. That costs a second authentication, and buys isolation: a transfer
/// that fails, or a browser the user closes, cannot disturb a shell they have
/// work in progress in.
class SftpSession extends ChangeNotifier {
  /// Creates a session over [connection] for [host].
  new({
    required this.host,
    required this.connection,
    required this.service,
    required SftpClient client,
  }) : queue = TransferQueue(
         runner: SftpTransferRunner(
           client: client,
           openRead: (path) => File(path).openRead().map(Uint8List.fromList),
           openWrite: (path) async => File(path).openWrite(),
         ),
       ) {
    queue.addListener(notifyListeners);
  }

  /// Which server this is browsing.
  final SshHost host;

  /// The files being moved.
  final TransferQueue queue;

  /// The SSH connection this session owns.
  final SshConnection connection;

  /// The SFTP operations.
  final SftpService service;

  String _path = '.';
  List<RemoteEntry> _entries = const [];
  var _loading = false;
  String? _error;
  var _showHidden = false;
  var _disposed = false;

  /// The directory being shown.
  String get path => _path;

  /// What is in it, filtered by [showHidden].
  List<RemoteEntry> get entries => _showHidden
      ? List.unmodifiable(_entries)
      : List.unmodifiable(_entries.where((entry) => !entry.isHidden));

  /// Whether a listing is in flight.
  bool get isLoading => _loading;

  /// Why the last listing failed.
  String? get error => _error;

  /// Whether dotfiles are shown.
  bool get showHidden => _showHidden;

  /// Whether the current directory has a parent to go up to.
  bool get canGoUp => _path != '/' && _path.isNotEmpty;

  /// Shows or hides dotfiles.
  void toggleHidden() {
    _showHidden = !_showHidden;
    notifyListeners();
  }

  /// Loads the initial directory.
  Future<void> start() async => await open(await service.absolute('.'));

  /// Lists [target] and shows it.
  Future<void> open(String target) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resolved = await service.absolute(target);
      _entries = await service.list(resolved);
      _path = resolved;
    } on Object catch (failure) {
      _error = _describe(failure);
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Goes to the parent directory.
  Future<void> goUp() async {
    if (!canGoUp) return;
    final index = _path.lastIndexOf('/');
    await open(index <= 0 ? '/' : _path.substring(0, index));
  }

  /// Re-lists the current directory.
  Future<void> refresh() => open(_path);

  /// Queues a download of [entry] to [localPath].
  void download(RemoteEntry entry, String localPath) {
    queue.enqueue(
      direction: TransferDirection.download,
      remotePath: entry.path,
      localPath: localPath,
      totalBytes: entry.size,
    );
  }

  /// Queues an upload of [localPath] into the current directory.
  Future<void> upload(String localPath) async {
    final name = localPath.split(Platform.pathSeparator).last;
    final size = await File(localPath).length();
    queue.enqueue(
      direction: TransferDirection.upload,
      remotePath: '$_path/$name',
      localPath: localPath,
      totalBytes: size,
    );
  }

  /// Queues a download of the folder [entry] into [destination].
  ///
  /// Returns what it planned, so the UI can say how much is coming and what
  /// was skipped. Returns null if the tree could not be read at all — the
  /// error is on [error] as usual.
  ///
  /// The whole tree is walked and every directory created before a single byte
  /// moves. A transfer that made directories as it went would leave a
  /// half-built tree behind when it failed, and could not say up front how
  /// many files there were.
  Future<TransferPlan?> downloadFolder(
    RemoteEntry entry,
    String destination,
  ) async {
    try {
      final plan = await FolderTransfer.planDownload(
        root: entry,
        destination: destination,
        list: service.list,
        separator: Platform.pathSeparator,
      );

      for (final directory in plan.directories) {
        await Directory(directory).create(recursive: true);
      }
      for (final file in plan.files) {
        queue.enqueue(
          direction: TransferDirection.download,
          remotePath: file.remotePath,
          localPath: file.localPath,
          totalBytes: file.size,
        );
      }
      return plan;
    } on Object catch (failure) {
      _error = _describe(failure);
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  /// Queues an upload of the local folder at [localPath] into this directory.
  ///
  /// Returns what it planned, or null if the folder could not be read.
  Future<TransferPlan?> uploadFolder(String localPath) async {
    try {
      final directory = Directory(localPath);
      final plan = await FolderTransfer.planUpload(
        root: LocalEntry(
          name: localPath.split(Platform.pathSeparator).last,
          path: localPath,
          isDirectory: true,
          isLink: false,
          size: 0,
        ),
        remoteParent: _path,
        list: listLocalDirectory,
      );

      // Parents before children, which is the order the plan is built in.
      for (final remote in plan.directories) {
        await service.ensureDirectory(remote);
      }
      for (final file in plan.files) {
        queue.enqueue(
          direction: TransferDirection.upload,
          remotePath: file.remotePath,
          localPath: file.localPath,
          totalBytes: file.size,
        );
      }

      // Refreshed so the new folder appears without the user having to ask.
      if (directory.existsSync()) await refresh();
      return plan;
    } on Object catch (failure) {
      _error = _describe(failure);
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  /// Lists a local directory the way the planner wants it.
  ///
  /// `followLinks: false` so a link is reported as a link and skipped, rather
  /// than resolved into whatever it points at — which for a link to an
  /// ancestor would walk in a circle.
  static Future<List<LocalEntry>> listLocalDirectory(String path) async {
    final entries = <LocalEntry>[];

    await for (final child in Directory(path).list(followLinks: false)) {
      // Synchronous stat deliberately: the async one dispatches to a worker
      // thread per entry, which on a folder of a few thousand files costs far
      // more than the stat itself.
      final stat = child.statSync();
      entries.add(
        LocalEntry(
          name: child.path.split(Platform.pathSeparator).last,
          path: child.path,
          isDirectory: child is Directory,
          isLink: child is Link,
          size: child is File ? stat.size : 0,
        ),
      );
    }
    return entries;
  }

  /// Creates a directory here and refreshes.
  Future<void> makeDirectory(String name) =>
      _guard(() => service.makeDirectory('$_path/$name'));

  /// Renames an entry and refreshes.
  Future<void> rename(RemoteEntry entry, String name) =>
      _guard(() => service.rename(entry.path, '$_path/$name'));

  /// Deletes an entry and refreshes.
  ///
  /// A directory goes with everything in it. SFTP's `rmdir` refuses a
  /// directory that is not empty, so before folders could be transferred there
  /// was nothing to delete recursively and no reason to; now there is.
  Future<void> delete(RemoteEntry entry) => _guard(
    () => entry.isDirectory && !entry.isLink
        ? service.deleteRecursively(entry)
        : service.delete(entry),
  );

  /// Changes an entry's permissions and refreshes.
  Future<void> chmod(RemoteEntry entry, int mode) =>
      _guard(() => service.chmod(entry.path, mode));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
    } on Object catch (failure) {
      _error = _describe(failure);
      if (!_disposed) notifyListeners();
    }
  }

  /// Turns a protocol error into something a user can act on.
  static String _describe(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission')) return 'Permission denied.';
    if (text.contains('no such file')) return 'That path does not exist.';
    if (text.contains('failure')) return 'The server refused that operation.';
    return 'Something went wrong talking to the server.';
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    queue
      ..removeListener(notifyListeners)
      ..dispose();
    await service.close();
    await connection.close();
    super.dispose();
  }
}
