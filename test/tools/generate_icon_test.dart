// Renders the app icon.
//
//     flutter test test/tools/generate_icon_test.dart --update-goldens
//
// Writes assets/icon/icon.png and assets/icon/foreground.png, which
// flutter_launcher_icons turns into every platform's assets.
//
// Written as a golden because Flutter's own renderer is the only rasteriser
// this project can rely on — there is no ImageMagick or librsvg here — and
// because a hand-drawn PNG nobody can regenerate is how an icon ends up
// impossible to change. Tagged `tools` so it is skipped by ordinary runs; it
// writes files rather than asserting anything.
@Tags(['tools'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;

/// The brand blue, matching `AppTheme.seed`.
const _brand = Color(0xFF3B7DD8);

/// The mark: a prompt chevron and a block cursor on a dark terminal ground.
///
/// Legibility at 32 pixels is the only real constraint, so it is two shapes
/// and nothing else — no text, and no detail fine enough to disappear.
class _Mark extends StatelessWidget {
  const new({required this.withBackground});

  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (withBackground)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2230), Color(0xFF11141B)],
                ),
              ),
            ),
          Center(
            child: SizedBox(
              // Android's adaptive-icon safe zone is the middle ~66%, so the
              // foreground is drawn smaller to survive any mask.
              width: _size * (withBackground ? 0.52 : 0.40),
              height: _size * (withBackground ? 0.52 : 0.40),
              child: CustomPaint(painter: _MarkPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;

    // The prompt: >
    canvas
      ..drawPath(
        Path()
          ..moveTo(size.width * 0.06, size.height * 0.16)
          ..lineTo(size.width * 0.46, size.height * 0.5)
          ..lineTo(size.width * 0.06, size.height * 0.84),
        Paint()
          ..color = _brand
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      // The cursor: a solid block, which is what a terminal actually shows.
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.6,
            size.height * 0.6,
            size.width * 0.34,
            size.height * 0.24,
          ),
          Radius.circular(stroke * 0.35),
        ),
        Paint()..color = const Color(0xFFE8EEF7),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _render(WidgetTester tester, Widget mark, String path) async {
  tester.view
    ..physicalSize = const Size(_size, _size)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: mark),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byType(SizedBox).first, matchesGoldenFile(path));
}

void main() {
  testWidgets('app icon', (tester) async {
    await _render(
      tester,
      const _Mark(withBackground: true),
      '../../assets/icon/icon.png',
    );
  });

  testWidgets('adaptive foreground', (tester) async {
    await _render(
      tester,
      const _Mark(withBackground: false),
      '../../assets/icon/foreground.png',
    );
  });
}
