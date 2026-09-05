import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:termino/domain/entities/transfer_task.dart';

/// Reports how much of a transfer has moved.
typedef TransferProgress = void Function(int transferredBytes);

/// Performs one transfer, reporting progress and honouring cancellation.
///
/// Injected so the queue can be tested without a server: the queue's job is
/// ordering, concurrency, cancellation and retry, none of which needs real
/// bytes to be moved.
abstract class TransferRunner {
  /// Moves the file described by [task].
  ///
  /// Should complete when the transfer finishes, throw on failure, and stop
  /// promptly when [cancelled] completes.
  Future<void> run(
    TransferTask task, {
    required TransferProgress onProgress,
    required Future<void> cancelled,
  });
}

/// The queue of files being moved to and from a server.
///
/// Runs a bounded number at once. Unbounded parallel transfers are worse than
/// they sound: they compete for the same connection, make every individual
/// transfer slower, and turn a progress list into noise.
class TransferQueue extends ChangeNotifier {
  /// Creates a queue driven by [runner].
  new({required this.runner, this.maxConcurrent = 2});

  /// Performs the transfers.
  final TransferRunner runner;

  /// How many may run at once.
  final int maxConcurrent;

  final List<TransferTask> _tasks = [];
  final Map<String, Completer<void>> _cancellations = {};
  var _nextId = 0;
  var _disposed = false;

  /// Every transfer, newest last.
  List<TransferTask> get tasks => List.unmodifiable(_tasks);

  /// Transfers still queued or running.
  List<TransferTask> get active =>
      _tasks.where((task) => !task.status.isFinished).toList();

  /// How many are currently moving bytes.
  int get runningCount =>
      _tasks.where((task) => task.status == TransferStatus.running).length;

  /// Whether anything is queued or running.
  bool get isBusy => active.isNotEmpty;

  /// Adds a transfer and starts it when a slot is free.
  TransferTask enqueue({
    required TransferDirection direction,
    required String remotePath,
    required String localPath,
    int totalBytes = 0,
  }) {
    final task = TransferTask(
      id: 'transfer-${_nextId++}',
      direction: direction,
      remotePath: remotePath,
      localPath: localPath,
      totalBytes: totalBytes,
    );
    _tasks.add(task);
    notifyListeners();
    _pump();
    return task;
  }

  /// Stops a transfer. A queued one never starts; a running one is aborted.
  void cancel(String id) {
    final index = _indexOf(id);
    if (index < 0) return;
    if (_tasks[index].status.isFinished) return;

    _cancellations.remove(id)?.complete();
    _update(id, (task) => task.copyWith(status: TransferStatus.cancelled));
    _pump();
  }

  /// Re-queues a failed or cancelled transfer, from the beginning.
  void retry(String id) {
    final index = _indexOf(id);
    if (index < 0 || !_tasks[index].status.canRetry) return;

    _update(
      id,
      (task) => task.copyWith(
        status: TransferStatus.queued,
        transferredBytes: 0,
        clearError: true,
      ),
    );
    _pump();
  }

  /// Cancels everything still in flight.
  void cancelAll() {
    for (final task in active) {
      cancel(task.id);
    }
  }

  /// Forgets transfers that have finished, leaving the active ones.
  void clearFinished() {
    _tasks.removeWhere((task) => task.status.isFinished);
    notifyListeners();
  }

  void _pump() {
    if (_disposed) return;

    while (runningCount < maxConcurrent) {
      final next = _tasks
          .where((task) => task.status == TransferStatus.queued)
          .firstOrNull;
      if (next == null) return;

      _update(next.id, (task) => task.copyWith(status: TransferStatus.running));
      unawaited(_run(next.id));
    }
  }

  Future<void> _run(String id) async {
    final cancellation = Completer<void>();
    _cancellations[id] = cancellation;

    final index = _indexOf(id);
    if (index < 0) return;

    try {
      await runner.run(
        _tasks[index],
        onProgress: (bytes) {
          // A progress report arriving after cancellation must not resurrect
          // the task or overwrite its final state.
          final current = _indexOf(id);
          if (current < 0) return;
          if (_tasks[current].status != TransferStatus.running) return;
          _update(id, (task) => task.copyWith(transferredBytes: bytes));
        },
        cancelled: cancellation.future,
      );

      if (_statusOf(id) == TransferStatus.running) {
        _update(
          id,
          (task) => task.copyWith(
            status: TransferStatus.completed,
            transferredBytes: task.totalBytes > 0
                ? task.totalBytes
                : task.transferredBytes,
          ),
        );
      }
    } on Object catch (error) {
      if (_statusOf(id) == TransferStatus.running) {
        _update(
          id,
          (task) => task.copyWith(
            status: TransferStatus.failed,
            error: _describe(error),
          ),
        );
      }
    } finally {
      _cancellations.remove(id);
      _pump();
    }
  }

  /// Turns an exception into something worth showing.
  ///
  /// A raw exception string is never surfaced; see the error taxonomy rule in
  /// ARCHITECTURE.md.
  static String _describe(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission')) return 'Permission denied.';
    if (text.contains('no such file')) return 'The file no longer exists.';
    if (text.contains('no space')) return 'The destination is full.';
    return 'The transfer failed.';
  }

  int _indexOf(String id) => _tasks.indexWhere((task) => task.id == id);

  TransferStatus? _statusOf(String id) {
    final index = _indexOf(id);
    return index < 0 ? null : _tasks[index].status;
  }

  void _update(String id, TransferTask Function(TransferTask) change) {
    final index = _indexOf(id);
    if (index < 0) return;
    _tasks[index] = change(_tasks[index]);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    // Idempotent: a queue owned by a screen can plausibly be disposed by both
    // the screen and whatever created it, and ChangeNotifier throws on a
    // second call.
    if (_disposed) return;
    _disposed = true;
    for (final cancellation in _cancellations.values) {
      if (!cancellation.isCompleted) cancellation.complete();
    }
    _cancellations.clear();
    super.dispose();
  }
}
