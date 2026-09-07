import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/command_palette/application/fuzzy_match.dart';
import 'package:termino/features/desktop/presentation/app_shortcuts.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';

/// One thing the palette can do.
class PaletteCommand {
  /// Creates a command.
  const new({
    required this.id,
    required this.group,
    required this.title,
    required this.icon,
    required this.run,
    this.subtitle,
    this.keywords = const [],
    this.accent,
  });

  /// Stable identity, used as a widget key.
  final String id;

  /// The heading this appears under.
  final String group;

  /// What the user reads first.
  final String title;

  /// The detail line — a target, a path, a value.
  final String? subtitle;

  /// The glyph shown beside it.
  final IconData icon;

  /// Performed when chosen.
  final FutureOr<void> Function() run;

  /// Extra text this is findable by, beyond title and subtitle.
  final List<String> keywords;

  /// Tints the icon, e.g. a host's own colour.
  final Color? accent;

  /// Everything a query is matched against.
  Iterable<String> get searchable => [title, ?subtitle, group, ...keywords];
}

/// Opens the palette over whatever is on screen.
Future<void> showCommandPalette(BuildContext context) => showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Dismiss',
  barrierColor: Colors.black.withValues(alpha: 0.62),
  transitionDuration: Motion.normal,
  pageBuilder: (_, _, _) => const _CommandPalette(),
  transitionBuilder: (context, animation, _, child) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.03),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  },
);

/// The shortcut that opens it, written the way the platform writes it.
///
/// Takes its answer from [AppShortcuts] rather than repeating the rule, so a
/// hint can never drift from the binding it describes.
String commandPaletteHint(BuildContext context) => AppShortcuts.label('K');

class _CommandPalette extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<_CommandPalette> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  var _highlighted = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<PaletteCommand> _matching(List<PaletteCommand> all) {
    final query = _controller.text;
    if (query.trim().isEmpty) return all;

