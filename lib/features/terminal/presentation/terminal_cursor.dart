import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:xterm/xterm.dart';

/// Draws the terminal cursor, because `xterm` cannot.
///
/// Two separate faults in `xterm` 4.0.0 land here:
///
/// * `TerminalPainter.paintCursor` ignores the vertical offset it is given for
///   the bar and underline shapes — it draws them at `y = 0` and
///   `y = cellHeight` in the *canvas*, not the cell. So both shapes appeared
///   only on the first line of the terminal, wherever the cursor actually was.
///   Only the block shape, which uses `offset & cellSize`, is correct.
/// * There is no blinking at all. `alwaysShowCursor` sounds like the control
///   for it and is not: it forces the cursor visible regardless of what the
///   program asked for. Nothing in the package ever toggles a cursor off.
///
/// The painter is constructed inside the render object and cannot be replaced,
/// and cursor visibility is set only by escape sequences. What *is* ours is the
/// theme: `_theme.cursor` is used in exactly one place, the cursor paint. So
/// the view is given a transparent cursor colour and this draws the real one on
/// top, which also makes blinking possible.
///
/// This is the mitigation DECISIONS.md registered for depending on an
/// under-maintained package — keep the blast radius inside our own widget —
/// taken without forking 13,000 lines to change 20.
/// Identifies the cursor's own painter, so a test can find it among the many
/// [CustomPaint]s Material builds.
const terminalCursorKey = Key('terminal-cursor');

/// Draws the terminal cursor over the view, correctly and with a blink.
class TerminalCursorOverlay extends StatefulWidget {
  /// Draws the cursor for [terminal] over the view beneath it.
  const new({
    required this.terminal,
    required this.scrollController,
    required this.style,
    required this.textScaler,
    required this.padding,
    required this.color,
    required this.shape,
    required this.blinks,
    required this.focusNode,
    super.key,
  });

  /// The emulator whose cursor this is.
  final Terminal terminal;

  /// The view's scroll position, so the cursor stays on its own line.
  final ScrollController scrollController;

  /// The text style the grid is drawn in, for measuring a cell.
  final TerminalStyle style;

  /// The scaler applied to that style.
  final TextScaler textScaler;

  /// The view's padding, which shifts the whole grid.
  final EdgeInsets padding;

  /// The cursor colour, from the palette.
  final Color color;

  /// Block, bar or underline.
  final TerminalCursorShape shape;

  /// Whether the cursor blinks while the terminal has focus.
  final bool blinks;

  /// Focus drives both the blink and the hollow unfocused cursor.
  final FocusNode focusNode;

  @override
  State<TerminalCursorOverlay> createState() => _TerminalCursorOverlayState();
}

class _TerminalCursorOverlayState extends State<TerminalCursorOverlay> {
  /// Half a blink cycle. Slow enough not to be a strobe, quick enough to find
  /// the cursor on a busy screen.
  static const _halfCycle = Duration(milliseconds: 600);

  Timer? _blink;
  var _on = true;
  var _lastCursor = const _CursorCell(0, 0);

  @override
  void initState() {
    super.initState();
    widget.terminal.addListener(_onTerminalChanged);
    widget.scrollController.addListener(_repaint);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartBlink();
  }

