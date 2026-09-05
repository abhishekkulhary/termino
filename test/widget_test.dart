// Phase 0 smoke test: the app boots and the terminal renders.

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/main.dart';
import 'package:xterm/xterm.dart';

void main() {
  testWidgets('app boots and renders a terminal', (tester) async {
    await tester.pumpWidget(const TerminoSmokeTestApp());
    await tester.pump();

    expect(find.byType(TerminalView), findsOneWidget);
  });
}
