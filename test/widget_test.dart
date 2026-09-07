import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/shared/widgets/adaptive_scaffold.dart';

import 'support/test_database.dart';

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

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1280, 800)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = testContainer(capabilities: _noLocalShell);
  addTearDown(container.dispose);
  // These exercise the app proper; the first-run introduction has its own
  // tests and would otherwise stand in front of everything.
  await container.read(settingsProvider.notifier).completeOnboarding();

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TerminoApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Opens a session without a real backend, the way these tests need one.
Future<void> _openSession(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await container
      .read(sessionManagerProvider.notifier)
      .open(
        backend: MockBackend.text('ready'),
        title: 'Fixture',
        // Named apart from the title so a test can tell the tab from the
        // header: the header shows what the session *is*, the tab what the
        // program calls it.
        descriptor: 'me@fixture.example.com',
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
    final container = await _pumpApp(tester);
    await _openSession(tester, container);

    expect(find.text('No sessions open'), findsNothing);
    expect(find.text('Fixture'), findsOneWidget, reason: 'the tab is labelled');
    expect(
      find.text('me@fixture.example.com'),
      findsOneWidget,
      reason: 'the header names the session in front, not the screen',
    );
  });

  testWidgets('navigating to another destination keeps the session alive', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    await _openSession(tester, container);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('APPEARANCE'), findsOneWidget);

    await tester.tap(find.text('Terminal'));
    await tester.pumpAndSettle();
    expect(
      find.text('Fixture'),
      findsOneWidget,
      reason: 'the session must survive a trip through another destination',
    );
  });
}
