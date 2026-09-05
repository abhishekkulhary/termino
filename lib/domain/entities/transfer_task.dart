import 'package:meta/meta.dart';

/// Which way a transfer is going.
enum TransferDirection {
  /// From the remote host to this device.
  download,

  /// From this device to the remote host.
  upload;

  /// A label for the UI.
  String get label => switch (this) {
    TransferDirection.download => 'Download',
    TransferDirection.upload => 'Upload',
  };
}

/// Where a transfer is in its life.
enum TransferStatus {
  /// Waiting for a slot.
  queued,

  /// Moving bytes.
  running,

  /// Finished successfully.
  completed,

  /// Stopped by the user.
  cancelled,

  /// Stopped by an error. May be retried.
  failed;

  /// Whether the transfer has stopped for good unless retried.
  bool get isFinished =>
      this != TransferStatus.queued && this != TransferStatus.running;

  /// Whether a retry makes sense.
  bool get canRetry =>
      this == TransferStatus.failed || this == TransferStatus.cancelled;
}

/// One file being moved, and how far along it is.
@immutable
class TransferTask {
  /// Creates a transfer.
  const new({
    required this.id,
    required this.direction,
    required this.remotePath,
    required this.localPath,
    required this.totalBytes,
    this.status = TransferStatus.queued,
    this.transferredBytes = 0,
    this.error,
  });

  /// Identifies this transfer for the lifetime of the app run.
  final String id;

  /// Which way it is going.
  final TransferDirection direction;

  /// The path on the server.
  final String remotePath;

  /// The path on this device.
  final String localPath;

  /// The file's size, or zero when the server did not report one.
  final int totalBytes;

  /// Where it is in its life.
  final TransferStatus status;

  /// How much has moved.
  final int transferredBytes;

  /// Why it failed, in words a user can act on.
  final String? error;

  /// The file's name, for display.
  String get filename {
    final path = direction == TransferDirection.download
        ? remotePath
        : localPath;
    final index = path.lastIndexOf('/');
    return index < 0 ? path : path.substring(index + 1);
  }

  /// How far along, from 0 to 1, or null when the size is unknown.
  ///
  /// Null rather than zero, so the UI can show an indeterminate bar instead of
  /// one that looks stuck — a server that reports no size is common enough for
  /// virtual files that guessing would be wrong.
  double? get progress {
    if (totalBytes <= 0) return null;
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  /// Returns a copy with the given changes.
  TransferTask copyWith({
    TransferStatus? status,
    int? transferredBytes,
    int? totalBytes,
    String? error,
    bool clearError = false,
  }) => TransferTask(
    id: id,
    direction: direction,
    remotePath: remotePath,
    localPath: localPath,
    totalBytes: totalBytes ?? this.totalBytes,
    status: status ?? this.status,
    transferredBytes: transferredBytes ?? this.transferredBytes,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  bool operator ==(Object other) =>
      other is TransferTask &&
      other.id == id &&
      other.status == status &&
      other.transferredBytes == transferredBytes &&
      other.totalBytes == totalBytes &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(id, status, transferredBytes, totalBytes, error);
}