  @override
  void didUpdateWidget(TerminalCursorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.removeListener(_onTerminalChanged);
      widget.terminal.addListener(_onTerminalChanged);
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_repaint);
      widget.scrollController.addListener(_repaint);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.blinks != widget.blinks) _restartBlink();
  }

  @override
  void dispose() {
    _blink?.cancel();
    widget.terminal.removeListener(_onTerminalChanged);
    widget.scrollController.removeListener(_repaint);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    _restartBlink();
    _repaint();
  }

  void _onTerminalChanged() {
    final cursor = _CursorCell(
      widget.terminal.buffer.cursorX,
      widget.terminal.buffer.absoluteCursorY,
    );
    // Typing must not leave the cursor invisible for half a second. Every
    // terminal restarts the blink from "on" when the cursor moves.
    if (cursor != _lastCursor) {
      _lastCursor = cursor;
      _restartBlink();
    }
    _repaint();
  }

  void _restartBlink() {
    _blink?.cancel();
    _on = true;

    final animate =
        widget.blinks &&
        widget.focusNode.hasFocus &&
        !MediaQuery.disableAnimationsOf(context);
    // A cursor that blinks forever is also a widget test that never settles,
    // and someone who asked for no motion did not ask for less of it.
    if (!animate) return;

    _blink = Timer.periodic(_halfCycle, (_) {
      if (!mounted) return;
      setState(() => _on = !_on);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: terminalCursorKey,
        painter: _CursorPainter(
          terminal: widget.terminal,
          scroll: widget.scrollController,
          cellSize: terminalCellSize(widget.style, widget.textScaler),
          padding: widget.padding,
          color: widget.color,
          shape: widget.shape,
          visible: _on,
          hasFocus: widget.focusNode.hasFocus,
        ),
      ),
    );
  }
}

/// The cursor's cell, for noticing that it moved.
@immutable
class _CursorCell {
  const new(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _CursorCell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// The size of one character cell.
///
/// The same measurement `xterm` makes internally — ten `m`s laid out and
/// divided — because its `calcCharSize` is not exported and the cursor has to
/// land exactly on the grid the view drew. Any other measurement puts the
/// cursor half a pixel off, which on a bar cursor is plainly visible.
Size terminalCellSize(TerminalStyle style, TextScaler textScaler) {
  const sample = 'mmmmmmmmmm';

  final textStyle = style.toTextStyle();
  final builder = ui.ParagraphBuilder(textStyle.getParagraphStyle())
    ..pushStyle(textStyle.getTextStyle(textScaler: textScaler))
    ..addText(sample);

  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));

  return Size(paragraph.maxIntrinsicWidth / sample.length, paragraph.height);
}

class _CursorPainter extends CustomPainter {
  const new({
    required this.terminal,
    required this.scroll,
    required this.cellSize,
    required this.padding,
    required this.color,
    required this.shape,
    required this.visible,
    required this.hasFocus,
  });

  final Terminal terminal;
  final ScrollController scroll;
  final Size cellSize;
  final EdgeInsets padding;
  final Color color;
  final TerminalCursorShape shape;
  final bool visible;
  final bool hasFocus;

  /// How thick a bar or underline is drawn.
  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    // A program that hid the cursor — `tput civis`, vim in some modes — is
    // asking for it to be gone, and that outranks the user's shape preference.
    if (!terminal.cursorVisibleMode) return;
    if (!visible && hasFocus) return;

    final scrollOffset = scroll.hasClients ? scroll.offset : 0.0;
    final origin = Offset(
      terminal.buffer.cursorX * cellSize.width + padding.left,
      terminal.buffer.absoluteCursorY * cellSize.height -
          scrollOffset +
          padding.top,
    );

    // Scrolled out of view. Without this the cursor is drawn over the tab
    // strip when the user scrolls back through the scrollback.
    if (origin.dy + cellSize.height < 0 || origin.dy > size.height) return;

    final paint = Paint()..color = color;

    // An unfocused terminal shows a hollow block whatever the chosen shape is,
    // which is the convention everywhere and reads immediately as "typing does
    // not go here".
    if (!hasFocus) {
      canvas.drawRect(
        (origin & cellSize).deflate(0.5),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      return;
    }

    switch (shape) {
      case TerminalCursorShape.block:
        canvas.drawRect(origin & cellSize, paint);
      case TerminalCursorShape.underline:
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx,
            origin.dy + cellSize.height - _stroke,
            cellSize.width,
            _stroke,
          ),
          paint,
        );
      case TerminalCursorShape.bar:
        canvas.drawRect(
          Rect.fromLTWH(origin.dx, origin.dy, _stroke, cellSize.height),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_CursorPainter oldDelegate) => true;
}
