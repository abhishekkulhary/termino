import 'package:flutter/material.dart';
import 'package:termino/shared/design/tokens.dart';

/// A stand-in for a feature that has not been built yet.
///
/// Deliberately explicit about *which* phase delivers it. A screen that says
/// nothing is indistinguishable from one that is broken, and this app is being
/// built in public phases where the difference matters.
class ComingSoonScreen extends StatelessWidget {
  /// Creates a placeholder for [feature], arriving in [phase].
  const new({
    required this.feature,
    required this.phase,
    required this.description,
    required this.icon,
    super.key,
  });

  /// The feature's name, e.g. 'Hosts'.
  final String feature;

  /// A short description of what it will do.
  final String description;

  /// Which delivery phase brings it, e.g. 'Phase 3'.
  final String phase;

  /// The icon shown above the title.
  final IconData icon;

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
              Icon(icon, size: 44, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.lg),
              Text(feature, style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Chip(
                label: Text(phase),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
