// Renders the Phase 0 smoke test screen and compares it against a golden.
//
// This is the visual proof that xterm actually paints — a widget test that only
// asserts `findsOneWidget` would pass even if the terminal rendered nothing.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/main.dart';

void main() {
  testWidgets('smoke test screen renders', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TerminoSmokeTestApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/smoke_test.png'),
    );
  });
}
