import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/identities/application/identity_service.dart';
import 'package:termino/features/identities/presentation/key_dialogs.dart';
import 'package:termino/shared/design/tokens.dart';

/// The user's SSH keys.
class IdentitiesScreen extends ConsumerWidget {
  /// Creates the identities screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identities = ref.watch(sshIdentitiesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: const _AddKeyButton(),
      body: identities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load keys')),
        data: (list) => list.isEmpty
            ? const _EmptyKeys()
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _IdentityTile(identity: list[index]),
              ),
      ),
    );
  }
}

class _AddKeyButton extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.auto_awesome_rounded, size: 18),
          onPressed: () => unawaited(showGenerateKeyDialog(context, ref)),
          child: const Text('Generate a key'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_upload_outlined, size: 18),
          onPressed: () => unawaited(showImportKeyDialog(context, ref)),
          child: const Text('Import a key'),
        ),
      ],
      builder: (context, controller, _) => FloatingActionButton.extended(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add key'),
      ),
    );
  }
}

class _IdentityTile extends ConsumerWidget {
  const new({required this.identity});

  final SshIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.vpn_key_rounded, size: 18)),
      title: Row(
        children: [
          Flexible(child: Text(identity.name)),
          const SizedBox(width: Spacing.sm),
          Chip(
            label: Text(identity.keyType.label),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelStyle: theme.textTheme.labelSmall,
          ),
          if (identity.hasPassphrase) ...[
            const SizedBox(width: Spacing.xs),
            Tooltip(
              message: 'Encrypted with a passphrase',
              child: Icon(
                Icons.lock_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        identity.fingerprint,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: Fonts.mono,
          fontFamilyFallback: Fonts.monoFallback,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () => unawaited(
              Clipboard.setData(ClipboardData(text: identity.publicKey)),
            ),
            child: const Text('Copy public key'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: () => unawaited(_confirmDelete(context, ref)),
            child: const Text('Delete'),
          ),
        ],
        builder: (context, controller, _) => IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${identity.name}?'),
        content: const Text(
          'The private key is removed from this device permanently. Any host '
          'set to use it will fall back to another method.',
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

    if (confirmed ?? false) {
      await ref.read(identityServiceProvider).delete(identity.id);
    }
  }
}

class _EmptyKeys extends StatelessWidget {
  const new();

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
              Icon(
                Icons.vpn_key_outlined,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text('No keys yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Generate an Ed25519 key, or import one you already use. '
                'Private keys are held in this device’s keystore and '
                'never leave it.',
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
