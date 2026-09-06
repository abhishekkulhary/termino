import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/terminal/presentation/terminal_cursor.dart';
import 'package:termino/shared/design/app_theme.dart';
import 'package:termino/shared/design/terminal_palette.dart';
import 'package:xterm/xterm.dart';

import '../../support/test_fonts.dart';

/// `xterm` 4.0.0 draws the bar and underline cursors at the top of the canvas
/// instead of at the cursor's own line, and cannot blink at all. Both are
/// answered by drawing the cursor ourselves, so both are pinned here — by where
/// the paint actually lands, not by which widget exists.
void main() {
  setUpAll(loadTerminalFont);

  const style = TerminalStyle(fontSize: 14);
  const cursorColour = Color(0xFF2BE3FF);

  late Terminal terminal;
  late ScrollController scroll;
  late FocusNode focus;

  setUp(() {
    terminal = Terminal(maxLines: 100)..resize(40, 10);
    scroll = ScrollController();
    focus = FocusNode();
  });

  tearDown(() {
    scroll.dispose();
    focus.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    required TerminalCursorShape shape,
    bool blinks = false,
    bool animations = false,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: !animations),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              // The node has to be attached to the tree for `requestFocus` to
              // take, and the cursor's whole appearance depends on focus.
              child: Focus(
                focusNode: focus,
                child: TerminalCursorOverlay(
                  terminal: terminal,
                  scrollController: scroll,
                  style: style,
                  textScaler: TextScaler.noScaling,
                  padding: EdgeInsets.zero,
                  color: cursorColour,
                  shape: shape,
                  blinks: blinks,
                  focusNode: focus,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
  }

  /// Where the cursor was painted, as a rectangle, or null if it was not.
  Rect? paintedCursor(WidgetTester tester) {
    final calls = <Rect>[];
    final recorder = TestRecordingCanvas();
    tester
        .renderObject<RenderCustomPaint>(find.byKey(terminalCursorKey))
        .painter!
        .paint(recorder, const Size(400, 300));
    for (final call in recorder.invocations) {
      if (call.invocation.memberName == #drawRect) {
        calls.add(call.invocation.positionalArguments[0] as Rect);
      }
    }
    return calls.isEmpty ? null : calls.first;
  }

  double cellHeight() => terminalCellSize(style, TextScaler.noScaling).height;

  group('the cursor lands on the line it is actually on', () {
    for (final shape in TerminalCursorShape.values) {
      testWidgets('${shape.name} on the first line', (tester) async {
        await pump(tester, shape: shape);

        final rect = paintedCursor(tester);
        expect(rect, isNotNull);
        expect(rect!.top, lessThan(cellHeight()));
      });

      testWidgets('${shape.name} on the fourth line', (tester) async {
        // This is the bug: xterm drew the bar and underline at y = 0 whatever
        // line the cursor was on, so all three shapes looked identical after
        // the first line — one stuck at the top of the terminal.
        terminal.write('a\r\nb\r\nc\r\nd');
        await pump(tester, shape: shape);

        final rect = paintedCursor(tester);
        expect(rect, isNotNull);
        expect(
          rect!.top,
          greaterThanOrEqualTo(cellHeight() * 3),
          reason: '${shape.name} should be drawn on the fourth line',
        );
      });
    }
  });

  group('shape', () {
    testWidgets('a block fills the cell', (tester) async {
      await pump(tester, shape: TerminalCursorShape.block);
      final rect = paintedCursor(tester)!;
      expect(rect.height, closeTo(cellHeight(), 0.01));
    });

    testWidgets('a bar is a thin upright', (tester) async {
      await pump(tester, shape: TerminalCursorShape.bar);
      final rect = paintedCursor(tester)!;
      expect(rect.height, closeTo(cellHeight(), 0.01));
      expect(rect.width, lessThan(4));
    });

    testWidgets('an underline is a thin rule at the bottom', (tester) async {
      await pump(tester, shape: TerminalCursorShape.underline);
      final rect = paintedCursor(tester)!;
      expect(rect.height, lessThan(4));
      expect(rect.bottom, closeTo(cellHeight(), 0.01));
    });
  });

  group('blinking', () {
    testWidgets('the cursor goes away and comes back', (tester) async {
      await pump(
        tester,
        shape: TerminalCursorShape.block,
        blinks: true,
        animations: true,
      );

      expect(paintedCursor(tester), isNotNull, reason: 'starts visible');

      await tester.pump(const Duration(milliseconds: 650));
      expect(paintedCursor(tester), isNull, reason: 'and blinks off');

      await tester.pump(const Duration(milliseconds: 650));
      expect(paintedCursor(tester), isNotNull, reason: 'and back on');

      // Leaves no timer running behind it.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('typing brings the cursor straight back', (tester) async {
      // A cursor that stays hidden while someone is typing is worse than one
      // that does not blink at all.
      await pump(
        tester,
        shape: TerminalCursorShape.block,
        blinks: true,
        animations: true,
      );

      await tester.pump(const Duration(milliseconds: 650));
      expect(paintedCursor(tester), isNull);

      terminal.write('x');
      await tester.pump();
      expect(paintedCursor(tester), isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a cursor that does not blink stays put', (tester) async {
      await pump(tester, shape: TerminalCursorShape.block, animations: true);

      await tester.pump(const Duration(milliseconds: 650));
      expect(paintedCursor(tester), isNotNull);
      await tester.pump(const Duration(milliseconds: 650));
      expect(paintedCursor(tester), isNotNull);
    });
  });

  testWidgets('a program that hides the cursor is obeyed', (tester) async {
    // `tput civis`. The user's shape preference does not outrank the program.
    terminal.write('\x1b[?25l');
    await pump(tester, shape: TerminalCursorShape.block);

    expect(paintedCursor(tester), isNull);
  });

  testWidgets('the palette hides xterm own cursor entirely', (tester) async {
    // The whole approach rests on this: the view must be given a transparent
    // cursor, or two cursors are drawn and only one of them is in the right
    // place.
    expect(TerminalPalettes.neon.themeWithoutCursor.cursor.a, 0);
    expect(
      TerminalPalettes.neon.themeWithoutCursor.foreground,
      TerminalPalettes.neon.theme.foreground,
      reason: 'nothing else about the palette may change',
    );
  });
}
