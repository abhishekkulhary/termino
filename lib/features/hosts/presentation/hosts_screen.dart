import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/features/hosts/application/ssh_prompt_service.dart';
import 'package:termino/features/hosts/presentation/host_editor_screen.dart';
import 'package:termino/features/hosts/presentation/host_key_dialogs.dart';
import 'package:termino/features/hosts/presentation/last_connected_label.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/infrastructure/ssh/import/ssh_config_import.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';
import 'package:termino/shared/widgets/swipe_to_delete.dart';

/// The saved SSH connections.
class HostsScreen extends ConsumerWidget {
  /// Creates the hosts screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(sshHostsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _AddHostButton(
        onNew: () => unawaited(_edit(context, ref)),
        onImport: () => unawaited(_import(context, ref)),
      ),
      body: hosts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _Message(
          icon: Icons.error_outline_rounded,
          title: 'Could not load hosts',
          detail: 'The connection list could not be read from storage.',
        ),
        data: (list) => list.isEmpty
            ? const _Message(
                icon: Icons.dns_outlined,
                title: 'No saved hosts',
                detail:
                    'Add a connection, or import your ~/.ssh/config from '
                    'Settings.',
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: Spacing.sm, bottom: 96),
                itemCount: list.length,
                itemBuilder: (context, index) => Reveal.staggered(
                  index: index,
                  child: SwipeToDelete(
                    itemKey: ValueKey(list[index].id),
                    confirm: () => _confirmDelete(context, list[index]),
                    onDelete: () => ref
                        .read(sshHostRepositoryProvider)
                        .delete(list[index].id),
                    child: _HostCard(
                      host: list[index],
                      onConnect: () =>
                          unawaited(_connect(context, ref, list[index])),
                      onBrowse: () {
                        ref
                            .read(selectedSftpHostProvider.notifier)
                            .select(list[index]);
                        context.go(AppDestinations.files.route);
                      },
                      onTunnels: () =>
                          context.go(AppDestinations.tunnels.route),
                      onEdit: () => unawaited(_edit(context, ref, list[index])),
                      onDelete: () =>
                          unawaited(_delete(context, ref, list[index])),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Imports hosts from `~/.ssh/config`, skipping ones already saved.
  ///
  /// Read-only: Termino never writes to the user's OpenSSH files, which are
  /// shared with `ssh` itself and every other tool on the machine.
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    const importer = SshConfigImporter();

    if (!importer.isAvailable) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No ~/.ssh directory was found.')),
      );
      return;
    }

    final repository = ref.read(sshHostRepositoryProvider);
    final existing = await repository.all();
    final known = existing
        .map((host) => '${host.username}@${host.hostname}:${host.port}')
        .toSet();

    var added = 0;
    for (final entry in await importer.readConfig()) {
      if (!entry.isImportable) continue;
      final hostname = entry.hostName ?? entry.alias;
      final username = entry.user ?? '';
      final port = entry.port ?? 22;
      if (username.isEmpty) continue;
      if (!known.add('$username@$hostname:$port')) continue;

      await repository.save(
        SshHost(
          id:
              'imported-${entry.alias}-'
              '${DateTime.now().microsecondsSinceEpoch}',
          label: entry.alias,
          hostname: hostname,
          username: username,
          port: port,
          keepAliveInterval: Duration(seconds: entry.serverAliveInterval ?? 30),
          startupCommand: entry.remoteCommand,
        ),
      );
      added++;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'Nothing new to import from ~/.ssh/config.'
              : 'Imported $added ${added == 1 ? 'host' : 'hosts'}.',
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [SshHost? host]) =>
      Navigator.of(context).push<void>(
        FadeThroughPageRoute(builder: (_) => HostEditorScreen(host: host)),
      );

  Future<void> _connect(
    BuildContext context,
    WidgetRef ref,
    SshHost host,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final session = await ref
        .read(sessionLauncherProvider.notifier)
        .openSsh(host);

    final backend = session.backend;
    final failure = backend.failure;
    if (failure == null) {
      // Go to the terminal the session was just opened in. Without this the
      // user stays on the host list with nothing to show that anything
      // happened — the session exists, in a tab they were never taken to.
      if (context.mounted) context.go(AppDestinations.terminal.route);
      return;
    }

    // A refused host key is the one failure that deserves more than a banner
    // in the tab: the user needs to see both fingerprints to act on it.
    final refused = backend is SshBackend ? backend.refusedHostKey : null;
    if (failure.kind == TerminalBackendFailureKind.hostKeyMismatch &&
        refused != null) {
      await _handleMismatch(ref, host, refused);
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _handleMismatch(
    WidgetRef ref,
    SshHost host,
    HostKeyCheck refused,
  ) async {
    final choice = await ref
        .read(sshPromptServiceProvider)
        .reportHostKeyMismatch(refused);

    if (choice == HostKeyMismatchChoice.forgetStoredKey) {
      // Deliberately does not reconnect. The user has to start the connection
      // again, which then goes through the ordinary first-use prompt — so
      // accepting a new key is always a separate, conscious act.
      await ref
          .read(knownHostsRepositoryProvider)
          .remove(host: host.hostname, port: host.port);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SshHost host,
  ) async {
    if (await _confirmDelete(context, host)) {
      await ref.read(sshHostRepositoryProvider).delete(host.id);
    }
  }

  /// The one dialog, shared by the menu and the swipe.
  static Future<bool> _confirmDelete(BuildContext context, SshHost host) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${host.label}?'),
        content: const Text(
          'The connection and any password saved for it are removed. '
          'Trusted host keys are kept.',
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
}

/// Offers a new host, and — where there is a `~/.ssh` to read — an import.
class _AddHostButton extends ConsumerWidget {
  const new({required this.onNew, required this.onImport});

  final VoidCallback onNew;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(platformCapabilitiesProvider);

    if (!capabilities.canReadUserSshConfig) {
      return FloatingActionButton.extended(
        onPressed: onNew,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add host'),
      );
    }

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.add_rounded, size: 18),
          onPressed: onNew,
          child: const Text('New host'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_download_outlined, size: 18),
          onPressed: onImport,
          child: const Text('Import from ~/.ssh/config'),
        ),
      ],
      builder: (context, controller, _) => FloatingActionButton.extended(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add host'),
      ),
    );
  }
}