    final scored = <(PaletteCommand, int)>[];
    for (final command in all) {
      final score = FuzzyMatch.scoreAny(query, command.searchable);
      if (score != null) scored.add((command, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((entry) => entry.$1).toList();
  }

  Future<void> _run(PaletteCommand command) async {
    Navigator.of(context).pop();
    await command.run();
  }

  void _move(int delta, int count) {
    if (count == 0) return;
    setState(() => _highlighted = (_highlighted + delta) % count);
    // Roughly one row; enough to keep the highlight in view while typing.
    _scroll.animateTo(
      (_highlighted * 52.0 - 100).clamp(0, _scroll.position.maxScrollExtent),
      duration: Motion.fast,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final commands = _buildCommands(context, ref);
    final results = _matching(commands);
    final highlighted = results.isEmpty
        ? -1
        : _highlighted.clamp(0, results.length - 1);

    return Align(
      alignment: const Alignment(0, -0.55),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
          child: Material(
            color: Colors.transparent,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _move(1, results.length),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _move(-1, results.length),
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (highlighted >= 0) unawaited(_run(results[highlighted]));
                },
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    Navigator.of(context).pop(),
              },
              child: NeonPanel(
                accent: theme.colorScheme.primary,
                selected: true,
                padding: EdgeInsets.zero,
                borderRadius: Radii.borderLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SearchField(
                      controller: _controller,
                      focusNode: _focus,
                      onChanged: () => setState(() => _highlighted = 0),
                      onSubmitted: () {
                        if (highlighted >= 0) {
                          unawaited(_run(results[highlighted]));
                        }
                      },
                    ),
                    Divider(height: 1, color: neon.grid),
                    Flexible(
                      child: results.isEmpty
                          ? const _NoResults()
                          : _Results(
                              results: results,
                              highlighted: highlighted,
                              controller: _scroll,
                              onSelect: (command) => unawaited(_run(command)),
                              onHover: (index) =>
                                  setState(() => _highlighted = index),
                            ),
                    ),
                    _Footer(count: results.length),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Assembles everything the palette can currently do.
///
/// Built here, in the widget, rather than in a provider: half of these need a
/// `BuildContext` to navigate, and a provider that takes one is worse than a
/// function that has one.
List<PaletteCommand> _buildCommands(BuildContext context, WidgetRef ref) {
  final commands = <PaletteCommand>[];
  final capabilities = ref.watch(platformCapabilitiesProvider);
  final hosts = ref.watch(sshHostsProvider).value ?? const <SshHost>[];
  final sessions = ref.watch(sessionManagerProvider);
  final snippets = ref.watch(snippetsProvider).value ?? const <Snippet>[];

  // Open sessions first: switching between them is the most frequent thing
  // anyone does in a terminal with more than one tab.
  for (final session in sessions.sessions) {
    if (session.id == sessions.activeId) continue;
    commands.add(
      PaletteCommand(
        id: 'session.${session.id}',
        group: 'Sessions',
        title: session.title.value,
        subtitle: 'Switch to this session',
        icon: Icons.terminal_rounded,
        keywords: const ['tab', 'switch'],
        run: () {
          ref.read(sessionManagerProvider.notifier).activate(session.id);
          context.go(AppDestinations.terminal.route);
        },
      ),
    );
  }

  if (capabilities.canUseSsh) {
    // All the connect commands, then all the browse commands. Interleaving
    // them per host repeats the group heading down the whole list, which reads
    // as a rendering fault rather than as grouping.
    for (final host in hosts) {
      commands.add(
        PaletteCommand(
          id: 'connect.${host.id}',
          group: 'Connect',
          title: host.label,
          subtitle: host.target,
          icon: Icons.bolt_rounded,
          keywords: const ['ssh', 'connect', 'open'],
          accent: host.colorValue == null ? null : Color(host.colorValue!),
          run: () async {
            await ref.read(sessionLauncherProvider.notifier).openSsh(host);
            if (context.mounted) {
              context.go(AppDestinations.terminal.route);
            }
          },
        ),
      );
    }

    for (final host in hosts) {
      commands.add(
        PaletteCommand(
          id: 'files.${host.id}',
          group: 'Files',
          title: 'Browse ${host.label}',
          subtitle: host.target,
          icon: Icons.folder_open_rounded,
          keywords: const ['sftp', 'files', 'transfer', 'upload'],
          run: () {
            ref.read(selectedSftpHostProvider.notifier).select(host);
            context.go(AppDestinations.files.route);
          },
        ),
      );
    }
  }

  final activeId = sessions.activeId;
  if (activeId != null) {
    for (final snippet in snippets) {
      commands.add(
        PaletteCommand(
          id: 'snippet.${snippet.id}',
          group: 'Snippets',
          title: snippet.name,
          subtitle: snippet.body.split('\n').first,
          icon: Icons.bolt_outlined,
          keywords: const ['run', 'paste', 'snippet'],
          // Snippets go to the session the user is looking at; the palette
          // only offers them when there is one.
          run: () => sessions.active?.sendText(snippet.payload),
        ),
      );
    }
  }

  if (capabilities.canRunLocalShell) {
    commands.add(
      PaletteCommand(
        id: 'shell.new',
        group: 'Terminal',
        title: 'New local shell',
        icon: Icons.add_rounded,
        keywords: const ['open', 'local', 'bash', 'zsh', 'sh'],
        run: () async {
          await ref.read(sessionLauncherProvider.notifier).openLocalShell();
          if (context.mounted) context.go(AppDestinations.terminal.route);
        },
      ),
    );
  }

  for (final destination in AppDestinations.all) {
    if (!destination.enabled) continue;
    commands.add(
      PaletteCommand(
        id: 'go.${destination.route}',
        group: 'Go to',
        title: destination.label,
        icon: destination.icon,
        keywords: const ['navigate', 'open', 'show'],
        run: () => context.go(destination.route),
      ),
    );
  }

  return commands;
}

class _SearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.md,
        Spacing.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: theme.textTheme.titleMedium,
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Connect, switch, browse…',
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const new({
    required this.results,
    required this.highlighted,
    required this.controller,
    required this.onSelect,
    required this.onHover,
  });

  final List<PaletteCommand> results;
  final int highlighted;
  final ScrollController controller;
  final ValueChanged<PaletteCommand> onSelect;
  final ValueChanged<int> onHover;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final command = results[index];
        final previous = index == 0 ? null : results[index - 1].group;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (command.group != previous)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.sm,
                  Spacing.lg,
                  Spacing.xs,
                ),
                child: NeonSectionLabel(command.group),
              ),
            _Row(
              command: command,
              selected: index == highlighted,
              onTap: () => onSelect(command),
              onHover: () => onHover(index),
            ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const new({
    required this.command,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  final PaletteCommand command;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = NeonAccents.of(context)
        .readable(command.accent ?? theme.colorScheme.primary);

    return MouseRegion(
      onEnter: (_) => onHover(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          margin: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: Radii.borderSm,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                command.icon,
                size: 18,
                color: selected ? accent : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: selected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.86,
                              ),
                      ),
                    ),
                    if (command.subtitle case final subtitle?)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.keyboard_return_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text('Nothing matches', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: NeonAccents.of(context).grid)),
      ),
      child: Row(
        children: [
          Text('$count', style: theme.textTheme.labelSmall),
          const SizedBox(width: Spacing.xs),
          Text(
            count == 1 ? 'result' : 'results',
            style: theme.textTheme.labelSmall,
          ),
          const Spacer(),
          const _Key('up down'),
          const SizedBox(width: Spacing.sm),
          const _Key('enter'),
          const SizedBox(width: Spacing.sm),
          const _Key('esc'),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: Radii.borderXs,
        border: Border.all(color: NeonAccents.of(context).panelBorder),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
