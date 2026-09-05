import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/identities/application/identity_service.dart';
import 'package:termino/shared/design/tokens.dart';

/// Generates a new key, asking for a name, an algorithm and a passphrase.
Future<void> showGenerateKeyDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(context: context, builder: (_) => const _GenerateDialog());

/// Imports an existing private key pasted as text.
Future<void> showImportKeyDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(context: context, builder: (_) => const _ImportDialog());

class _GenerateDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends ConsumerState<_GenerateDialog> {
  final _name = TextEditingController();
  final _passphrase = TextEditingController();
  SshKeyType _keyType = SshKeyType.ed25519;
  var _remember = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _passphrase
      ..clear()
      ..dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // RSA-4096 takes a few seconds; the dialog shows progress rather than
      // appearing to hang.
      await ref
          .read(identityServiceProvider)
          .generate(
            name: _name.text.trim(),
            keyType: _keyType,
            passphrase: _passphrase.text.isEmpty ? null : _passphrase.text,
            rememberPassphrase: _remember,
          );
      navigator.pop();
    } on Object {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('The key could not be generated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate a key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: Spacing.lg),
            SegmentedButton<SshKeyType>(
              segments: const [
                ButtonSegment(
                  value: SshKeyType.ed25519,
                  label: Text('Ed25519'),
                ),
                ButtonSegment(value: SshKeyType.rsa, label: Text('RSA 4096')),
              ],
              selected: {_keyType},
              onSelectionChanged: _busy
                  ? null
                  : (selection) => setState(() => _keyType = selection.first),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              _keyType == SshKeyType.ed25519
                  ? 'Ed25519 is the right default: small, fast, and with no '
                        'parameters to get wrong.'
                  : 'RSA 4096 is for servers too old to accept Ed25519. '
                        'Generating it takes a few seconds.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _passphrase,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Passphrase (optional)',
                helperText: 'Encrypts the key on top of the device keystore',
              ),
            ),
            CheckboxListTile(
              value: _remember,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _remember = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Remember the passphrase'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _generate,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}

class _ImportDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<_ImportDialog> {
  final _name = TextEditingController();
  final _pem = TextEditingController();
  final _passphrase = TextEditingController();
  var _remember = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final controller in [_pem, _passphrase]) {
      controller
        ..clear()
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _import() async {
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(identityServiceProvider)
          .import(
            name: _name.text.trim().isEmpty
                ? 'Imported key'
                : _name.text.trim(),
            pem: _pem.text,
            passphrase: _passphrase.text.isEmpty ? null : _passphrase.text,
            rememberPassphrase: _remember,
          );
      navigator.pop();
    } on KeyImportException catch (failure) {
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import a key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _pem,
              maxLines: 6,
              minLines: 4,
              autocorrect: false,
              style: const TextStyle(
                fontFamily: Fonts.mono,
                fontFamilyFallback: Fonts.monoFallback,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                labelText: 'Private key',
                hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _passphrase,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase (if the key has one)',
              ),
            ),
            CheckboxListTile(
              value: _remember,
              onChanged: (value) => setState(() => _remember = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Remember the passphrase'),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _import, child: const Text('Import')),
      ],
    );
  }
}
