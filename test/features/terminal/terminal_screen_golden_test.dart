@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';
import '../../support/test_fonts.dart';

const _withLocalShell = PlatformCapabilities(
  canRunLocalShell: true,
  canUseSsh: true,
  canUseBiometrics: true,
  hasWindowManagement: true,
  canReadUserSshConfig: true,
);

const _withoutLocalShell = PlatformCapabilities(
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
  canUseBiometrics: false,
  hasWindowManagement: false,
  canReadUserSshConfig: false,
);

Future<void> _pump(
  WidgetTester tester,
  PlatformCapabilities capabilities, {
  Size size = const Size(720, 560),
}) async {
  await pumpApp(
    tester,
    const Scaffold(body: TerminalScreen()),
    size: size,
    container: testContainer(capabilities: capabilities),
  );
}

void main() {
  setUpAll(loadTerminalFont);

  testWidgets('a platform with no local shell explains itself', (tester) async {
    await _pump(tester, _withoutLocalShell);

    expect(find.text('Demo session'), findsOneWidget);
    await expectLater(
      find.byType(TerminalScreen),
      matchesGoldenFile('goldens/empty_state_no_local_shell.png'),
    );
  });

  testWidgets('the web explains its own, different reason', (tester) async {
    await _pump(tester, _onTheWeb);

    expect(
      find.textContaining('browser tab has no operating system'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(TerminalScreen),
      matchesGoldenFile('goldens/empty_state_web.png'),
    );
  });

  testWidgets('a capable platform offers no unavailability notice', (
    tester,
  ) async {
    // shellProfilesProvider still discovers real shells here, so this asserts
    // only the absence of the notice, which does not depend on the machine.
    await _pump(tester, _withLocalShell);

    expect(find.textContaining('does not allow apps to launch'), findsNothing);
    expect(
      find.textContaining('browser tab has no operating system'),
      findsNothing,
    );
  });
}
