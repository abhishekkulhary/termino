import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/settings/presentation/settings_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

const _onTheWeb = PlatformCapabilities(
  canRunLocalShell: false,
  localShellUnavailableReason: LocalShellUnavailableReason.noProcessesInBrowser,
  canUseSsh: true,
  needsRelay: true,
  canUseBiometrics: false,
  hasWindowManagement: false,
  canReadUserSshConfig: false,
);

const _onADesktop = PlatformCapabilities(
  canRunLocalShell: true,
  canUseSsh: true,
  canUseBiometrics: true,
  hasWindowManagement: true,
  canReadUserSshConfig: true,
);

void main() {
  testWidgets('the web build asks for a relay address', (tester) async {
    final container = testContainer(capabilities: _onTheWeb);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const Scaffold(body: SettingsScreen()),
      size: const Size(560, 1400),
      container: container,
    );

    expect(find.text('RELAY'), findsOneWidget);
    expect(find.text('Relay address'), findsOneWidget);
    expect(
      find.textContaining('cannot read your session'),
      findsOneWidget,
      reason: 'the trust boundary is worth stating where it is configured',
    );
    expect(
      find.textContaining('pin the relay certificate'),
      findsOneWidget,
      reason: 'the limitation is stated rather than left implicit',
    );
  });

  testWidgets('a desktop build does not mention a relay', (tester) async {
    final container = testContainer(capabilities: _onADesktop);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const Scaffold(body: SettingsScreen()),
      size: const Size(560, 1400),
      container: container,
    );

    expect(
      find.text('RELAY'),
      findsNothing,
      reason: 'a native build connects directly and never needs one',
    );
  });
}
