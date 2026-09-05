import 'package:flutter/material.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

/// The app's primary navigation, in order.
///
/// Everything but the terminal is a placeholder until its phase lands. They are
/// listed now rather than added later so the shell's layout is exercised — and
/// judged — at full width from the start.
abstract final class AppDestinations {
  /// The terminal workspace.
  static const terminal = AppDestination(
    label: 'Terminal',
    icon: Icons.terminal_outlined,
    selectedIcon: Icons.terminal_rounded,
    route: '/',
  );

  /// Saved SSH connections. Phase 3.
  static const hosts = AppDestination(
    label: 'Hosts',
    icon: Icons.dns_outlined,
    selectedIcon: Icons.dns_rounded,
    route: '/hosts',
  );

  /// SSH keys and identities. Phase 3.
  static const keys = AppDestination(
    label: 'Keys',
    icon: Icons.vpn_key_outlined,
    selectedIcon: Icons.vpn_key_rounded,
    route: '/keys',
  );

  /// The SFTP browser. Phase 5.
  static const files = AppDestination(
    label: 'Files',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    route: '/files',
  );

  /// Settings. Phase 6.
  static const settings = AppDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: '/settings',
  );

  /// Every destination, in navigation order.
  static const all = <AppDestination>[terminal, hosts, keys, files, settings];
}
