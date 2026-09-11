import 'package:flutter/material.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

/// The app's primary navigation, in order.
///
/// One list, consulted by the bottom bar, the rail and the sidebar alike, so a
/// destination cannot exist at one window size and not another.
abstract final class AppDestinations {
  /// The terminal workspace.
  static const terminal = AppDestination(
    label: 'Terminal',
    icon: Icons.terminal_outlined,
    selectedIcon: Icons.terminal_rounded,
    route: '/',
  );

  /// Saved SSH connections.
  static const hosts = AppDestination(
    label: 'Hosts',
    icon: Icons.dns_outlined,
    selectedIcon: Icons.dns_rounded,
    route: '/hosts',
  );

  /// SSH keys and identities.
  static const keys = AppDestination(
    label: 'Keys',
    icon: Icons.vpn_key_outlined,
    selectedIcon: Icons.vpn_key_rounded,
    route: '/keys',
  );

  /// The SFTP browser.
  static const files = AppDestination(
    label: 'Files',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    route: '/files',
  );

  /// Port forwarding.
  static const tunnels = AppDestination(
    label: 'Tunnels',
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz_rounded,
    route: '/tunnels',
  );

  /// Settings.
  static const settings = AppDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: '/settings',
  );

  /// Every destination, in navigation order.
  static const all = <AppDestination>[
    terminal,
    hosts,
    keys,
    files,
    tunnels,
    settings,
  ];
}
