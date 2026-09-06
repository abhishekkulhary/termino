import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/shared/design/tokens.dart';

/// The first-run introduction.
///
/// Deliberately short, and mostly about what this device can and cannot do.
/// The one thing a new user of a terminal app needs to know immediately is
/// whether a local shell is available here — because on iOS and the web it is
/// not, and discovering that by hunting for a missing button is a bad first
/// five minutes.
class OnboardingScreen extends ConsumerWidget {
  /// Creates the introduction.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final capabilities = ref.watch(platformCapabilitiesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text('Termino', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'A terminal and SSH client.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  if (capabilities.canRunLocalShell)
                    const _Point(
                      icon: Icons.computer_rounded,
                      title: 'A shell on this device',
                      detail:
                          'Open a real shell here, with your own environment '
                          'and tools.',
                    )
                  else
                    _Point(
                      icon: Icons.info_outline_rounded,
                      title: 'No local shell here',
                      detail:
                          capabilities
                              .localShellUnavailableReason
                              ?.explanation ??
                          'This platform cannot run a local shell.',
                    ),

                  const _Point(
                    icon: Icons.dns_rounded,
                    title: 'Connect over SSH',
                    detail:
                        'Add a host, authenticate with a key or a password, '
                        'and get a real interactive shell.',
                  ),
                  const _Point(
                    icon: Icons.gpp_good_rounded,
                    title: 'Keys stay on this device',
                    detail:
                        'Private keys live in the system keystore, never in '
                        'the app database and never in a log. A host key that '
                        'changes blocks the connection.',
                  ),
                  if (capabilities.needsRelay)
                    const _Point(
                      icon: Icons.swap_horiz_rounded,
                      title: 'A relay is needed in a browser',
                      detail:
                          'Browsers cannot open network connections directly. '
                          'Set a relay address in Settings. It only forwards '
                          'encrypted bytes — it cannot read your session.',
                    ),

                  const SizedBox(height: Spacing.xl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => unawaited(
                        ref
                            .read(settingsProvider.notifier)
                            .completeOnboarding(),
                      ),
                      child: const Text('Get started'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const new({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
