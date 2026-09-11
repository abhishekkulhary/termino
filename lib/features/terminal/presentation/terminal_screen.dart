import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/command_palette/presentation/command_palette.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/snippets/presentation/snippet_sheet.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/local_shell_notice.dart';
import 'package:termino/features/terminal/presentation/recording_button.dart';
import 'package:termino/features/terminal/presentation/session_status_bar.dart';
import 'package:termino/features/terminal/presentation/terminal_pane.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';

/// The terminal workspace: a tab strip and the active session's pane.
///
/// One pane at a time on a phone, two side by side where there is room for
/// them — see `_Panes`, which keeps every session mounted either way so
/// switching tabs never interrupts a running command.
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
          leadingIcon: const Icon(Icons.dns_rounded, size: 18),
          onPressed: () => context.go(AppDestinations.hosts.route),
          child: const Text('Connect to a host'),
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
          _Pane(
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
          child: _Pane(
            key: ValueKey('split-${secondary.id}'),
            session: secondary,
            autofocus: false,
          ),
        ),
      ],
    );
  }
}

/// A terminal with its readout beneath it.
///
/// The status bar belongs to the pane rather than to the screen because a
/// split shows two sessions, and each one's state is its own.
class _Pane extends StatelessWidget {
  const new({required this.session, required this.autofocus, super.key});

  final TerminalSession session;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TerminalPane(session: session, autofocus: autofocus),
        ),
        SessionStatusBar(session: session),
      ],
    );
  }
}

/// Finds the tab strip in a test, so a tab's height can be compared with the
/// thing it is supposed to fill.
@visibleForTesting
const stripKey = ValueKey<String>('terminal-tab-strip');

class _TabStrip extends StatefulWidget {
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
  State<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<_TabStrip> {
  final _scroll = ScrollController();

  /// Each tab's key, so the active one can be scrolled to by the framework
  /// rather than by arithmetic on widths this widget does not know.
  final _tabKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    // On the first build too: sessions can already exist when this is mounted
    // — coming back from the file browser, for one — and the active tab is
    // just as likely to be off the edge then.
    _revealActive();
  }

  @override
  void didUpdateWidget(_TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) _revealActive();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the active tab into view, and only if it is not already there.
  ///
  /// The strip scrolls but never scrolled itself, so with enough sessions open
  /// the highlighted tab could sit off-screen — and switching by keyboard or
  /// from the command palette gave no visible sign of having worked at all.
  ///
  /// The bounds are computed rather than handed to `ensureVisible`, because
  /// that always scrolls to its alignment: clicking a tab that was perfectly
  /// visible would shunt the whole strip sideways. Here a visible tab is left
  /// exactly where it is, and one that is off an edge moves just far enough to
  /// clear it.
  ///
  /// Deferred a frame, because the tab for a session opened in this same build
  /// does not exist yet when the switch is announced.
  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;

