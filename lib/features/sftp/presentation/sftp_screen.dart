import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/sftp/application/sftp_session.dart';
import 'package:termino/features/sftp/presentation/transfer_queue_sheet.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/reveal.dart';

/// The remote file browser.
class SftpScreen extends ConsumerWidget {
  /// Creates the file browser.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(selectedSftpHostProvider);
    if (host == null) return const _HostPicker();

    final session = ref.watch(sftpSessionProvider);

    return session.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ConnectionError(
        host: host,
        reason: error is TerminalBackendFailure ? error.message : null,
        onBack: () => ref.read(selectedSftpHostProvider.notifier).select(null),
      ),
      data: (session) =>
          session == null ? const _HostPicker() : _Browser(session: session),
    );
  }
}

class _HostPicker extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(sshHostsProvider).value ?? const <SshHost>[];
    final theme = Theme.of(context);

    if (hosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text('No hosts to browse', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Add a connection under Hosts first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: hosts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.dns_rounded, size: 18)),
        title: Text(hosts[index].label),
        subtitle: Text(hosts[index].target),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () =>
            ref.read(selectedSftpHostProvider.notifier).select(hosts[index]),
      ),
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const new({required this.host, required this.onBack, this.reason});

  final SshHost host;

  /// What actually went wrong, from the failure taxonomy. Null only when the
  /// error escaped classification, which is a bug rather than a normal case.
  final String? reason;

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Could not open ${host.label}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              reason ??
                  'The connection failed or was refused. Check the host '
                      'under Hosts, then try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton(onPressed: onBack, child: const Text('Choose a host')),
          ],
        ),
      ),
    );
  }
}

class _Browser extends ConsumerWidget {
  const new({required this.session});

  final SftpSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _PathBar(session: session, ref: ref),
              if (session.error case final message?)
                MaterialBanner(
                  content: Text(message),
                  backgroundColor: theme.colorScheme.errorContainer,
                  actions: [
                    TextButton(
                      onPressed: () => unawaited(session.refresh()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              if (session.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: session.entries.isEmpty && !session.isLoading
                    ? Center(
                        child: Text(
                          'This directory is empty',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: session.entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => Reveal.staggered(
                          index: index,
                          child: _EntryTile(
                            session: session,
                            entry: session.entries[index],
                          ),
                        ),
                      ),
              ),
              if (session.queue.tasks.isNotEmpty)
                TransferQueueBar(queue: session.queue),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Upload a file',
            onPressed: () => unawaited(_upload(context)),
            child: const Icon(Icons.upload_rounded),
          ),
        );
      },
    );
  }

  Future<void> _upload(BuildContext context) async {
    // Captured before the first await: the widget may be gone by the time the
    // user has finished choosing a file.
    final messenger = ScaffoldMessenger.of(context);

    try {
      // file_picker 12 returns the files directly rather than a result object,
      // and it returns every file the user selected — all of them are queued,
      // rather than a multiple selection quietly uploading nothing.
      final picked = await FilePicker.pickFiles();
      final paths = picked
          .map((file) => file.path)
          .whereType<String>()
          .toList();
      if (paths.isEmpty) return;

      for (final path in paths) {
        await session.upload(path);
      }
    } on Object catch (error, stackTrace) {
      // This ran unguarded until a macOS entitlement made the picker throw:
      // the button did nothing, reported nothing, and the exception went to a
      // console the user was never going to read. The detail belongs in the
      // log; the user gets a sentence.
      Loggers.session.warning(
        'Choosing a file to upload failed.',
        error,
        stackTrace,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('That file could not be opened.')),
      );
    }
  }
}

class _PathBar extends StatelessWidget {
  const new({required this.session, required this.ref});

  final SftpSession session;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded),
            tooltip: 'Parent directory',
            onPressed: session.canGoUp ? () => unawaited(session.goUp()) : null,
          ),
          Expanded(
            child: Text(
              session.path,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: Fonts.mono,
                fontFamilyFallback: Fonts.monoFallback,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              session.showHidden
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            tooltip: session.showHidden ? 'Hide dotfiles' : 'Show dotfiles',
            onPressed: session.toggleHidden,
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New folder',
            onPressed: () => unawaited(_newFolder(context)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => unawaited(session.refresh()),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Disconnect',
            onPressed: () =>
                ref.read(selectedSftpHostProvider.notifier).select(null),
          ),
        ],
      ),
    );
  }

  Future<void> _newFolder(BuildContext context) async {
    final name = await _promptForName(context, title: 'New folder');
    if (name == null || name.isEmpty) return;
    await session.makeDirectory(name);
  }
}

class _EntryTile extends StatelessWidget {
  const new({required this.session, required this.entry});

  final SftpSession session;
  final RemoteEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Icon(
        entry.isDirectory
            ? Icons.folder_rounded
            : entry.isLink
            ? Icons.link_rounded
            : Icons.insert_drive_file_outlined,
        color: entry.isDirectory ? theme.colorScheme.primary : null,
      ),
      title: Text(entry.name),
      subtitle: Text(
        [
          if (!entry.isDirectory) _formatSize(entry.size),
          if (entry.modeString != null) entry.modeString!,
        ].join('  ·  '),
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: Fonts.mono,
          fontFamilyFallback: Fonts.monoFallback,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: entry.isDirectory
          ? () => unawaited(session.open(entry.path))
          : null,
      trailing: MenuAnchor(
        menuChildren: [
          if (!entry.isDirectory)
            MenuItemButton(
              leadingIcon: const Icon(Icons.download_rounded, size: 18),
              onPressed: () => unawaited(_download(context)),
              child: const Text('Download'),
            ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.drive_file_rename_outline, size: 18),
            onPressed: () => unawaited(_rename(context)),
            child: const Text('Rename'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.lock_outline_rounded, size: 18),
            onPressed: () => unawaited(_chmod(context)),
            child: const Text('Permissions'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: () => unawaited(_delete(context)),
            child: const Text('Delete'),
          ),
        ],
        builder: (context, controller, _) => IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 18),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    session.download(entry, '${directory.path}/${entry.name}');
  }

  Future<void> _rename(BuildContext context) async {
    final name = await _promptForName(
      context,
      title: 'Rename',
      initial: entry.name,
    );
    if (name == null || name.isEmpty || name == entry.name) return;
    await session.rename(entry, name);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entry.name}?'),
        content: Text(
          entry.isDirectory
              ? 'The directory must already be empty. This cannot be undone.'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await session.delete(entry);
  }

  Future<void> _chmod(BuildContext context) async {
    final octal = await _promptForName(
      context,
      title: 'Permissions',
      initial: (entry.mode ?? 0).toRadixString(8).padLeft(3, '0'),
      helper: 'Octal, such as 644 or 755',
    );
    final mode = int.tryParse(octal ?? '', radix: 8);
    if (mode == null) return;
    await session.chmod(entry, mode);
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(1)} ${units[unit]}';
  }
}

Future<String?> _promptForName(
  BuildContext context, {
  required String title,
  String initial = '',
  String? helper,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Name', helperText: helper),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
