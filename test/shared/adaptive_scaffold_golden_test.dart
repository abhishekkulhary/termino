@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/destinations.dart';
import 'package:termino/shared/design/breakpoints.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

import '../support/pump.dart';
import '../support/test_fonts.dart';

Widget _shell() => AdaptiveScaffold(
  destinations: AppDestinations.all,
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  title: const Text('Terminal'),
  body: const Center(child: Text('content')),
);

void main() {
  setUpAll(loadTerminalFont);

  group('AdaptiveScaffold', () {
    testWidgets('uses bottom navigation on a compact window', (tester) async {
      await pumpApp(tester, _shell(), size: compactSize);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await expectLater(
        find.byType(AdaptiveScaffold),
        matchesGoldenFile('goldens/shell_compact.png'),
      );
    });

    testWidgets('uses a collapsed rail on a medium window', (tester) async {
      await pumpApp(tester, _shell(), size: mediumSize);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await expectLater(
        find.byType(AdaptiveScaffold),
        matchesGoldenFile('goldens/shell_medium.png'),
      );
    });

    testWidgets('uses an extended rail on an expanded window', (tester) async {
      await pumpApp(tester, _shell());

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);

      await expectLater(
        find.byType(AdaptiveScaffold),
        matchesGoldenFile('goldens/shell_expanded.png'),
      );
    });

    testWidgets('renders in the light theme too', (tester) async {
      await pumpApp(tester, _shell(), brightness: Brightness.light);

      await expectLater(
        find.byType(AdaptiveScaffold),
        matchesGoldenFile('goldens/shell_expanded_light.png'),
      );
    });

    testWidgets('a disabled destination cannot be selected', (tester) async {
      var selected = -1;
      await pumpApp(
        tester,
        AdaptiveScaffold(
          destinations: const [
            AppDestinations.terminal,
            AppDestination(
              label: 'Local shell',
              icon: Icons.block,
              selectedIcon: Icons.block,
              route: '/local',
              enabled: false,
              disabledReason: 'iOS does not permit running local programs.',
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (index) => selected = index,
          body: const SizedBox.shrink(),
        ),
        size: compactSize,
      );

      await tester.tap(find.text('Local shell'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        selected,
        -1,
        reason: 'a feature-gated destination must never navigate',
      );
    });
  });

  group('Breakpoints', () {
    test('classify widths into window sizes', () {
      expect(Breakpoints.of(0), WindowSize.compact);
      expect(Breakpoints.of(599), WindowSize.compact);
      expect(Breakpoints.of(600), WindowSize.medium);
      expect(Breakpoints.of(1023), WindowSize.medium);
      expect(Breakpoints.of(1024), WindowSize.expanded);
      expect(Breakpoints.of(2560), WindowSize.expanded);
    });

    test('report their layout affordances', () {
      expect(WindowSize.compact.supportsSplitPanes, isFalse);
      expect(WindowSize.medium.supportsSplitPanes, isTrue);
      expect(WindowSize.expanded.supportsSplitPanes, isTrue);
      expect(WindowSize.expanded.prefersSidebar, isTrue);
      expect(WindowSize.medium.prefersSidebar, isFalse);
    });
  });
}
