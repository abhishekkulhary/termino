import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';

/// Asks the user whether to trust a host key they have not seen before.
///
/// Returns true only on an explicit accept. Dismissing the dialog any other way
/// — tapping outside, the back button, the escape key — declines, because the
/// safe answer to "should I trust this?" is no.
Future<bool> showTrustHostKeyDialog(
  BuildContext context,
  HostKeyCheck check,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => _TrustHostKeyDialog(check: check),
  );
  return accepted ?? false;
}

/// Tells the user a host key has changed, and refuses the connection.
///
/// Deliberately has no "connect anyway" button. A changed key means either the
/// server was rebuilt or someone is intercepting the connection, and nothing
/// available here can distinguish those. Replacing the stored key is a separate
/// action, reached from this dialog, that does not itself connect — so the user
/// has to come back and try again, having actually decided.
Future<HostKeyMismatchChoice> showHostKeyMismatchDialog(
  BuildContext context,
  HostKeyCheck check,
) async {
  final choice = await showDialog<HostKeyMismatchChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _HostKeyMismatchDialog(check: check),
  );
  return choice ?? HostKeyMismatchChoice.cancel;
}

/// What the user chose when told a host key had changed.
enum HostKeyMismatchChoice {
  /// Do nothing. The connection stays refused.
  cancel,

  /// Forget the stored key, having decided the server really did change.
  ///
  /// This does not connect. The user must start a new connection, which then
  /// goes through the ordinary first-use prompt.
  forgetStoredKey,
}

class _TrustHostKeyDialog extends StatelessWidget {
  const new({required this.check});

  final HostKeyCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewType = check.verdict == HostKeyVerdict.newKeyType;

    return AlertDialog(
      // Amber, not the app accent: this is a question the user has to
      // answer carefully, and the colour should say so.
      icon: Icon(Icons.shield_outlined, color: NeonAccents.of(context).busy),
      iconColor: NeonAccents.of(context).busy,
      title: Text(
        isNewType ? 'New key type for ${check.target}' : 'Unknown host',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNewType
                ? '${check.target} is already trusted, but it is now offering '
                      'a ${check.keyType} key, which you have not seen before.'
                : 'The authenticity of ${check.target} cannot be established. '
                      'This is expected the first time you connect.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.lg),
          _FingerprintBlock(
            label: '${check.keyType} fingerprint',
            fingerprint: check.fingerprint,
          ),
          if (isNewType) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'Already trusted: ${check.otherKnownTypes.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          Text(
            'Check this against the fingerprint shown on the server before '
            'accepting.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Trust and connect'),
        ),
      ],
    );
  }
}

class _HostKeyMismatchDialog extends StatelessWidget {
  const new({required this.check});

  final HostKeyCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(Icons.gpp_bad_rounded, color: theme.colorScheme.error),
      iconColor: theme.colorScheme.error,
      title: const Text('Host key has changed'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: Radii.borderSm,
              ),
              child: Text(
                'The key for ${check.target} does not match the one you '
                'trusted before. The connection was refused.\n\n'
                'This happens when a server is rebuilt — and it is also what '
                'an attacker intercepting your connection looks like. There '
                'is no way to tell the two apart from here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            _FingerprintBlock(
              label: 'Expected',
              fingerprint: check.expected?.fingerprint ?? 'unknown',
            ),
            const SizedBox(height: Spacing.sm),
            _FingerprintBlock(
              label: 'Offered now',
              fingerprint: check.fingerprint,
              emphasise: true,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'If you know the server was rebuilt, confirm the new fingerprint '
              'through a channel you trust, then forget the stored key and '
              'connect again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(HostKeyMismatchChoice.forgetStoredKey),
          child: const Text('Forget stored key'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(HostKeyMismatchChoice.cancel),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// A fingerprint, in the terminal font, with a copy button.
class _FingerprintBlock extends StatelessWidget {
  const new({
    required this.label,
    required this.fingerprint,
    this.emphasise = false,
  });

  final String label;
  final String fingerprint;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final neon = NeonAccents.of(context);
    final accent = emphasise
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        // Given its own lit panel. This string is the entire security decision
        // the dialog is asking about, and it was set in the same body text as
        // the sentence explaining it.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: emphasise ? 0.10 : 0.06),
            borderRadius: Radii.borderSm,
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: emphasise ? neon.glow(accent, blur: 12) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  groupFingerprint(fingerprint),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: Fonts.mono,
                    fontFamilyFallback: Fonts.monoFallback,
                    color: emphasise ? theme.colorScheme.error : null,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy fingerprint',
                // The clipboard gets the real string, ungrouped, because that
                // is what will be compared against a server's output.
                onPressed: () => unawaited(
                  Clipboard.setData(ClipboardData(text: fingerprint)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A fingerprint broken into blocks of four, for comparing by eye.
///
/// Forty-three unbroken base64 characters is exactly the string a person gives
/// up on halfway and accepts — which is the failure this dialog exists to
/// prevent. Grouping is what every other security surface does with a value
/// someone has to check by hand, and it costs nothing: the clipboard still
/// carries the real thing.
String groupFingerprint(String fingerprint) {
  final colon = fingerprint.indexOf(':');
  if (colon < 0) return _inFours(fingerprint);
  final prefix = fingerprint.substring(0, colon + 1);
  return '$prefix ${_inFours(fingerprint.substring(colon + 1))}';
}

String _inFours(String value) {
  final blocks = <String>[];
  for (var i = 0; i < value.length; i += 4) {
    blocks.add(value.substring(i, (i + 4).clamp(0, value.length)));
  }
  return blocks.join(' ');
}
