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
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';

import '../support/pump.dart';
import '../support/test_database.dart';
import '../support/test_fonts.dart';

/// The light theme has no glow to lean on, so everything that carries meaning
/// in the dark — depth, selection, a host's colour — has to be carried some
/// other way. It went unwatched once and drifted into a flat, illegible
/// version of itself; these are the three screens that showed it worst.
void main() {
  setUpAll(loadTerminalFont);

  const capabilities = PlatformCapabilities(
    canRunLocalShell: true,
    canUseSsh: true,
    canUseBiometrics: false,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
  );

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    withoutAnimations(tester);

    final container = testContainer(capabilities: capabilities);
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    final now = DateTime.now();
    for (final host in [
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
    return container;
  }

  testWidgets('host cards, where accent colours have to be adapted', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Hosts'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/light_hosts.png'),
    );
  });

  testWidgets('the palette, which is a surface above a surface', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Command palette'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/light_palette.png'),
    );
  });

  testWidgets('a live terminal and its readout', (tester) async {
    final container = await pump(tester);
    await container
        .read(sessionManagerProvider.notifier)
        .open(
          backend: MockBackend.text(
            r'$ uname -a'
            '\n'
            'Linux pi 6.1.0 aarch64',
          ),
          title: 'pi',
        );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/light_terminal.png'),
    );
  });
}
