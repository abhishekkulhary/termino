import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/throughput_meter.dart';
import 'package:termino/features/terminal/application/transfer_controller.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';

/// The ZModem prompt and progress strip, drawn over the terminal it belongs to.
///
/// Deliberately in the terminal rather than in a modal dialog. A transfer is
/// something the shell started — the user typed `sz report.pdf` — and the
/// answer belongs next to the command that caused it. A dialog would also hide
/// the output that explains why the prompt appeared.
///
/// Nothing is shown unless this pane's session is the one being asked, so a
/// transfer running in a background tab does not interrupt work in the front
/// one.
class TransferOverlay extends ConsumerWidget {
  /// Creates the overlay for the session with [sessionId].
  const new({required this.sessionId, super.key});

  /// Which session's transfers to show.
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    if (state.isIdle || state.sessionId != sessionId) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(transferControllerProvider.notifier);
    final child = switch (state) {
      TransferState(request: final IncomingRequest offer) => _Offer(
        key: const ValueKey('transfer-offer'),
        request: offer,
        onAccept: () => unawaited(controller.accept()),
        onDecline: controller.decline,
      ),
      TransferState(request: final OutgoingRequest _) => _Pick(
        key: const ValueKey('transfer-pick'),
        onPicked: (paths) => unawaited(controller.send(paths)),
      ),
      TransferState(progress: final progress?) => _Progress(
        key: const ValueKey('transfer-progress'),
        progress: progress,
        onCancel: () => unawaited(_cancel(ref)),
      ),
      TransferState(completed: final completed?) => _Done(
        key: const ValueKey('transfer-done'),
        progress: completed,
        onDismiss: controller.dismiss,
      ),
      TransferState(error: final message?) => _Failed(
        key: const ValueKey('transfer-error'),
        message: message,
        onDismiss: controller.dismiss,
      ),
      _ => const SizedBox.shrink(),
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedSwitcher(duration: Motion.normal, child: child),
        ),
      ),
    );
  }

  /// Stops a transfer at both ends.
  ///
  /// The far end has to be told, or it sits waiting for bytes that are not
  /// coming and the session keeps diverting every keystroke into it.
  Future<void> _cancel(WidgetRef ref) async {
    final sessions = ref.read(sessionManagerProvider).sessions;
    for (final session in sessions) {
      if (session.id == sessionId) await session.zmodem?.abort();
    }
    await ref.read(transferControllerProvider.notifier).abort();
  }
}

class _Offer extends StatelessWidget {
  const new({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final IncomingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = request.file.size;

    return NeonPanel(
      accent: theme.colorScheme.primary,
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const NeonSectionLabel('Incoming file'),
          const SizedBox(height: Spacing.sm),
          Text(
            // The name comes from the remote machine, so it is shown as the
            // remote machine's claim about it — and it is `safeName`, the one
            // that will actually be written, not the raw path it sent.
            request.file.safeName,
            style: theme.textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            size > 0
                ? '${formatBytes(size)} offered by the host you are '
                      'connected to'
                : 'Offered by the host you are connected to',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDecline, child: const Text('Decline')),
              const SizedBox(width: Spacing.sm),
              FilledButton(onPressed: onAccept, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  const new({required this.onPicked, super.key});

  final void Function(List<String> paths) onPicked;

  Future<void> _choose() async {
    final picked = await FilePicker.pickFiles();
    onPicked([for (final file in picked) ?file.path]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeonPanel(
      accent: theme.colorScheme.primary,
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const NeonSectionLabel('Waiting for files'),
          const SizedBox(height: Spacing.sm),
          Text(
            'The host is running rz and is ready to receive.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => onPicked(const []),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton(
                onPressed: () => unawaited(_choose()),
                child: const Text('Choose files'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const new({required this.progress, required this.onCancel, super.key});

  final TransferProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);

    return NeonPanel(
      accent: theme.colorScheme.primary,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                progress.incoming ? Icons.south_east : Icons.north_east,
                size: 16,
                color: neon.readable(theme.colorScheme.primary),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  progress.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                progress.total > 0
                    ? '${formatBytes(progress.bytes)}'
                          ' / ${formatBytes(progress.total)}'
                    : formatBytes(progress.bytes),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: Spacing.xs),
              NeonAction(
                icon: Icons.stop_circle_outlined,
                tooltip: 'Cancel transfer',
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: Radii.borderXs,
            // Null shows an indeterminate bar, which is the honest rendering
            // when the far end never said how big the file is.
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const new({required this.progress, required this.onDismiss, super.key});

  final TransferProgress progress;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final path = progress.path;

    return NeonPanel(
      accent: neon.online,
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: neon.online),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  progress.incoming
                      ? 'Saved ${progress.name}'
                      : 'Sent ${progress.name}',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                // Where it went, because a received file nobody can find has
                // not really been received.
                if (path != null)
                  Text(
                    path,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          NeonAction(
            icon: Icons.close,
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const new({required this.message, required this.onDismiss, super.key});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeonPanel(
      accent: theme.colorScheme.error,
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: NeonAccents.of(context).readable(theme.colorScheme.error),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          NeonAction(
            icon: Icons.close,
            tooltip: 'Dismiss',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
