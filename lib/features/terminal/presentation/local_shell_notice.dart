import 'package:flutter/material.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/shared/design/tokens.dart';

/// Explains, in plain language, why this platform has no local shell.
///
/// The alternative — hiding the feature, or offering a button that fails —
/// makes the app look broken or arbitrary. iOS forbidding this is a rule of the
/// platform, not a gap in Termino, and saying so directly is both more honest
/// and more useful than silence.
class LocalShellNotice extends StatelessWidget {
  /// Creates a notice explaining [reason].
  const new({required this.reason, super.key});

  /// Why the local shell is unavailable.
  final LocalShellUnavailableReason reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
                Text('No local shell here', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              reason.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
