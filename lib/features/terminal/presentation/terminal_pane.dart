import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/snippets/presentation/snippet_sheet.dart';
import 'package:termino/features/terminal/application/hyperlinks.dart';
import 'package:termino/features/terminal/application/sticky_modifiers.dart';
import 'package:termino/features/terminal/application/terminal_search_controller.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/bell_effect.dart';
import 'package:termino/features/terminal/presentation/key_accessory_bar.dart';
import 'package:termino/features/terminal/presentation/terminal_cursor.dart';
import 'package:termino/features/terminal/presentation/terminal_links.dart';
import 'package:termino/features/terminal/presentation/terminal_search_bar.dart';
import 'package:termino/features/terminal/presentation/transfer_overlay.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xterm/xterm.dart';

/// Renders one [TerminalSession], with everything needed to work in it.
///
/// This widget is the **only** place in the app that imports `xterm`. Every
/// other feature talks to [TerminalSession] and to this widget, so replacing or
/// vendoring the emulator — a real possibility, given how long xterm.dart has
/// gone without a release — changes one file rather than the whole UI.
///
/// See DECISIONS.md, "xterm adopted despite being under-maintained".
class TerminalPane extends ConsumerStatefulWidget {
  /// Creates a pane showing [session].
  const new({required this.session, super.key, this.autofocus = true});

  /// The session to render.
  final TerminalSession session;

  /// Whether this pane should take keyboard focus when first shown.
  final bool autofocus;

  @override
  ConsumerState<TerminalPane> createState() => TerminalPaneState();
}

/// Public so that a parent — the tab bar, a keyboard shortcut — can open the
/// find bar on the pane the user is looking at.
class TerminalPaneState extends ConsumerState<TerminalPane> {
  final _controller = TerminalController();
  final _modifiers = StickyModifiers();
  final _focus = FocusNode();
  // Owned here so the cursor overlay can read the same scroll position
  // the grid is drawn at.
  final _scroll = ScrollController();

  TerminalSearchController? _search;
  double? _fontSizeAtGestureStart;

  /// Whether the find bar is open.
  bool get isSearching => _search != null;

  /// Opens the find bar.
  void openSearch() {
    if (_search != null) return;
    final palette = ref.read(
      activePaletteProvider(Theme.of(context).brightness),
    );
    setState(() {
      _search = TerminalSearchController(
        terminal: widget.session.terminal,
        controller: _controller,
        matchColor: palette.theme.searchHitBackground,
        currentMatchColor: palette.theme.searchHitBackgroundCurrent,
      );
    });
  }

  /// Offers the saved commands that apply to this session.
  Future<void> openSnippets() => showSnippetSheet(
    context,
    hostId: widget.session.hostId,
    onSend: widget.session.sendText,
  );

