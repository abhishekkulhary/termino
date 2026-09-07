import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/command_palette/presentation/command_palette.dart';
import 'package:termino/features/desktop/presentation/app_shortcuts.dart';
import 'package:termino/features/forwarding/presentation/forwarding_screen.dart';
import 'package:termino/features/hosts/application/ssh_prompt_service.dart';
import 'package:termino/features/hosts/presentation/hosts_screen.dart';
import 'package:termino/features/identities/presentation/identities_screen.dart';
import 'package:termino/features/settings/presentation/settings_screen.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/sftp/presentation/sftp_screen.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';
import 'package:termino/shared/widgets/neon.dart';

/// The app's routes.
///
/// A [StatefulShellRoute] keeps each branch's navigation state alive, so
/// switching to Hosts and back does not rebuild the terminal — which matters a
/// great deal when the terminal holds a live session.
GoRouter buildRouter() {
  return GoRouter(
    // Shared so that a connection, which has no BuildContext of its own, can
    // still show a host key prompt.
    navigatorKey: rootNavigatorKey,
    initialLocation: AppDestinations.terminal.route,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.terminal.route,
                builder: (context, state) => const TerminalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.hosts.route,
                builder: (context, state) => const HostsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.keys.route,
                builder: (context, state) => const IdentitiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.files.route,
                builder: (context, state) => const SftpScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.tunnels.route,
                builder: (context, state) => const ForwardingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.settings.route,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Shell extends ConsumerWidget {
  const new({required this.shell});

  final StatefulNavigationShell shell;

  /// What each destination should wear right now.
  ///
  /// Read here rather than inside the scaffold: the shell is the only place
  /// that knows about both the navigation and the application's state, and the
  /// scaffold stays a widget that renders what it is told.
  Widget? _badgeFor(WidgetRef ref, AppDestination destination) {
    if (destination.route == AppDestinations.terminal.route) {
      final sessions = ref.watch(sessionManagerProvider).sessions;
      final connecting = sessions.any(
        (session) =>
            session.connectionState.value == BackendConnectionState.connecting,
      );
      return NeonBadge(
        count: sessions.length,
        pulse: connecting,
        accent: connecting ? NeonAccents.of(ref.context).busy : null,
      );
    }

    if (destination.route == AppDestinations.files.route) {
      final queue = ref.watch(sftpSessionProvider).value?.queue;
      final running = queue?.active.length ?? 0;
      return NeonBadge(
        count: running,
        pulse: running > 0,
        accent: NeonAccents.of(ref.context).busy,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bound at the shell rather than per screen so the palette is reachable
    // from anywhere, including while a terminal has the keyboard. The terminal
    // sees every other keystroke; this is the one combination the app keeps.
    return CallbackShortcuts(
      bindings: {
        AppShortcuts.palette: () => unawaited(showCommandPalette(context)),
        AppShortcuts.newSession: () => context.go(AppDestinations.hosts.route),
        AppShortcuts.closeSession: () {
          final sessions = ref.read(sessionManagerProvider);
          final active = sessions.activeId;
          if (active != null) {
            unawaited(ref.read(sessionManagerProvider.notifier).close(active));
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: AdaptiveScaffold(
          destinations: AppDestinations.all,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          title: Text(AppDestinations.all[shell.currentIndex].label),
          badgeFor: (destination) => _badgeFor(ref, destination),
          actions: [
            _PaletteButton(onPressed: () => showCommandPalette(context)),
            const SizedBox(width: Spacing.sm),
          ],
          body: shell,
        ),
      ),
    );
  }
}

/// The palette's affordance in the top bar.
///
/// A keyboard shortcut nobody knows about is a feature nobody has. This shows
/// both that the palette exists and how to open it without the mouse.
class _PaletteButton extends StatelessWidget {
  const new({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);

    // A phone has no Ctrl key and no Cmd key, so naming one is telling the
    // user to press something they do not have. The palette is still there,
    // still reachable, and on a touch device it is a button.
    final showShortcut = Breakpoints.ofContext(context) != WindowSize.compact;

    return Tooltip(
      message: 'Command palette',
      child: InkWell(
        onTap: () => unawaited(onPressed()),
        borderRadius: Radii.borderSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: Radii.borderSm,
            border: Border.all(color: neon.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              if (showShortcut) ...[
                const SizedBox(width: Spacing.sm),
                Text(
                  commandPaletteHint(context),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
