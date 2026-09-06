@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/settings/application/settings_controller.dart';

import '../../support/test_database.dart';
import '../../support/test_fonts.dart';

/// The palette is the app's most visually distinctive surface, so it gets a
/// golden of its own: a glowing panel over a dimmed workspace, grouped
/// results, and the keyboard hints along the bottom.
void main() {
  setUpAll(loadTerminalFont);

  testWidgets('the palette over a full workspace', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = testContainer(
      capabilities: const PlatformCapabilities(
        canRunLocalShell: true,
        canUseSsh: true,
        canUseBiometrics: false,
        hasWindowManagement: false,
        canReadUserSshConfig: false,
      ),
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    for (final host in const [
      SshHost(
        id: 'a',
        label: 'Build server',
        hostname: 'build-01.example.com',
        username: 'deploy',
      ),
      SshHost(
        id: 'b',
        label: 'Raspberry Pi',
        hostname: 'pi.local',
        username: 'pi',
      ),
      SshHost(
        id: 'c',
        label: 'Prod gateway',
        hostname: 'gw.prod.internal',
        username: 'ops',
        port: 2222,
      ),
    ]) {
      await container.read(sshHostRepositoryProvider).save(host);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TerminoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Command palette'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/command_palette.png'),
    );
  });
}
