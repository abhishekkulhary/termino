import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/shared/design/app_theme.dart';

import 'test_database.dart';

/// Renders without animation, for the rest of this test.
///
/// Goldens have to be deterministic, and an entrance animation is not: a
/// `Future.delayed` schedules no frame, so `pumpAndSettle` can return before
/// the animation it is waiting for has even started, and the image is captured
/// half way through. Switching motion off at the platform level — the same
/// switch a user flips for reduce-motion — settles that, and exercises the
/// accessible path while it is at it.
void withoutAnimations(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// A phone-sized window.
const compactSize = Size(390, 780);

/// A medium window — a small tablet or a split-screen pane.
const mediumSize = Size(840, 700);

/// An expanded window — desktop.
const expandedSize = Size(1280, 800);

/// Pumps [child] inside the app's theme at [size].
///
/// Pass `animations: false` for a golden, where a half-finished entrance makes
/// the image non-deterministic. It is not the default: switching motion off
/// also shortens how long `pumpAndSettle` pumps, which leaves other work —
/// drift's stream teardown, for one — still pending when the test ends.
///
/// Riverpod 3 does not export its `Override` type, so a helper cannot declare
/// `List<Override>` in its signature. Tests that need overrides build a
/// container with `ProviderContainer.test(overrides: [...])` — where the type
/// is inferred — and pass it here.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Size size = expandedSize,
  Brightness brightness = Brightness.dark,
  ProviderContainer? container,
  bool animations = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  if (!animations) withoutAnimations(tester);

  // Defaults to an in-memory database and secret store. Anything that reads
  // settings — which now includes the terminal itself — would otherwise reach
  // for path_provider and fail with a MissingPluginException.
  final scope = container ?? testContainer();
  addTearDown(scope.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