      final tab = _tabKeys[widget.activeId]?.currentContext;
      final box = tab?.findRenderObject();
      if (box == null) return;

      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) return;

      final leading = viewport.getOffsetToReveal(box, 0).offset;
      final trailing = viewport.getOffsetToReveal(box, 1).offset;
      final offset = _scroll.offset;

      // Between the two is the tab sitting fully inside the viewport.
      final target = offset > leading
          ? leading
          : offset < trailing
          ? trailing
          : null;
      if (target == null) return;

      _scroll.animateTo(
        target.clamp(
          _scroll.position.minScrollExtent,
          _scroll.position.maxScrollExtent,
        ),
        duration: Motion.normal,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = widget.sessions;

    // Keys for sessions that have gone are dropped, so a long-lived window
    // does not accumulate one per tab it ever opened.
    _tabKeys.removeWhere(
      (id, _) => !sessions.any((session) => session.id == id),
    );

    return Container(
      key: stripKey,
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
            // A row in a scroll view rather than a list: both flavours of
            // `ListView` create elements only for the tabs currently laid out,
            // and the tab that needs scrolling to is precisely the one that is
            // not. A strip holds tens of these, not thousands, so building
            // them all costs nothing worth measuring.
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                // Full height, which the horizontal `ListView` this replaced
                // gave for free. A `Row` otherwise hands its children a loose
                // cross-axis constraint and centres what comes back, so the
                // selected tab's fill became a short band floating in the
                // strip with its underline hanging in mid-air instead of
                // sitting on the bottom edge.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final session in sessions)
                    _Tab(
                      key: _tabKeys.putIfAbsent(session.id, GlobalKey.new),
                      session: session,
                      selected: session.id == widget.activeId,
                      inSplit: session.id == widget.secondaryId,
                      canSplit:
                          Breakpoints.ofContext(context).supportsSplitPanes &&
                          session.id != widget.activeId,
                      onTap: () => widget.onSelect(session.id),
                      onClose: () => widget.onClose(session.id),
                      onSplit: () => widget.onSplitWith(session.id),
                      onUnsplit: widget.onUnsplit,
                    ),
                ],
              ),
            ),
          ),
          if (widget.activeSession case final recording?) ...[
            RecordingButton(
              key: ValueKey('record-${recording.id}'),
              session: recording,
            ),
          ],
          const SizedBox(width: Spacing.xs),
          _BrowseFilesButton(session: widget.activeSession),
          _SnippetsButton(session: widget.activeSession),
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
/// Opens the file browser on the host this session is connected to.
///
/// Costs no second authentication: the browser attaches to the same connection
/// this shell is already using. Absent for a local shell, which has no host to
/// browse.
class _BrowseFilesButton extends ConsumerWidget {
  const new({required this.session});

  final TerminalSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostId = session?.hostId;
    if (hostId == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.folder_open_rounded, size: 18),
      tooltip: 'Browse files on this host',
      onPressed: () => unawaited(_browse(context, ref, hostId)),
    );
  }

  Future<void> _browse(
    BuildContext context,
    WidgetRef ref,
    String hostId,
  ) async {
    final host = await ref.read(sshHostRepositoryProvider).byId(hostId);
    if (host == null || !context.mounted) return;

    ref.read(selectedSftpHostProvider.notifier).select(host);
    context.go(AppDestinations.files.route);
  }
}

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
    super.key,
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
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Curves.easeOut,
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
                // The tab's own light. A session that dropped while the user
                // was in another tab is otherwise indistinguishable from one
                // that is fine, until they switch to it and find out.
                ValueListenableBuilder<BackendConnectionState>(
                  valueListenable: session.connectionState,
                  builder: (context, state, _) =>
                      StatusDot(status: healthOf(state), size: 7),
                ),
                const SizedBox(width: Spacing.sm),
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

/// A terminal glyph inside a glowing ring.
///
/// The empty terminal is the first thing a new user sees, and a flat icon on
/// a black field says nothing at all. This says the app is on.
class _EmptyMark extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: neon.glowStrong(accent),
      ),
      child: Icon(Icons.terminal_rounded, size: 38, color: accent),
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
                const Reveal(child: _EmptyMark()),
                const SizedBox(height: Spacing.xl),
                Reveal(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    'No sessions open',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Reveal(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    capabilities.canRunLocalShell
                        ? 'Open a shell on this machine, or connect to a '
                              'saved host.'
                        : 'Connect to a saved host to open a session here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // The empty screen is where someone is most likely to be
                // looking for a way in, so it is where the shortcut is worth
                // saying out loud.
                Reveal(
                  delay: const Duration(milliseconds: 140),
                  child: Text(
                    'Press ${commandPaletteHint(context)} for anything',
                    style: theme.textTheme.labelSmall,
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
                  TextButton.icon(
                    onPressed: () => context.go(AppDestinations.hosts.route),
                    icon: const Icon(Icons.dns_rounded, size: 18),
                    label: const Text('Connect to a host'),
                  ),
                ] else ...[
                  // Where there is no local shell, connecting is the only
                  // thing this screen can offer — so it is the primary
                  // action rather than a link under one.
                  FilledButton.icon(
                    onPressed: () => context.go(AppDestinations.hosts.route),
                    icon: const Icon(Icons.dns_rounded),
                    label: const Text('Connect to a host'),
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
