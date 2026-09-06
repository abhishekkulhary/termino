import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/snippets/presentation/snippet_sheet.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/local_shell_notice.dart';
import 'package:termino/features/terminal/presentation/terminal_pane.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/design/tokens.dart';

/// The terminal workspace: a tab strip and the active session's pane.
///
/// Split panes arrive in Phase 4; this shows one session at a time on every
/// window size.
class TerminalScreen extends ConsumerWidget {
  /// Creates the terminal workspace.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionManagerProvider);

    if (sessions.isEmpty) return const _EmptyState();

    return Column(
      children: [
        _TabStrip(
          sessions: sessions.sessions,
          activeId: sessions.activeId,
          activeSession: sessions.active,
          secondaryId: sessions.secondaryId,
          onSelect: ref.read(sessionManagerProvider.notifier).activate,
          onClose: (id) =>
              unawaited(ref.read(sessionManagerProvider.notifier).close(id)),
          onSplitWith: ref.read(sessionManagerProvider.notifier).splitWith,
          onUnsplit: ref.read(sessionManagerProvider.notifier).unsplit,
        ),
        Expanded(child: _Panes(sessions: sessions)),
      ],
    );
  }
}

/// Opens a new session, offering whichever shells this machine actually has.
class _NewSessionButton extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(shellProfilesProvider);
    final launcher = ref.read(sessionLauncherProvider.notifier);

    return MenuAnchor(
      menuChildren: [
        for (final profile in profiles)
          MenuItemButton(
            leadingIcon: const Icon(Icons.terminal_rounded, size: 18),
            onPressed: () => unawaited(launcher.openLocalShell(profile)),
            child: Text(profile.name),
          ),
        if (profiles.isNotEmpty) const Divider(height: Spacing.sm),
        MenuItemButton(
          leadingIcon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          onPressed: () => unawaited(launcher.openDemo()),
          child: const Text('Demo session'),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.add_rounded, size: 18),
        tooltip: 'New session',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Shows the active session, or two side by side when the window is split.
///
/// Every session stays mounted whichever pane it is in, so switching tabs never
/// interrupts a running command or discards scrollback.
class _Panes extends ConsumerWidget {
  const new({required this.sessions});

  final SessionsState sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = Breakpoints.ofContext(context);
    final secondary = size.supportsSplitPanes ? sessions.secondary : null;

    final stack = IndexedStack(
      index: sessions.sessions.indexWhere(
        (session) => session.id == sessions.activeId,
      ),
      children: [
        for (final session in sessions.sessions)
          TerminalPane(
            key: ValueKey(session.id),
            session: session,
            autofocus: session.id == sessions.activeId,
          ),
      ],
    );

    if (secondary == null) return stack;

    return Row(
      children: [
        Expanded(child: stack),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: TerminalPane(
            key: ValueKey('split-${secondary.id}'),
            session: secondary,
            autofocus: false,
          ),
        ),
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const new({
    required this.sessions,
    required this.activeId,
    required this.activeSession,
    required this.secondaryId,
    required this.onSelect,
    required this.onClose,
    required this.onSplitWith,
    required this.onUnsplit,
  });

  final List<TerminalSession> sessions;
  final String? activeId;
  final TerminalSession? activeSession;
  final String? secondaryId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final ValueChanged<String> onSplitWith;
  final VoidCallback onUnsplit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _Tab(
                  session: session,
                  selected: session.id == activeId,
                  inSplit: session.id == secondaryId,
                  canSplit:
                      Breakpoints.ofContext(context).supportsSplitPanes &&
                      session.id != activeId,
                  onTap: () => onSelect(session.id),
                  onClose: () => onClose(session.id),
                  onSplit: () => onSplitWith(session.id),
                  onUnsplit: onUnsplit,
                );
              },
            ),
          ),
          _SnippetsButton(session: activeSession),
          const _NewSessionButton(),
          const SizedBox(width: Spacing.xs),
        ],
      ),
    );
  }
}

/// Opens the snippet sheet for whichever session is in front.
///
/// In the tab strip rather than only in the terminal's context menu, because a
/// touch device has no right-click and snippets are most useful there.
class _SnippetsButton extends StatelessWidget {
  const new({required this.session});

  final TerminalSession? session;

  @override
  Widget build(BuildContext context) {
    final current = session;

    return IconButton(
      icon: const Icon(Icons.bolt_outlined, size: 18),
      tooltip: 'Snippets',
      onPressed: current == null
          ? null
          : () => unawaited(
              showSnippetSheet(
                context,
                hostId: current.hostId,
                onSend: current.sendText,
              ),
            ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({
    required this.session,
    required this.selected,
    required this.inSplit,
    required this.canSplit,
    required this.onTap,
    required this.onClose,
    required this.onSplit,
    required this.onUnsplit,
  });

  final TerminalSession session;
  final bool selected;
  final bool inSplit;
  final bool canSplit;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onSplit;
  final VoidCallback onUnsplit;

  VoidCallback _showMenu(BuildContext context) => () {
    unawaited(
      showMenu<void>(
        context: context,
        position: const RelativeRect.fromLTRB(0, 40, 0, 0),
        items: [
          if (canSplit)
            PopupMenuItem<void>(
              onTap: onSplit,
              child: const Text('Open beside'),
            ),
          if (inSplit)
            PopupMenuItem<void>(
              onTap: onUnsplit,
              child: const Text('Close second pane'),
            ),
        ],
      ),
    );
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: session.title,
      builder: (context, title, _) {
        return InkWell(
          onTap: onTap,
          onSecondaryTap: canSplit || inSplit ? _showMenu(context) : null,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              color: selected || inSplit
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : inSplit
                      ? theme.colorScheme.secondary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (inSplit) ...[
                  Tooltip(
                    message: 'Shown in the second pane',
                    child: Icon(
                      Icons.vertical_split_rounded,
                      size: 12,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                ],
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                InkWell(
                  onTap: onClose,
                  borderRadius: Radii.borderSm,
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xxs),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final profiles = ref.watch(shellProfilesProvider);
    final launcher = ref.read(sessionLauncherProvider.notifier);
    final reason = capabilities.localShellUnavailableReason;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: Spacing.lg),
                Text('No sessions open', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                Text(
                  capabilities.canRunLocalShell
                      ? 'Open a shell on this machine, or connect to a saved '
                            'host under Hosts.'
                      : 'Connect to a saved host under Hosts, or replay the '
                            'demo to try the terminal.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                if (capabilities.canRunLocalShell && profiles.isNotEmpty) ...[
                  FilledButton.icon(
                    onPressed: () => unawaited(launcher.openLocalShell()),
                    icon: const Icon(Icons.terminal_rounded),
                    label: Text('Open ${profiles.first.name}'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton(
                    onPressed: () => unawaited(launcher.openDemo()),
                    child: const Text('Demo session'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () => unawaited(launcher.openDemo()),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Demo session'),
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: Spacing.xl),
                    LocalShellNotice(reason: reason),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
