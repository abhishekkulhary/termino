import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/identities/application/identity_service.dart';
import 'package:termino/features/identities/presentation/key_dialogs.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';
import 'package:termino/shared/widgets/swipe_to_delete.dart';

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
            : ListView.builder(
                padding: const EdgeInsets.only(top: Spacing.sm, bottom: 96),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final identity = list[index];
                  final card = _IdentityCard(identity: identity);
                  return Reveal.staggered(
                    index: index,
                    child: SwipeToDelete(
                      itemKey: ValueKey(identity.id),
                      confirm: () => card.confirmDelete(context),
                      onDelete: () =>
                          ref.read(identityServiceProvider).delete(identity.id),
                      child: card,
                    ),
                  );
                },
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

class _IdentityCard extends ConsumerWidget {
  const new({required this.identity});

  final SshIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeonListCard(
      icon: Icons.vpn_key_rounded,
      title: identity.name,
      subtitle: identity.fingerprint,
      meta: identity.comment,
      tags: [
        identity.keyType.label,
        if (identity.hasPassphrase) 'passphrase',
        if (identity.requiresBiometrics) 'biometric',
      ],
      actions: [
        NeonAction(
          icon: Icons.copy_rounded,
          tooltip: 'Copy public key',
          onPressed: () => unawaited(_copyPublicKey(context)),
        ),
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: () => unawaited(_delete(context, ref)),
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

  /// Copies the *public* key, and says so. The private half never leaves the
  /// keystore, and a control this close to one that could is worth being
  /// explicit about.
  Future<void> _copyPublicKey(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: identity.publicKey));
    messenger.showSnackBar(const SnackBar(content: Text('Public key copied.')));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (await confirmDelete(context)) {
      await ref.read(identityServiceProvider).delete(identity.id);
    }
  }

  /// The one dialog, shared by the menu and the swipe.
  Future<bool> confirmDelete(BuildContext context) async {
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

    return confirmed ?? false;
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
