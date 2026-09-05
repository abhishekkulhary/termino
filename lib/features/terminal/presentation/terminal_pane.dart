import 'package:flutter/material.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/shared/design/terminal_palette.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:xterm/xterm.dart';

/// Renders one [TerminalSession].
///
/// This widget is the **only** place in the app that imports `xterm`. Every
/// other feature talks to [TerminalSession] and to this widget, so replacing or
/// vendoring the emulator — a real possibility, given how long xterm.dart has
/// gone without a release — changes one file rather than the whole UI.
///
/// See DECISIONS.md, "xterm adopted despite being under-maintained".
class TerminalPane extends StatefulWidget {
  /// Creates a pane showing [session].
  const new({required this.session, super.key, this.autofocus = true});

  /// The session to render.
  final TerminalSession session;

  /// Whether this pane should take keyboard focus when first shown.
  final bool autofocus;

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  final _controller = TerminalController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TerminalPalettes.forBrightness(
      Theme.of(context).brightness,
    );

    return ColoredBox(
      color: palette.theme.background,
      child: Column(
        children: [
          _ConnectionBanner(session: widget.session),
          Expanded(
            child: TerminalView(
              widget.session.terminal,
              controller: _controller,
              theme: palette.theme,
              textStyle: palette.styleWith(),
              // The terminal grid has its own font-size setting; scaling it
              // with the platform text-scale factor would reflow the grid
              // underneath the user and break alignment of box drawing.
              // UI chrome elsewhere still honours the platform setting.
              textScaler: TextScaler.noScaling,
              autofocus: widget.autofocus,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A strip shown above the terminal whenever the session is not simply
/// connected, so a dropped connection is never silent.
class _ConnectionBanner extends StatelessWidget {
  const new({required this.session});

  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BackendConnectionState>(
      valueListenable: session.connectionState,
      builder: (context, state, _) {
        final theme = Theme.of(context);
        final (message, background, foreground) = switch (state) {
          BackendConnectionState.idle => (
            'Not started',
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.onSurfaceVariant,
          ),
          BackendConnectionState.connecting => (
            'Connecting…',
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
          ),
          BackendConnectionState.connected => (null, null, null),
          BackendConnectionState.closed => (
            'Session ended',
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.onSurfaceVariant,
          ),
          BackendConnectionState.error => (
            session.backend.failure?.message ?? 'The session failed.',
            theme.colorScheme.errorContainer,
            theme.colorScheme.onErrorContainer,
          ),
        };

        if (message == null) return const SizedBox.shrink();

        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            color: background,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  switch (state) {
                    BackendConnectionState.error => Icons.error_outline_rounded,
                    BackendConnectionState.connecting => Icons.sync_rounded,
                    _ => Icons.info_outline_rounded,
                  },
                  size: 16,
                  color: foreground,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
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
