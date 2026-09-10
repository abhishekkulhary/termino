@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/settings/application/settings_controller.dart';

import '../support/pump.dart';
import '../support/test_database.dart';
import '../support/test_fonts.dart';

/// The screens without goldens of their own — the ones that stayed plain
/// Material while the rest of the app moved on. They are here so that a change
/// to the shared chrome, like the backdrop behind every screen, is seen rather
/// than discovered later.
void main() {
  setUpAll(loadTerminalFont);

  Future<void> shot(WidgetTester tester, String tab, String name) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    withoutAnimations(tester);

    final container = testContainer(
      capabilities: const PlatformCapabilities(
        canRunLocalShell: true,
        canUseSsh: true,
        canUseBiometrics: true,
        hasWindowManagement: true,
        canReadUserSshConfig: true,
      ),
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    // Keys and Tunnels need something in them to be worth a picture.
    await container
        .read(sshIdentityRepositoryProvider)
        .save(
          SshIdentity(
            id: 'k1',
            name: 'Laptop key',
            keyType: SshKeyType.ed25519,
            publicKey: 'ssh-ed25519 AAAA',
            fingerprint: 'SHA256:9pTx0hLKq1n7bWvR3sZmCd8yQeUj4aXfP2kNvB6tGwo',
            createdAt: DateTime.utc(2026, 3, 2),
            comment: 'me@laptop',
          ),
        );
    await container
        .read(sshIdentityRepositoryProvider)
        .save(
          SshIdentity(
            id: 'k2',
            name: 'Deploy key',
            keyType: SshKeyType.rsa,
            publicKey: 'ssh-rsa AAAA',
            fingerprint: 'SHA256:Lm4Qs8zXv1oPd7cRt5uYbN0hKeJf3aWgD6iBxT2nCqE',
            createdAt: DateTime.utc(2026, 1, 9),
            hasPassphrase: true,
          ),
        );

    await container
        .read(sshHostRepositoryProvider)
        .save(
          const SshHost(
            id: 'h1',
            label: 'Build server',
            hostname: 'build-01.example.com',
            username: 'deploy',
          ),
        );
    await container
        .read(portForwardRepositoryProvider)
        .save(
          const PortForward(
            id: 'f1',
            hostId: 'h1',
            kind: PortForwardKind.local,
            listenPort: 8080,
            destinationHost: 'localhost',
            destinationPort: 80,
            label: 'Staging web',
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TerminoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/screen_$name.png'),
    );
  }

  testWidgets('settings', (tester) => shot(tester, 'Settings', 'settings'));
  testWidgets('files', (tester) => shot(tester, 'Files', 'files'));
  testWidgets('keys', (tester) => shot(tester, 'Keys', 'keys'));
  testWidgets('tunnels', (tester) => shot(tester, 'Tunnels', 'tunnels'));
}
