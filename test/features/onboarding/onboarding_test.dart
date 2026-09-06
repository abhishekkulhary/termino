@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/onboarding/presentation/onboarding_screen.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';
import '../../support/test_fonts.dart';

const _onADesktop = PlatformCapabilities(
  canRunLocalShell: true,
  canUseSsh: true,
  canUseBiometrics: true,
  hasWindowManagement: true,
  canReadUserSshConfig: true,
);

const _onIos = PlatformCapabilities(
  canRunLocalShell: false,
  localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
  canUseSsh: true,
  canUseBiometrics: true,
  hasWindowManagement: false,
  canReadUserSshConfig: false,
);

const _onTheWeb = PlatformCapabilities(
  canRunLocalShell: false,
  localShellUnavailableReason: LocalShellUnavailableReason.noProcessesInBrowser,
  canUseSsh: true,
  needsRelay: true,
  canUseBiometrics: false,
  hasWindowManagement: false,
  canReadUserSshConfig: false,
);

void main() {
  setUpAll(loadTerminalFont);

  testWidgets('a capable platform is told it has a local shell', (
    tester,
  ) async {
    final container = testContainer(capabilities: _onADesktop);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const OnboardingScreen(),
      size: const Size(560, 800),
      container: container,
    );

    expect(find.text('A shell on this device'), findsOneWidget);
    expect(find.text('No local shell here'), findsNothing);
  });

  testWidgets('iOS is told up front that it has none', (tester) async {
    final container = testContainer(capabilities: _onIos);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const OnboardingScreen(),
      size: const Size(560, 800),
      container: container,
    );

    // Finding this out by hunting for a missing button is a bad first five
    // minutes; saying it here is the whole reason onboarding exists.
    expect(find.text('No local shell here'), findsOneWidget);
    expect(
      find.textContaining('iOS does not allow apps to launch other programs'),
      findsOneWidget,
    );
  });

  testWidgets('the web is told it needs a relay', (tester) async {
    final container = testContainer(capabilities: _onTheWeb);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const OnboardingScreen(),
      size: const Size(560, 800),
      container: container,
    );

    expect(find.text('A relay is needed in a browser'), findsOneWidget);
  });

  testWidgets('completing it records the choice and shows the app', (
    tester,
  ) async {
    final container = testContainer(capabilities: _onADesktop);
    addTearDown(container.dispose);

    await pumpApp(tester, const TerminoApp(), container: container);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(TerminalScreen), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(TerminalScreen), findsOneWidget);
    expect(
      (await container.read(settingsStoreProvider).read()).onboardingComplete,
      isTrue,
      reason: 'it must not appear again on the next launch',
    );
  });

  testWidgets('a returning user does not see it', (tester) async {
    final container = testContainer(capabilities: _onADesktop);
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    await pumpApp(tester, const TerminoApp(), container: container);

    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('renders', (tester) async {
    final container = testContainer(capabilities: _onIos);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const OnboardingScreen(),
      size: const Size(560, 760),
      container: container,
    );

    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding.png'),
    );
  });
}
