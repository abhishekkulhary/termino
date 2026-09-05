import 'package:flutter/material.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/design/tokens.dart';

/// One entry in the app's primary navigation.
class AppDestination {
  /// Creates a destination.
  const new({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.enabled = true,
    this.disabledReason,
  });

  /// Shown beside the icon in a rail or sidebar, and beneath it in a bar.
  final String label;

  /// The icon when unselected.
  final IconData icon;

  /// The icon when selected.
  final IconData selectedIcon;

  /// The route this destination navigates to.
  final String route;

  /// Whether this destination is available on this platform.
  ///
  /// Feature gating is data, not a widget-level `Platform.isX` check: the
  /// capability service decides, and the navigation simply renders what it is
  /// told. A disabled destination stays visible with an explanation rather than
  /// vanishing, so the app never looks broken or arbitrarily different.
  final bool enabled;

  /// Why this destination is unavailable, shown as a tooltip when [enabled] is
  /// false.
  final String? disabledReason;
}

/// The app shell: bottom navigation on phones, a rail on medium windows, and a
/// persistent sidebar on desktop.
///
/// The [body] is always the hero. Chrome shrinks before the content does.
class AdaptiveScaffold extends StatelessWidget {
  /// Creates the shell.
  const new({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    super.key,
    this.title,
    this.actions,
  });

  /// The primary navigation entries.
  final List<AppDestination> destinations;

  /// Which destination is currently shown.
  final int selectedIndex;

  /// Called with the index of a destination the user chose. Disabled
  /// destinations never call this.
  final ValueChanged<int> onDestinationSelected;

  /// The content.
  final Widget body;

  /// Optional title, shown only where there is room for a top bar.
  final Widget? title;

  /// Optional actions for the top bar.
  final List<Widget>? actions;

  void _select(int index) {
    if (!destinations[index].enabled) return;
    onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final size = Breakpoints.ofContext(context);

    return switch (size) {
      WindowSize.compact => _buildCompact(context),
      WindowSize.medium => _buildWithRail(context, extended: false),
      WindowSize.expanded => _buildWithRail(context, extended: true),
    };
  }

  Widget _buildCompact(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: title, actions: actions),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Tooltip(
                message: destination.enabled
                    ? ''
                    : destination.disabledReason ?? '',
                child: Icon(destination.icon),
              ),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
              enabled: destination.enabled,
            ),
        ],
      ),
    );
  }

  Widget _buildWithRail(BuildContext context, {required bool extended}) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _select,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: extended
                  ? const _RailHeader()
                  : const SizedBox(height: Spacing.sm),
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Tooltip(
                      message: destination.enabled
                          ? destination.label
                          : destination.disabledReason ?? destination.label,
                      child: Icon(destination.icon),
                    ),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                    disabled: !destination.enabled,
                  ),
              ],
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: Column(
                children: [
                  if (title != null)
                    _TopBar(title: title!, actions: actions ?? const []),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.terminal_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Termino',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const new({required this.title, required this.actions});

  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          DefaultTextStyle.merge(
            style: theme.textTheme.titleSmall,
            child: title,
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}
