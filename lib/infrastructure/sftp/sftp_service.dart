import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:termino/domain/entities/transfer_task.dart';
import 'package:termino/features/sftp/application/transfer_queue.dart';

/// One entry in a remote directory.
class RemoteEntry {
  /// Creates an entry.
  const new({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.isLink,
    required this.size,
    this.modified,
    this.mode,
  });

  /// The file name, without its directory.
  final String name;

  /// The full remote path.
  final String path;

  /// Whether this is a directory.
  final bool isDirectory;

  /// Whether this is a symbolic link.
  final bool isLink;

  /// Size in bytes, or zero when unknown.
  final int size;

  /// Last modification time, when the server reported one.
  final DateTime? modified;

  /// POSIX permission bits, when the server reported them.
  final int? mode;

  /// Whether this entry is hidden by convention.
  bool get isHidden => name.startsWith('.');

  /// The permissions as `rwxr-xr-x`, or null when unknown.
  String? get modeString {
    final bits = mode;
    if (bits == null) return null;
    const flags = ['x', 'w', 'r'];
    final buffer = StringBuffer();
    for (var group = 2; group >= 0; group--) {
      for (var bit = 2; bit >= 0; bit--) {
        buffer.write(bits & (1 << (group * 3 + bit)) != 0 ? flags[bit] : '-');
      }
    }
    return buffer.toString();
  }
}

/// Browses and transfers files over SFTP.
///
/// Wraps `dartssh2`'s SFTP client so that the UI never touches it directly,
/// and so failures arrive as messages rather than protocol errors.
class SftpService {
  /// Creates a service over an SFTP client.
  new(this._client);

  final SftpClient _client;

  /// Lists [path], directories first and then alphabetically — which is how
  /// people scan a directory, rather than in whatever order the server sends.
  Future<List<RemoteEntry>> list(String path) async {
    final names = await _client.listdir(path);
    final entries = <RemoteEntry>[];

    for (final name in names) {
      if (name.filename == '.' || name.filename == '..') continue;
      entries.add(_toEntry(name, path));
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  /// Resolves [path] to an absolute one, expanding `.` and `~`.
  Future<String> absolute(String path) => _client.absolute(path);

  /// Creates a directory.
  Future<void> makeDirectory(String path) => _client.mkdir(path);

  /// Renames or moves an entry.
  Future<void> rename(String from, String to) => _client.rename(from, to);

  /// Deletes a file, or a directory that must already be empty.
  Future<void> delete(RemoteEntry entry) => entry.isDirectory
      ? _client.rmdir(entry.path)
      : _client.remove(entry.path);

  /// Changes an entry's permission bits.
  Future<void> chmod(String path, int mode) =>
      _client.setStat(path, SftpFileAttrs(mode: SftpFileMode.value(mode)));

  /// The size of [path], or zero when the server does not report one.
  Future<int> sizeOf(String path) async {
    final attrs = await _client.stat(path);
    return attrs.size ?? 0;
  }

  /// Closes the SFTP channel.
  Future<void> close() => _client.close();

  RemoteEntry _toEntry(SftpName name, String directory) {
    final attrs = name.attr;
    final base = directory.endsWith('/') ? directory : '$directory/';

    return RemoteEntry(
      name: name.filename,
      path: '$base${name.filename}',
      isDirectory: attrs.isDirectory,
      isLink: attrs.isSymbolicLink,
      size: attrs.size ?? 0,
      modified: attrs.modifyTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(attrs.modifyTime! * 1000),
      mode: attrs.mode?.value,
    );
  }
}

/// Moves files with SFTP, for the transfer queue.
class SftpTransferRunner implements TransferRunner {
  /// Creates a runner over [client], reading and writing local files through
  /// [openRead] and [openWrite] so the queue stays testable and the web build
  /// — which has no filesystem — can supply its own.
  const new({
    required this.client,
    required this.openRead,
    required this.openWrite,
  });

  /// The SFTP client.
  final SftpClient client;

  /// Opens a local file for reading, for uploads.
  final Stream<Uint8List> Function(String path) openRead;

  /// Opens a local sink for writing, for downloads.
  final Future<StreamSink<List<int>>> Function(String path) openWrite;

  @override
  Future<void> run(
    TransferTask task, {
    required TransferProgress onProgress,
    required Future<void> cancelled,
  }) => switch (task.direction) {
    TransferDirection.download => _download(task, onProgress, cancelled),
    TransferDirection.upload => _upload(task, onProgress, cancelled),
  };

  Future<void> _download(
    TransferTask task,
    TransferProgress onProgress,
    Future<void> cancelled,
  ) async {
    final file = await client.open(task.remotePath);
    final sink = await openWrite(task.localPath);
    var written = 0;
    var stopped = false;
    unawaited(cancelled.then((_) => stopped = true));

    try {
      await for (final chunk in file.read()) {
        if (stopped) break;
        sink.add(chunk);
        written += chunk.length;
        onProgress(written);
      }
    } finally {
      await sink.close();
      await file.close();
    }
  }

  Future<void> _upload(
    TransferTask task,
    TransferProgress onProgress,
    Future<void> cancelled,
  ) async {
    final file = await client.open(
      task.remotePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );

    try {
      final writer = file.write(
        openRead(task.localPath),
        onProgress: onProgress,
      );
      unawaited(cancelled.then((_) => writer.abort()));
      await writer.done;
    } finally {
      await file.close();
    }
  }
}
