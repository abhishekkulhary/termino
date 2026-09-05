import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/features/placeholder/coming_soon_screen.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

/// The app's routes.
///
/// A [StatefulShellRoute] keeps each branch's navigation state alive, so
/// switching to Hosts and back does not rebuild the terminal — which matters a
/// great deal when the terminal holds a live session.
GoRouter buildRouter() {
  return GoRouter(
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
                builder: (context, state) => const ComingSoonScreen(
                  feature: 'Hosts',
                  description:
                      'Saved SSH connections, folders and tags, plus import '
                      'from your ~/.ssh/config.',
                  phase: 'Phase 3',
                  icon: Icons.dns_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.keys.route,
                builder: (context, state) => const ComingSoonScreen(
                  feature: 'Keys',
                  description:
                      'Import and generate SSH keys, held in the platform '
                      'keystore behind an optional biometric gate.',
                  phase: 'Phase 3',
                  icon: Icons.vpn_key_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.files.route,
                builder: (context, state) => const ComingSoonScreen(
                  feature: 'Files',
                  description:
                      'A dual-pane SFTP browser with a transfer queue you can '
                      'pause, cancel and retry.',
                  phase: 'Phase 5',
                  icon: Icons.folder_rounded,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestinations.settings.route,
                builder: (context, state) => const ComingSoonScreen(
                  feature: 'Settings',
                  description:
                      'Themes, fonts, keybindings and behaviour — including '
                      'the terminal palettes and scrollback size.',
                  phase: 'Phase 6',
                  icon: Icons.settings_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Shell extends StatelessWidget {
  const new({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: AppDestinations.all,
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
      title: Text(AppDestinations.all[shell.currentIndex].label),
      body: shell,
    );
  }
}
