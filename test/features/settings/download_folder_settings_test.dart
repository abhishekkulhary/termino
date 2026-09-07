import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/settings/presentation/settings_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// Where downloads go is only a question worth asking where a person has a
/// filesystem they navigate by hand.
void main() {
  const onADesktop = PlatformCapabilities(
    canRunLocalShell: true,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: true,
    canReadUserSshConfig: true,
    canChooseFolders: true,
  );

  const onAPhone = PlatformCapabilities(
    canRunLocalShell: false,
    localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
  );

  testWidgets('a desktop build offers to remember a folder', (tester) async {
    final container = testContainer(capabilities: onADesktop);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const Scaffold(body: SettingsScreen()),
      size: const Size(560, 1600),
      container: container,
    );

    expect(find.text('FILES'), findsOneWidget);
    expect(find.text('Save downloads to'), findsOneWidget);
    expect(
      find.text('Ask the first time, then remember'),
      findsOneWidget,
      reason: 'the default is stated rather than left blank',
    );
  });

  testWidgets('a phone does not offer a choice of one', (tester) async {
    // The app's own documents folder is the only place a download can go
    // there, so a row offering to change it would be offering nothing.
    final container = testContainer(capabilities: onAPhone);
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const Scaffold(body: SettingsScreen()),
      size: const Size(560, 1600),
      container: container,
    );

    expect(find.text('Save downloads to'), findsNothing);
  });

  testWidgets('a chosen folder is shown, and can be forgotten', (tester) async {
    final container = testContainer(capabilities: onADesktop);
    addTearDown(container.dispose);

    await container
        .read(settingsProvider.notifier)
        .setDownloadDirectory('/Users/me/Downloads');

    await pumpApp(
      tester,
      const Scaffold(body: SettingsScreen()),
      size: const Size(560, 1600),
      container: container,
    );

    expect(find.text('/Users/me/Downloads'), findsOneWidget);

    await tester.tap(find.byTooltip('Forget this folder'));
    await tester.pumpAndSettle();

    expect(container.read(currentSettingsProvider).downloadDirectory, isNull);
    expect(find.text('Ask the first time, then remember'), findsOneWidget);
  });
}
