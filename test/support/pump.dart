import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/shared/design/app_theme.dart';

import 'test_database.dart';

/// A phone-sized window.
const compactSize = Size(390, 780);

/// A medium window — a small tablet or a split-screen pane.
const mediumSize = Size(840, 700);

/// An expanded window — desktop.
const expandedSize = Size(1280, 800);

/// Pumps [child] inside the app's theme at [size].
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
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
