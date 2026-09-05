import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

void main() {
  testWidgets('the app boots into the terminal workspace', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: TerminoApp()));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveScaffold), findsOneWidget);
    expect(find.byType(TerminalScreen), findsOneWidget);
    expect(find.text('No sessions open'), findsOneWidget);
  });

  testWidgets('opening a session replaces the empty state with a terminal', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: TerminoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New session'));
    // The demo fixture reveals itself over a few hundred milliseconds; let it
    // finish so no timer is left pending at teardown.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('No sessions open'), findsNothing);
    expect(find.text('Demo'), findsOneWidget, reason: 'the tab is labelled');
  });

  testWidgets('navigating to another destination keeps the session alive', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: TerminoApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New session'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hosts'));
    await tester.pumpAndSettle();
    expect(find.text('Phase 3'), findsOneWidget);

    await tester.tap(find.text('Terminal'));
    await tester.pumpAndSettle();
    expect(
      find.text('Demo'),
      findsOneWidget,
      reason: 'the session must survive a trip through another destination',
    );
  });
}
