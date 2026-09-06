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

/// The host list is where the app is judged before anything connects, so its
/// look is pinned: colour identity, live state, last use, and the actions that
/// save a trip through a menu.
void main() {
  setUpAll(loadTerminalFont);

  const capabilities = PlatformCapabilities(
    canRunLocalShell: true,
    canUseSsh: true,
    canUseBiometrics: false,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
  );

  Future<void> pumpHosts(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final container = testContainer(capabilities: capabilities);
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    final now = DateTime.now();
    final hosts = [
      SshHost(
        id: 'a',
        label: 'Build server',
        hostname: 'build-01.example.com',
        username: 'deploy',
        colorValue: 0xFF2BE3FF,
        folder: 'ci',
        lastConnectedAt: now.subtract(const Duration(minutes: 7)),
      ),
      SshHost(
        id: 'b',
        label: 'Raspberry Pi',
        hostname: 'pi.local',
        username: 'pi',
        colorValue: 0xFF2BE58B,
        lastConnectedAt: now.subtract(const Duration(hours: 5)),
      ),
      SshHost(
        id: 'c',
        label: 'Prod gateway',
        hostname: 'gw.prod.internal',
        username: 'ops',
        port: 2222,
        colorValue: 0xFFFF4D9D,
        jumpHostId: 'a',
        lastConnectedAt: now.subtract(const Duration(days: 3)),
      ),
      const SshHost(
        id: 'd',
        label: 'Backup box',
        hostname: 'backup.lan',
        username: 'root',
      ),
    ];
    for (final host in hosts) {
      await container.read(sshHostRepositoryProvider).save(host);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TerminoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hosts'));
    await tester.pumpAndSettle();
  }

  testWidgets('host cards on a desktop window', (tester) async {
    await pumpHosts(tester, const Size(1280, 800));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/hosts_expanded.png'),
    );
  });

  testWidgets('host cards on a phone', (tester) async {
    await pumpHosts(tester, const Size(390, 780));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/hosts_compact.png'),
    );
  });
}
