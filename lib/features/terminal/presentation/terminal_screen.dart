import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/features/terminal/application/demo_backend.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/terminal_pane.dart';
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

    if (sessions.isEmpty) {
      return _EmptyState(onNewSession: () => _openDemoSession(ref));
    }

    return Column(
      children: [
        _TabStrip(
          sessions: sessions.sessions,
          activeId: sessions.activeId,
          onSelect: ref.read(sessionManagerProvider.notifier).activate,
          onClose: (id) => ref.read(sessionManagerProvider.notifier).close(id),
          onNew: () => _openDemoSession(ref),
        ),
        Expanded(
          child: IndexedStack(
            // Every session stays mounted so that switching tabs never
            // interrupts a running command or discards scrollback.
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
          ),
        ),
      ],
    );
  }

  void _openDemoSession(WidgetRef ref) {
    unawaited(
      ref
          .read(sessionManagerProvider.notifier)
          .open(backend: createDemoBackend(), title: 'Demo'),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const new({
    required this.sessions,
    required this.activeId,
    required this.onSelect,
    required this.onClose,
    required this.onNew,
  });

  final List<TerminalSession> sessions;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final VoidCallback onNew;

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
                  onTap: () => onSelect(session.id),
                  onClose: () => onClose(session.id),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: 'New session',
            onPressed: onNew,
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final TerminalSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: session.title,
      builder: (context, title, _) {
        return InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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

class _EmptyState extends StatelessWidget {
  const new({required this.onNewSession});

  final VoidCallback onNewSession;

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
              Icon(
                Icons.terminal_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text('No sessions open', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Open a session to get started. Local shells arrive in '
                'Phase 2 and SSH in Phase 3; this one replays a fixture.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton.icon(
                onPressed: onNewSession,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
