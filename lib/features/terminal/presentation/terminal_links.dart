import 'package:flutter/material.dart';
import 'package:termino/features/terminal/application/hyperlinks.dart';
import 'package:termino/features/terminal/presentation/terminal_cursor.dart';
import 'package:xterm/xterm.dart';

/// Underlines the cells a program declared as hyperlinks with OSC 8.
///
/// Drawn rather than styled into the text because xterm.dart has no per-cell
/// URL attribution to hang a style on — the same reason the links themselves
/// are tracked outside the emulator. The geometry is the emulator's own: the
/// cell size is measured exactly as the grid measures it, and the scroll offset
/// is read from the controller the grid scrolls with, so the underline sits
/// under the characters at every font size and every scroll position.
///
/// A link that a program declared is not underlined *because it looks like a
/// URL* — it is underlined because the program said so. Text that merely reads
/// as a URL is still handled by the visible-text detector and is not marked
/// here, which is the honest distinction: one is a claim, the other is a guess.
class TerminalLinkOverlay extends StatefulWidget {
  /// Creates an overlay for [terminal]'s links.
  const new({
    required this.terminal,
    required this.hyperlinks,
    required this.scrollController,
    required this.style,
    required this.textScaler,
    required this.padding,
    required this.color,
    super.key,
  });

  /// The emulator whose buffer is being drawn.
  final Terminal terminal;

  /// Where the spans live.
  final TerminalHyperlinks hyperlinks;

  /// The grid's scroll position.
  final ScrollController scrollController;

  /// The text style the grid is drawn with, for measuring a cell.
  final TerminalStyle style;

  /// The scaler the grid uses.
  final TextScaler textScaler;

  /// The view's padding, which shifts the whole grid.
  final EdgeInsets padding;

  /// What to draw the underline in.
  final Color color;

  @override
  State<TerminalLinkOverlay> createState() => _TerminalLinkOverlayState();
}

class _TerminalLinkOverlayState extends State<TerminalLinkOverlay> {
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.terminal.addListener(_repaint);
    widget.scrollController.addListener(_repaint);
  }

  @override
  void didUpdateWidget(TerminalLinkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terminal != widget.terminal) {
      oldWidget.terminal.removeListener(_repaint);
      widget.terminal.addListener(_repaint);
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_repaint);
      widget.scrollController.addListener(_repaint);
    }
  }

  @override
  void dispose() {
    widget.terminal.removeListener(_repaint);
    widget.scrollController.removeListener(_repaint);
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LinkPainter(
          terminal: widget.terminal,
          hyperlinks: widget.hyperlinks,
          scroll: widget.scrollController,
          cellSize: terminalCellSize(widget.style, widget.textScaler),
          padding: widget.padding,
          color: widget.color,
          generation: _generation,
        ),
      ),
    );
  }
}

class _LinkPainter extends CustomPainter {
  const new({
    required this.terminal,
    required this.hyperlinks,
    required this.scroll,
    required this.cellSize,
    required this.padding,
    required this.color,
    required this.generation,
  });

  final Terminal terminal;
  final TerminalHyperlinks hyperlinks;
  final ScrollController scroll;
  final Size cellSize;
  final EdgeInsets padding;
  final Color color;
  final int generation;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollOffset = scroll.hasClients ? scroll.offset : 0.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Only the lines actually on screen are considered. A scrollback of ten
    // thousand lines would otherwise be walked on every frame.
    final first = ((scrollOffset - padding.top) / cellSize.height)
        .floor()
        .clamp(0, terminal.buffer.height);
    final last = ((scrollOffset + size.height) / cellSize.height).ceil().clamp(
      0,
      terminal.buffer.height,
    );

    for (var line = first; line < last; line++) {
      final spans = hyperlinks.spansOn(terminal, line);
      if (spans.isEmpty) continue;

      final y = (line + 1) * cellSize.height - scrollOffset + padding.top - 1.5;

      for (final span in spans) {
        canvas.drawLine(
          Offset(span.start * cellSize.width + padding.left, y),
          Offset(span.end * cellSize.width + padding.left, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinkPainter oldDelegate) => true;
}
