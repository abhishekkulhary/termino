import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/sftp/application/download_destination.dart';
import 'package:termino/features/sftp/application/folder_transfer.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/sftp/application/sftp_session.dart';
import 'package:termino/features/sftp/presentation/transfer_queue_sheet.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';
import 'package:termino/shared/widgets/swipe_to_delete.dart';

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
                        itemBuilder: (context, index) {
                          final entry = session.entries[index];
                          final tile = _EntryTile(
                            session: session,
                            entry: entry,
                          );
                          return Reveal.staggered(
                            index: index,
                            child: SwipeToDelete(
                              // Dense, so the revealed panel lines up with a
                              // file row rather than a host card.
                              dense: true,
                              itemKey: ValueKey(entry.path),
                              confirm: () => tile.confirmDelete(context),
                              onDelete: () => session.delete(entry),
                              child: tile,
                            ),
                          );
                        },
                      ),
              ),
              if (session.queue.tasks.isNotEmpty)
                TransferQueueBar(queue: session.queue),
            ],
          ),
          floatingActionButton: MenuAnchor(
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.insert_drive_file_outlined),
                onPressed: () => unawaited(_upload(context)),
                child: const Text('Upload files…'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.folder_outlined),
                onPressed: () => unawaited(_uploadFolder(context)),
                child: const Text('Upload a folder…'),
              ),
            ],
            builder: (context, controller, _) => FloatingActionButton(
              tooltip: 'Upload',
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: const Icon(Icons.upload_rounded),
            ),
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

  Future<void> _uploadFolder(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final chosen = await FilePicker.getDirectoryPath(
        dialogTitle: 'Choose a folder to upload',
      );
      if (chosen == null) return;

      final plan = await session.uploadFolder(chosen);
      if (plan == null) return;
      messenger.showSnackBar(SnackBar(content: Text(describePlan(plan))));
    } on Object catch (error, stackTrace) {
      Loggers.session.warning(
        'Choosing a folder to upload failed.',
        error,
        stackTrace,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('That folder could not be opened.')),
      );
    }
  }
}

/// One line saying what a folder transfer is about to do.
///
/// It says how much, and it says what it left out. A transfer that quietly
/// skipped things would look like one that had finished.
String describePlan(TransferPlan plan) {
  if (plan.isEmpty) return 'That folder is empty.';

  final count = plan.files.length;
  final buffer = StringBuffer(
    count == 1
        ? '1 file queued'
        : '$count files queued (${_formatSize(plan.totalBytes)})',
  );

  if (plan.skippedLinks > 0) {
    buffer.write(
      plan.skippedLinks == 1
          ? ', 1 symbolic link skipped'
          : ', ${plan.skippedLinks} symbolic links skipped',
    );
  }
  if (plan.truncated) {
    buffer.write(', stopped at ${FolderTransfer.defaultMaxEntries} files');
  }
  return '$buffer.';
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
            icon: const Icon(Icons.terminal_rounded),
            // Free, now that both sit on one connection: the shell opens on
            // the connection this browser already authenticated.
            tooltip: 'Open a shell on this host',
            onPressed: () => unawaited(_openShell(context, ref)),
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

  /// Opens a terminal on the host being browsed.
  Future<void> _openShell(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionLauncherProvider.notifier).openSsh(session.host);
    if (context.mounted) context.go(AppDestinations.terminal.route);
  }

  Future<void> _newFolder(BuildContext context) async {
    final name = await _promptForName(context, title: 'New folder');
    if (name == null || name.isEmpty) return;
    await session.makeDirectory(name);
  }
}

class _EntryTile extends ConsumerWidget {
  const new({required this.session, required this.entry});

  final SftpSession session;
  final RemoteEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return NeonListCard(
      // Dense: a directory can be hundreds of rows, and a comfortable card
      // would mean scrolling past four files a screen. Same shapes, same
      // marks, tighter.
      dense: true,
      icon: entry.isDirectory
          ? Icons.folder_rounded
          : entry.isLink
          ? Icons.link_rounded
          : Icons.insert_drive_file_outlined,
      accent: entry.isDirectory
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      title: entry.name,
      subtitle: [
        if (!entry.isDirectory) _formatSize(entry.size),
        ?entry.modeString,
      ].join('  ·  '),
      onTap: entry.isDirectory
          ? () => unawaited(session.open(entry.path))
          : null,
      actions: [
        NeonAction(
          icon: Icons.download_rounded,
          tooltip: entry.isDirectory ? 'Download folder' : 'Download',
          onPressed: () => unawaited(_download(context, ref)),
        ),
        MenuAnchor(
          menuChildren: [
            if (ref.watch(platformCapabilitiesProvider).canChooseFolders)
              MenuItemButton(
                leadingIcon: const Icon(Icons.folder_open_rounded, size: 18),
                onPressed: () =>
                    unawaited(_download(context, ref, alwaysAsk: true)),
                child: const Text('Download to…'),
              ),
            MenuItemButton(
              leadingIcon: const Icon(
                Icons.drive_file_rename_outline,
                size: 18,
              ),
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
            tooltip: 'More',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
      ],
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref, {
    bool alwaysAsk = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final destination = await downloadDestination(ref).resolve(
      ref.read(currentSettingsProvider).downloadDirectory,
      alwaysAsk: alwaysAsk,
    );
    // Null means the chooser was dismissed. Falling back to somewhere
    // arbitrary would be answering a question the user declined to answer.
    if (destination == null) return;

    if (!entry.isDirectory) {
      session.download(entry, '$destination/${entry.name}');
      messenger.showSnackBar(
        SnackBar(content: Text('Saving to $destination.')),
      );
      return;
    }

    final plan = await session.downloadFolder(entry, destination);
    if (plan == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${describePlan(plan)} Saving to $destination.')),
    );
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
    if (await confirmDelete(context)) await session.delete(entry);
  }

  /// The one dialog, shared by the menu and the swipe.
  Future<bool> confirmDelete(BuildContext context) async {
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
    return confirmed ?? false;
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
}

String _formatSize(int bytes) {
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

/// The download destination resolver, wired to the real picker and settings.
DownloadDestination downloadDestination(WidgetRef ref) => DownloadDestination(
  canChoose: ref.read(platformCapabilitiesProvider).canChooseFolders,
  appFolder: () async => (await getApplicationDocumentsDirectory()).path,
  chooseFolder: () =>
      FilePicker.getDirectoryPath(dialogTitle: 'Choose where to save'),
  directoryExists: (path) {
    // A remembered folder can be on a disk that is no longer mounted, and the
    // browser has no filesystem at all — either way the answer is "no, ask
    // again", not an exception out of a build callback.
    try {
      return Directory(path).existsSync();
    } on Object {
      return false;
    }
  },
  remember: (path) =>
      ref.read(settingsProvider.notifier).setDownloadDirectory(path),
);
