import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/shared/design/app_theme.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';

/// Motion here is decoration, and decoration must never be the reason someone
/// cannot use the app — or the reason a test hangs. Both are the same
/// property: nothing may animate forever when animations are switched off.
void main() {
  Widget wrap(Widget child, {required bool animations}) => MediaQuery(
    data: MediaQueryData(disableAnimations: !animations),
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('Reveal', () {
    testWidgets('animates its child in', (tester) async {
      await tester.pumpWidget(
        wrap(const Reveal(child: Text('hello')), animations: true),
      );
      await tester.pump();

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('hello'), matching: find.byType(Opacity)),
      );
      expect(
        opacity.opacity,
        lessThan(1),
        reason: 'it should start hidden and rise into place',
      );

      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('is already finished when animations are off', (tester) async {
      await tester.pumpWidget(
        wrap(const Reveal(child: Text('hello')), animations: false),
      );
      await tester.pump();

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('hello'), matching: find.byType(Opacity)),
      );
      expect(
        opacity.opacity,
        1,
        reason: 'reduce-motion means no motion, not faster motion',
      );
    });

    testWidgets('a staggered list still settles', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              for (var i = 0; i < 20; i++)
                Reveal.staggered(index: i, child: Text('row $i')),
            ],
          ),
          animations: true,
        ),
      );

      // Would time out if the stagger grew without bound.
      await tester.pumpAndSettle();
      expect(find.text('row 19'), findsOneWidget);
    });
  });

  group('StatusDot', () {
    testWidgets('a busy dot settles when animations are off', (tester) async {
      // The real check: with animations on this would never settle, and every
      // widget test that happened to show a connecting session would hang.
      await tester.pumpWidget(
        wrap(const StatusDot(status: ConnectionHealth.busy), animations: false),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StatusDot), findsOneWidget);
    });

    testWidgets('a resting dot settles even with animations on', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusDot(status: ConnectionHealth.online),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StatusDot), findsOneWidget);
    });
  });

  group('NeonBadge', () {
    testWidgets('draws nothing at zero', (tester) async {
      await tester.pumpWidget(
        wrap(const NeonBadge(count: 0), animations: false),
      );
      expect(find.text('0'), findsNothing);
    });

    testWidgets('caps the number it is willing to render', (tester) async {
      await tester.pumpWidget(
        wrap(const NeonBadge(count: 42), animations: false),
      );
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('a pulsing badge settles when animations are off', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const NeonBadge(count: 2, pulse: true), animations: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });
}
