import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

/// A platform with no local shell, so widget tests never spawn a real process.
/// The PTY itself is covered by `integration_test/local_pty_test.dart`, which
/// runs against a real shell.
const _noLocalShell = PlatformCapabilities(
  canRunLocalShell: false,
  localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
  canUseSsh: true,
  canUseBiometrics: true,
  hasWindowManagement: false,
  canReadUserSshConfig: false,
);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1280, 800)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(_noLocalShell),
      ],
      child: const TerminoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the app boots into the terminal workspace', (tester) async {
    await _pumpApp(tester);

    expect(find.byType(AdaptiveScaffold), findsOneWidget);
    expect(find.byType(TerminalScreen), findsOneWidget);
    expect(find.text('No sessions open'), findsOneWidget);
  });

  testWidgets('a platform without a local shell explains why', (tester) async {
    await _pumpApp(tester);

    expect(
      find.textContaining('iOS does not allow apps to launch other programs'),
      findsOneWidget,
    );
  });

  testWidgets('opening a session replaces the empty state', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Demo session'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('No sessions open'), findsNothing);
    expect(find.text('Demo'), findsOneWidget, reason: 'the tab is labelled');
  });

  testWidgets('navigating to another destination keeps the session alive', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Demo session'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Settings is still a placeholder, so this exercises navigation without
    // pulling in the database that Hosts and Keys need.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Phase 6'), findsOneWidget);

    await tester.tap(find.text('Terminal'));
    await tester.pumpAndSettle();
    expect(
      find.text('Demo'),
      findsOneWidget,
      reason: 'the session must survive a trip through another destination',
    );
  });
}
