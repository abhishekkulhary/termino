import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/features/hosts/presentation/host_key_dialogs.dart';
import 'package:termino/features/hosts/presentation/last_connected_label.dart';
import 'package:termino/features/known_hosts/application/known_hosts_controller.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/grid_backdrop.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';
import 'package:termino/shared/widgets/swipe_to_delete.dart';

/// The host keys this app has accepted.
///
/// Until now a key could be trusted and never reviewed: the only way to forget
/// one was to meet the mismatch dialog, which means something had already gone
/// wrong. Being able to see what you have accepted — and drop it — is the
/// other half of taking host key verification seriously.
class KnownHostsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(trustedHostKeysProvider);
    final canImport = ref
        .watch(platformCapabilitiesProvider)
        .canReadUserSshConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted host keys'),
        actions: [
          if (canImport)
            TextButton.icon(
              onPressed: () => unawaited(_import(context, ref)),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Import'),
            ),
          const SizedBox(width: Spacing.sm),
        ],
      ),
      body: GridBackdrop(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const _Message(
            icon: Icons.error_outline_rounded,
            title: 'Could not load trusted keys',
            detail: 'The list could not be read from storage.',
          ),
          data: (list) => list.isEmpty
              ? const _Message(
                  icon: Icons.verified_user_outlined,
                  title: 'Nothing trusted yet',
                  detail:
                      'A host key is recorded here the first time you accept '
                      'it. Nothing is trusted until you say so.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    top: Spacing.sm,
                    bottom: Spacing.xxl,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final entry = list[index];
                    return Reveal.staggered(
                      index: index,
                      child: SwipeToDelete(
                        itemKey: ValueKey('${entry.hostPort}-${entry.keyType}'),
                        label: 'Forget',
                        confirm: () => _confirmForget(context, entry),
                        onDelete: () => ref
                            .read(knownHostsControllerProvider.notifier)
                            .forget(entry),
                        child: _KnownHostCard(entry: entry),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await ref
        .read(knownHostsControllerProvider.notifier)
        .importFromOpenSsh();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'Nothing new to import. Only keys for hosts saved here are '
                    'brought across.'
              : 'Imported $added host '
                    '${added == 1 ? 'key' : 'keys'} from ~/.ssh/known_hosts.',
        ),
      ),
    );
  }

  static Future<bool> _confirmForget(
    BuildContext context,
    KnownHost entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forget ${entry.hostPort}?'),
        content: const Text(
          'The next connection to this host is treated as a first sighting '
          'and asks you to check its fingerprint again. Nothing on the server '
          'is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _KnownHostCard extends StatelessWidget {
  const new({required this.entry});

  final KnownHost entry;

  @override
  Widget build(BuildContext context) {
    return NeonListCard(
      icon: Icons.verified_user_outlined,
      title: entry.hostPort,
      // Grouped, as in the dialogs: this is the same value, and it is checked
      // the same way.
      subtitle: groupFingerprint(entry.fingerprint),
      meta: lastConnectedLabel(
        entry.addedAt,
        long: true,
      ).replaceFirst('Connected', 'Trusted'),
      tags: [entry.keyType, entry.source.label],
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
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