class _HostCard extends ConsumerWidget {
  const new({
    required this.host,
    required this.onConnect,
    required this.onBrowse,
    required this.onTunnels,
    required this.onEdit,
    required this.onDelete,
  });

  final SshHost host;
  final VoidCallback onConnect;
  final VoidCallback onBrowse;
  final VoidCallback onTunnels;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// How this host is doing right now, read from the open sessions rather than
  /// probed. A network probe would be a guess about reachability; an open
  /// session is a fact about this host.
  ConnectionHealth _health(WidgetRef ref) {
    final sessions = ref
        .watch(sessionManagerProvider)
        .sessions
        .where((session) => session.hostId == host.id);
    if (sessions.isEmpty) return ConnectionHealth.idle;

    final states = sessions.map((session) => session.connectionState.value);
    if (states.contains(BackendConnectionState.connected)) {
      return ConnectionHealth.online;
    }
    if (states.contains(BackendConnectionState.connecting)) {
      return ConnectionHealth.busy;
    }
    return ConnectionHealth.offline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = _health(ref);

    // On a phone there is not room for three buttons and a readable host name,
    // and the name is what the user came for. Browse and Tunnels move into the
    // menu rather than squeezing the label to an ellipsis.
    final roomy = Breakpoints.ofContext(context) != WindowSize.compact;

    return NeonListCard(
      icon: Icons.dns_rounded,
      accent: host.colorValue == null ? null : Color(host.colorValue!),
      status: health,
      selected: health == ConnectionHealth.online,
      title: host.label,
      subtitle: host.target,
      meta: lastConnectedLabel(host.lastConnectedAt, long: roomy),
      tags: [?host.folder, if (host.jumpHostId != null) 'via jump'],
      onTap: onConnect,
      actions: [
        NeonAction(
          icon: Icons.bolt_rounded,
          tooltip: 'Connect',
          accent: host.colorValue == null ? null : Color(host.colorValue!),
          onPressed: onConnect,
        ),
        if (roomy) ...[
          const SizedBox(width: Spacing.xs),
          NeonAction(
            icon: Icons.folder_open_rounded,
            tooltip: 'Browse files',
            onPressed: onBrowse,
          ),
          const SizedBox(width: Spacing.xs),
          NeonAction(
            icon: Icons.swap_horiz_rounded,
            tooltip: 'Port forwards',
            onPressed: onTunnels,
          ),
        ],
        _OverflowMenu(
          items: [
            if (!roomy) ...[
              (Icons.folder_open_rounded, 'Browse files', onBrowse),
              (Icons.swap_horiz_rounded, 'Port forwards', onTunnels),
            ],
            (Icons.edit_rounded, 'Edit', onEdit),
            (Icons.delete_outline_rounded, 'Delete', onDelete),
          ],
        ),
      ],
    );
  }
}

/// The "more" button every row carries.
class _OverflowMenu extends StatelessWidget {
  const new({required this.items});

  final List<(IconData, String, VoidCallback)> items;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final (icon, label, action) in items)
          MenuItemButton(
            leadingIcon: Icon(icon, size: 18),
            onPressed: action,
            child: Text(label),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.more_vert_rounded, size: 18),
        tooltip: 'More',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const new({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.lg),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
