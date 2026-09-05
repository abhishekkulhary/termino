import 'package:flutter/material.dart';
import 'package:termino/domain/entities/transfer_task.dart';
import 'package:termino/features/sftp/application/transfer_queue.dart';
import 'package:termino/shared/design/tokens.dart';

/// A summary strip of the transfer queue, which opens the full list.
class TransferQueueBar extends StatelessWidget {
  /// Creates a bar for [queue].
  const new({required this.queue, super.key});

  /// The transfers being summarised.
  final TransferQueue queue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = queue.active.length;
    final failed = queue.tasks
        .where((task) => task.status == TransferStatus.failed)
        .length;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => TransferQueueSheet(queue: queue),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            children: [
              Icon(
                failed > 0
                    ? Icons.error_outline_rounded
                    : active > 0
                    ? Icons.sync_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: failed > 0 ? theme.colorScheme.error : null,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  active > 0
                      ? '$active transfer${active == 1 ? '' : 's'} in progress'
                      : failed > 0
                      ? '$failed transfer${failed == 1 ? '' : 's'} failed'
                      : 'Transfers complete',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.expand_less_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full transfer list, with cancel and retry.
class TransferQueueSheet extends StatelessWidget {
  /// Creates a sheet for [queue].
  const new({required this.queue, super.key});

  /// The transfers being listed.
  final TransferQueue queue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: queue,
      builder: (context, _) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    Text('Transfers', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: queue.isBusy ? queue.cancelAll : null,
                      child: const Text('Cancel all'),
                    ),
                    TextButton(
                      onPressed: queue.clearFinished,
                      child: const Text('Clear finished'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: queue.tasks.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _TransferTile(queue: queue, task: queue.tasks[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransferTile extends StatelessWidget {
  const new({required this.queue, required this.task});

  final TransferQueue queue;
  final TransferTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        task.direction == TransferDirection.download
            ? Icons.download_rounded
            : Icons.upload_rounded,
        size: 18,
      ),
      title: Text(task.filename, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xxs),
          if (!task.status.isFinished)
            // A null progress means the server did not report a size, so an
            // indeterminate bar is the honest thing to show.
            LinearProgressIndicator(value: task.progress),
          Text(
            task.error ??
                switch (task.status) {
                  TransferStatus.queued => 'Waiting',
                  TransferStatus.running => _progressText(task),
                  TransferStatus.completed => 'Done',
                  TransferStatus.cancelled => 'Cancelled',
                  TransferStatus.failed => 'Failed',
                },
            style: theme.textTheme.bodySmall?.copyWith(
              color: task.status == TransferStatus.failed
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: task.status.canRetry
          ? IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: 'Retry',
              onPressed: () => queue.retry(task.id),
            )
          : task.status.isFinished
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Cancel',
              onPressed: () => queue.cancel(task.id),
            ),
    );
  }

  static String _progressText(TransferTask task) {
    if (task.totalBytes <= 0) return '${task.transferredBytes} bytes';
    final percent = ((task.progress ?? 0) * 100).round();
    return '$percent%';
  }
}
