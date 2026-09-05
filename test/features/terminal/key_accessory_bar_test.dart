@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/sticky_modifiers.dart';
import 'package:termino/features/terminal/presentation/key_accessory_bar.dart';
import 'package:xterm/xterm.dart';

import '../../support/pump.dart';
import '../../support/test_fonts.dart';

void main() {
  setUpAll(loadTerminalFont);

  late Terminal terminal;
  late StickyModifiers modifiers;
  late StringBuffer output;

  setUp(() {
    output = StringBuffer();
    terminal = Terminal()..onOutput = output.write;
    modifiers = StickyModifiers();
  });

  Future<void> pumpBar(WidgetTester tester, {Size size = compactSize}) =>
      pumpApp(
        tester,
        Scaffold(
          body: Column(
            children: [
              const Spacer(),
              KeyAccessoryBar(terminal: terminal, modifiers: modifiers),
            ],
          ),
        ),
        size: size,
      );

  group('sending keys', () {
    testWidgets('Esc sends an escape', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.text('Esc'));
      await tester.pump();

      expect(output.toString(), '\x1b');
    });

    testWidgets('Tab sends a tab', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.text('Tab'));
      await tester.pump();

      expect(output.toString(), '\t');
    });

    testWidgets('the up arrow sends a cursor sequence', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.text('↑'));
      await tester.pump();

      expect(output.toString(), '\x1b[A');
    });

    testWidgets('a symbol key types its character', (tester) async {
      // The bar scrolls horizontally, so on a phone the symbol keys start off
      // screen — which is the point of it scrolling.
      await pumpBar(tester, size: expandedSize);

      await tester.tap(find.text('|'));
      await tester.pump();

      expect(output.toString(), '|');
    });
  });

  group('sticky modifiers', () {
    testWidgets('tapping Ctrl arms it without sending anything', (
      tester,
    ) async {
      await pumpBar(tester);

      await tester.tap(find.text('Ctrl'));
      await tester.pump();

      expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.armed);
      expect(
        output.toString(),
        isEmpty,
        reason: 'a modifier on its own is not input',
      );
    });

    testWidgets('an armed Ctrl applies to the next key and then releases', (
      tester,
    ) async {
      await pumpBar(tester);

      await tester.tap(find.text('Ctrl'));
      await tester.pump();
      await tester.tap(find.text('Esc'));
      await tester.pump();

      expect(
        modifiers.stateOf(StickyModifier.ctrl),
        ModifierState.off,
        reason: 'an armed modifier must not leak into the next keystroke',
      );
    });

    testWidgets('a locked Ctrl survives a key press', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.text('Ctrl'));
      await tester.pump();
      await tester.tap(find.text('Ctrl'));
      await tester.pump();
      await tester.tap(find.text('Tab'));
      await tester.pump();

      expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.locked);
    });

    testWidgets('modifier state is exposed to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBar(tester);

      await tester.tap(find.text('Ctrl'));
      await tester.pump();

      // State conveyed only by colour would be invisible to a screen reader,
      // so the button announces "armed" as its value.
      // Tooltip inserts its own Semantics inside ours, so walk the ancestors
      // rather than assuming which one carries the value.
      final ancestors = find
          .ancestor(of: find.text('Ctrl'), matching: find.byType(Semantics))
          .evaluate();
      final values = [
        for (final element in ancestors)
          tester
              .getSemantics(find.byElementPredicate((e) => e == element))
              .value,
      ];

      expect(values, contains('armed'));
      handle.dispose();
    });
  });

  group('expanding', () {
    testWidgets('function keys are hidden until asked for', (tester) async {
      await pumpBar(tester);

      expect(find.text('F1'), findsNothing);

      await tester.tap(find.byTooltip('More keys'));
      await tester.pumpAndSettle();

      expect(find.text('F1'), findsOneWidget);
    });
  });

  group('goldens', () {
    testWidgets('renders on a phone', (tester) async {
      await pumpBar(tester);

      await expectLater(
        find.byType(KeyAccessoryBar),
        matchesGoldenFile('goldens/key_bar_compact.png'),
      );
    });

    testWidgets('shows armed and locked states distinctly', (tester) async {
      await pumpBar(tester);

      await tester.tap(find.text('Ctrl'));
      await tester.pump();
      await tester.tap(find.text('Alt'));
      await tester.pump();
      await tester.tap(find.text('Alt'));
      await tester.pump();

      await expectLater(
        find.byType(KeyAccessoryBar),
        matchesGoldenFile('goldens/key_bar_modifiers.png'),
      );
    });

    testWidgets('renders expanded', (tester) async {
      await pumpBar(tester, size: mediumSize);
      await tester.tap(find.byTooltip('More keys'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(KeyAccessoryBar),
        matchesGoldenFile('goldens/key_bar_expanded.png'),
      );
    });
  });
}
