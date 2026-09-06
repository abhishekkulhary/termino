import 'package:flutter/material.dart';
import 'package:termino/shared/design/neon_accents.dart';

/// A faint blueprint grid behind the app's content.
///
/// Empty screens in a dark app are a void: the Keys screen with nothing in it
/// was six hundred pixels of black. A grid gives the surface a scale and a
/// texture without competing with anything drawn on top, and it is the cheapest
/// way to make the app look built rather than blank.
///
/// Painted, not tiled with images, and static — no animation. A backdrop that
/// moves is a backdrop the eye returns to all day.
class GridBackdrop extends StatelessWidget {
  /// Draws the grid behind [child].
  const new({required this.child, super.key, this.spacing = 32});

  /// The content drawn over the grid.
  final Widget child;

  /// Distance between lines, in logical pixels.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final neon = NeonAccents.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GridPainter(
                line: neon.grid,
                // The vignette needs something to darken towards. In the light
                // theme it darkens towards the panel border instead, which is
                // the only thing there darker than the page.
                edge: neon.glowStrength > 0 ? Colors.black : neon.panelBorder,
                spacing: spacing,
                strength: neon.glowStrength > 0 ? 1 : 0.45,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const new({
    required this.line,
    required this.edge,
    required this.spacing,
    required this.strength,
  });

  final Color line;
  final Color edge;
  final double spacing;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = line.withValues(alpha: 0.55 * strength)
      ..strokeWidth = 1;
    // Every fourth line is brighter, which is what stops a uniform grid
    // reading as noise and gives the eye something to measure against.
    final thick = Paint()
      ..color = line.withValues(alpha: 1.0 * strength)
      ..strokeWidth = 1;

    var index = 0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 4 == 0 ? thick : thin,
      );
      index++;
    }

    index = 0;
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 4 == 0 ? thick : thin,
      );
      index++;
    }

    // A vignette, so the grid fades out towards the edges rather than running
    // into the window frame at full strength.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [
            edge.withValues(alpha: 0),
            edge.withValues(alpha: 0.55 * strength),
          ],
          stops: const [0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.edge != edge ||
      oldDelegate.spacing != spacing ||
      oldDelegate.strength != strength;
}