  /// Closes the find bar and clears its highlights.
  void closeSearch() {
    final search = _search;
    if (search == null) return;
    setState(() => _search = null);
    search.dispose();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _search?.dispose();
    _controller.dispose();
    _modifiers.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copySelection() async {
    final selection = _controller.selection;
    if (selection == null) return;
    final text = widget.session.terminal.buffer.getText(selection);
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    _controller.clearSelection();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    // Goes through the terminal rather than straight to the backend so that
    // bracketed paste is applied when the program has asked for it — without
    // it, pasting into vim inserts and auto-indents every line.
    widget.session.terminal.paste(text);
  }

  Future<void> _changeFontSize(double delta) => ref
      .read(settingsProvider.notifier)
      .setFontSize(ref.read(currentSettingsProvider).fontSize + delta);

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isControl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    // The accelerator is Cmd on Apple platforms and Ctrl+Shift elsewhere,
    // because a bare Ctrl+F belongs to the program running in the terminal.
    final accelerator = Theme.of(context).platform == TargetPlatform.macOS
        ? isMeta
        : isControl && isShift;

    if (!accelerator) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyF:
        openSearch();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        unawaited(_changeFontSize(1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.minus:
        unawaited(_changeFontSize(-1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.digit0:
        unawaited(ref.read(settingsProvider.notifier).setFontSize(14));
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final settings = ref.watch(currentSettingsProvider);
    final palette = ref.watch(activePaletteProvider(brightness));
    final size = Breakpoints.ofContext(context);
    final isTouch = size == WindowSize.compact;

    const gridPadding = EdgeInsets.symmetric(
      horizontal: Spacing.sm,
      vertical: Spacing.xs,
    );
    final textStyle = palette.styleWith(
      fontSize: settings.fontSize,
      lineHeight: settings.lineHeight,
      fontFamily: settings.fontFamily,
    );

    final terminalView = TerminalView(
      widget.session.terminal,
      controller: _controller,
      focusNode: _focus,
      scrollController: _scroll,
      // The view is given no cursor of its own; see TerminalCursorOverlay.
      theme: palette.themeWithoutCursor,
      textStyle: textStyle,
      // The terminal grid has its own font-size setting; scaling it with the
      // platform text-scale factor would reflow the grid underneath the user
      // and break alignment of box drawing. UI chrome still honours it.
      textScaler: TextScaler.noScaling,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      onTapUp: (details, offset) => unawaited(_openLinkAt(offset)),
      onSecondaryTapDown: (details, offset) =>
          unawaited(_showContextMenu(details.globalPosition)),
      padding: gridPadding,
    );

    final grid = Stack(
      children: [
        Positioned.fill(child: terminalView),
        // Under the cursor, so a cursor sitting on a link is still legible.
        Positioned.fill(
          child: TerminalLinkOverlay(
            terminal: widget.session.terminal,
            hyperlinks: widget.session.hyperlinks,
            scrollController: _scroll,
            style: textStyle,
            textScaler: TextScaler.noScaling,
            padding: gridPadding,
            color: palette.theme.blue,
          ),
        ),
        Positioned.fill(
          child: TerminalCursorOverlay(
            terminal: widget.session.terminal,
            scrollController: _scroll,
            style: textStyle,
            textScaler: TextScaler.noScaling,
            padding: gridPadding,
            color: palette.theme.cursor,
            shape: settings.cursorShape,
            blinks: settings.cursorBlinks,
            focusNode: _focus,
          ),
        ),
        // Over the grid rather than beside it: a transfer prompt that pushed
        // the terminal up would reflow the screen a program is drawing on.
        Positioned.fill(child: TransferOverlay(sessionId: widget.session.id)),
      ],
    );

    return BellEffect(
      session: widget.session,
      child: ColoredBox(
        color: palette.theme.background,
        child: Column(
          children: [
            _ConnectionBanner(session: widget.session),
            if (_search case final search?)
              TerminalSearchBar(controller: search, onClose: closeSearch),
            Expanded(
              child: _PinchToZoom(
                onScaleStart: () => _fontSizeAtGestureStart = settings.fontSize,
                onScaleUpdate: (scale) {
                  final base = _fontSizeAtGestureStart;
                  if (base == null) return;
                  unawaited(
                    ref
                        .read(settingsProvider.notifier)
                        .setFontSize(base * scale),
                  );
                },
                onScaleEnd: () => _fontSizeAtGestureStart = null,
                child: grid,
              ),
            ),
            if (isTouch)
              KeyAccessoryBar(
                terminal: widget.session.terminal,
                modifiers: _modifiers,
              ),
          ],
        ),
      ),
    );
  }

  /// Opens a URL the user tapped, if they tapped one.
  ///
  /// The decision — which URL, and whether to ask first — lives in
  /// [TerminalHyperlinks.actionAt], where it can be tested. This is only the
  /// part that needs a `BuildContext`.
  Future<void> _openLinkAt(CellOffset offset) async {
    final session = widget.session;
    final action = session.hyperlinks.actionAt(
      session.terminal,
      offset.y,
      offset.x,
    );

    final uri = switch (action) {
      NoLink() => null,
      OpenLink(:final uri) => uri,
      ConfirmLink(:final uri) => await _confirmLink(uri) ? uri : null,
    };
    if (uri == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(uri)) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $uri')));
    }
  }

  /// Shows where a declared link actually goes, and asks.
  Future<bool> _confirmLink(Uri uri) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open this link?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The program chose the words on screen and this destination '
              'separately. They need not match.',
            ),
            const SizedBox(height: Spacing.md),
            SelectableText(
              uri.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: Fonts.mono,
                fontFamilyFallback: Fonts.monoFallback,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _showContextMenu(Offset position) async {
    final hasSelection = _controller.selection != null;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final choice = await showMenu<_ContextAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _ContextAction.copy,
          enabled: hasSelection,
          child: const Text('Copy'),
        ),
        const PopupMenuItem(value: _ContextAction.paste, child: Text('Paste')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ContextAction.selectAll,
          child: Text('Select all'),
        ),
        const PopupMenuItem(value: _ContextAction.find, child: Text('Find…')),
        const PopupMenuItem(
          value: _ContextAction.snippets,
          child: Text('Snippets…'),
        ),
      ],
    );

    switch (choice) {
      case _ContextAction.copy:
        await _copySelection();
      case _ContextAction.paste:
        await _paste();
      case _ContextAction.selectAll:
        final buffer = widget.session.terminal.buffer;
        _controller.setSelection(
          buffer.createAnchor(0, 0),
          buffer.createAnchor(0, buffer.height - 1),
        );
      case _ContextAction.find:
        openSearch();
      case _ContextAction.snippets:
        await openSnippets();
      case null:
        break;
    }
  }
}

enum _ContextAction { copy, paste, selectAll, find, snippets }

/// Two-finger pinch to change the terminal font size.
///
/// Wrapped around the terminal rather than replacing its gesture handling, so
/// single-finger selection and scrolling still belong to `xterm`. A scale
/// gesture only starts with two pointers, which is what keeps this from
/// stealing a tap or a drag — a gesture that accidentally sends input is far
/// worse than one that does not fire.
class _PinchToZoom extends StatelessWidget {
  const new({
    required this.child,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  final Widget child;
  final VoidCallback onScaleStart;
  final ValueChanged<double> onScaleUpdate;
  final VoidCallback onScaleEnd;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
              ScaleGestureRecognizer.new,
              (recognizer) => recognizer
                ..onStart = (details) {
                  if (details.pointerCount < 2) return;
                  onScaleStart();
                }
                ..onUpdate = (details) {
                  if (details.pointerCount < 2) return;
                  onScaleUpdate(details.scale);
                }
                ..onEnd = (_) => onScaleEnd(),
            ),
      },
      behavior: HitTestBehavior.translucent,
      child: child,
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
