import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/transfer_task.dart';
import 'package:termino/features/sftp/application/transfer_queue.dart';

/// A runner the test drives by hand, so ordering and concurrency can be
/// checked without moving any bytes.
class ControllableRunner implements TransferRunner {
  final Map<String, Completer<void>> completers = {};
  final Map<String, TransferProgress> progress = {};
  final List<String> started = [];
  final List<String> cancelledIds = [];

  @override
  Future<void> run(
    TransferTask task, {
    required TransferProgress onProgress,
    required Future<void> cancelled,
  }) {
    started.add(task.id);
    progress[task.id] = onProgress;
    final completer = Completer<void>();
    completers[task.id] = completer;

    unawaited(
      cancelled.then((_) {
        cancelledIds.add(task.id);
        if (!completer.isCompleted) completer.complete();
      }),
    );

    return completer.future;
  }

  void finish(String id) => completers[id]?.complete();

  void fail(String id, Object error) => completers[id]?.completeError(error);
}

void main() {
  late ControllableRunner runner;
  late TransferQueue queue;

  setUp(() {
    runner = ControllableRunner();
    // Two at a time is the default; named here because several tests depend
    // on exactly that number.
    queue = TransferQueue(runner: runner);
  });

  // A tear-off would be evaluated at registration time, before setUp runs.
  tearDown(() => queue.dispose());

  TransferTask add({String remote = '/remote/file', int size = 100}) =>
      queue.enqueue(
        direction: TransferDirection.download,
        remotePath: remote,
        localPath: '/local/file',
        totalBytes: size,
      );

  group('queueing', () {
    test('a new transfer starts immediately when a slot is free', () async {
      final task = add();
      await pumpEventQueue();

      expect(queue.tasks.single.id, task.id);
      expect(runner.started, [task.id]);
    });

    test('runs at most maxConcurrent at once', () async {
      final first = add();
      final second = add();
      final third = add();
      await pumpEventQueue();

      expect(runner.started, [first.id, second.id]);
      expect(queue.runningCount, 2);
      expect(
        queue.tasks.last.status,
        TransferStatus.queued,
        reason: 'the third waits for a slot',
      );
      expect(third.id, isNotNull);
    });

    test('a finished transfer lets the next one start', () async {
      final first = add();
      add();
      final third = add();
      await pumpEventQueue();

      runner.finish(first.id);
      await pumpEventQueue();

      expect(runner.started, contains(third.id));
      expect(queue.runningCount, 2);
    });

    test('transfers keep their queue order', () async {
      final ids = [for (var i = 0; i < 4; i++) add().id];
      await pumpEventQueue();

      expect(queue.tasks.map((task) => task.id), ids);
    });
  });

  group('progress', () {
    test('is reported while running', () async {
      final task = add();
      await pumpEventQueue();

      runner.progress[task.id]!(40);
      await pumpEventQueue();

      expect(queue.tasks.single.transferredBytes, 40);
      expect(queue.tasks.single.progress, 0.4);
    });

    test('is unknown when the size is not reported', () async {
      queue.enqueue(
        direction: TransferDirection.download,
        remotePath: '/proc/self/status',
        localPath: '/local/status',
      );
      await pumpEventQueue();

      expect(
        queue.tasks.single.progress,
        isNull,
        reason: 'an indeterminate bar is honest; a stuck one is not',
      );
    });

    test('completing fills the bar', () async {
      final task = add();
      await pumpEventQueue();

      runner.finish(task.id);
      await pumpEventQueue();

      expect(queue.tasks.single.status, TransferStatus.completed);
      expect(queue.tasks.single.progress, 1.0);
    });
  });

  group('cancellation', () {
    test('a running transfer is told to stop', () async {
      final task = add();
      await pumpEventQueue();

      queue.cancel(task.id);
      await pumpEventQueue();

      expect(runner.cancelledIds, contains(task.id));
      expect(queue.tasks.single.status, TransferStatus.cancelled);
    });

    test('a queued transfer never starts', () async {
      add();
      add();
      final third = add();
      await pumpEventQueue();

      queue.cancel(third.id);
      await pumpEventQueue();

      expect(runner.started, isNot(contains(third.id)));
      expect(queue.tasks.last.status, TransferStatus.cancelled);
    });

    test('cancelling frees a slot for the next transfer', () async {
      final first = add();
      add();
      final third = add();
      await pumpEventQueue();

      queue.cancel(first.id);
      await pumpEventQueue();

      expect(runner.started, contains(third.id));
    });

    test('late progress does not resurrect a cancelled transfer', () async {
      final task = add();
      await pumpEventQueue();
      queue.cancel(task.id);
      await pumpEventQueue();

      runner.progress[task.id]!(99);
      await pumpEventQueue();

      expect(queue.tasks.single.status, TransferStatus.cancelled);
      expect(queue.tasks.single.transferredBytes, 0);
    });

    test('cancelAll stops everything in flight', () async {
      add();
      add();
      add();
      await pumpEventQueue();

      queue.cancelAll();
      await pumpEventQueue();

      expect(queue.isBusy, isFalse);
      expect(
        queue.tasks.every((t) => t.status == TransferStatus.cancelled),
        isTrue,
      );
    });

    test('cancelling a finished transfer does nothing', () async {
      final task = add();
      await pumpEventQueue();
      runner.finish(task.id);
      await pumpEventQueue();

      queue.cancel(task.id);

      expect(queue.tasks.single.status, TransferStatus.completed);
    });
  });

  group('failure and retry', () {
    test('a failure is recorded with a usable message', () async {
      final task = add();
      await pumpEventQueue();

      runner.fail(task.id, Exception('SFTP status 3: permission denied'));
      await pumpEventQueue();

      expect(queue.tasks.single.status, TransferStatus.failed);
      expect(queue.tasks.single.error, 'Permission denied.');
      expect(
        queue.tasks.single.error,
        isNot(contains('Exception')),
        reason: 'a raw exception string must never reach the user',
      );
    });

    test('retry re-queues from the beginning', () async {
      final task = add();
      await pumpEventQueue();
      runner.progress[task.id]!(50);
      runner.fail(task.id, Exception('boom'));
      await pumpEventQueue();

      queue.retry(task.id);
      await pumpEventQueue();

      expect(queue.tasks.single.status, TransferStatus.running);
      expect(queue.tasks.single.transferredBytes, 0);
      expect(queue.tasks.single.error, isNull);
      expect(runner.started.where((id) => id == task.id), hasLength(2));
    });

    test('a cancelled transfer can be retried', () async {
      final task = add();
      await pumpEventQueue();
      queue.cancel(task.id);
      await pumpEventQueue();

      queue.retry(task.id);
      await pumpEventQueue();

      expect(queue.tasks.single.status, TransferStatus.running);
    });

    test('a completed transfer cannot be retried', () async {
      final task = add();
      await pumpEventQueue();
      runner.finish(task.id);
      await pumpEventQueue();

      queue.retry(task.id);

      expect(queue.tasks.single.status, TransferStatus.completed);
    });
  });

  group('housekeeping', () {
    test('clearFinished keeps only the active transfers', () async {
      final first = add();
      add();
      await pumpEventQueue();
      runner.finish(first.id);
      await pumpEventQueue();

      queue.clearFinished();

      expect(queue.tasks, hasLength(1));
      expect(queue.tasks.single.status, TransferStatus.running);
    });

    test('disposing cancels everything in flight', () async {
      final task = add();
      await pumpEventQueue();

      queue.dispose();
      await pumpEventQueue();

      expect(runner.cancelledIds, contains(task.id));
    });
  });
}
