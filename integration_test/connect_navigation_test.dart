@Timeout(Duration(seconds: 120))
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/hosts/presentation/hosts_screen.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';

import '../test/support/test_database.dart';
import '../test/support/test_sshd.dart';

/// Connecting from the host list has to take the user to the terminal it
/// opened in. It did not: the session was created in a tab nobody was shown,
/// so a successful connection and a silent failure looked identical.
///
///     flutter test integration_test/connect_navigation_test.dart -d macos
///
/// An integration test rather than a widget test because it needs both a
/// widget tree and a real socket. Under the ordinary test binding the SSH
/// keepalive lands on the fake clock, which then never advances while real
/// network work is waited on, and closing the session hangs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!TestSshd.isSupported) {
    test('connecting needs a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  const capabilities = PlatformCapabilities(
    canRunLocalShell: false,
    localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
    canUseSsh: true,
    canUseBiometrics: false,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
  );

  late TestSshd server;

  setUp(() async => server = await TestSshd.start());
  tearDown(() => server.stop());

  testWidgets('connecting to a host lands on the terminal', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = testContainer(capabilities: capabilities);
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    // A key the throwaway server trusts, stored the way the app stores one.
    final identity = SshIdentity(
      id: 'test-key',
      name: 'Test key',
      keyType: SshKeyType.ed25519,
      publicKey: 'unused-for-authentication',
      fingerprint: 'SHA256:test',
      createdAt: DateTime.utc(2026),
    );

    await container
        .read(secretStoreProvider)
        .write(identity.secretRef, TestSshd.clientPrivateKey);
    await container.read(sshIdentityRepositoryProvider).save(identity);

    await container
        .read(sshHostRepositoryProvider)
        .save(
          SshHost(
            id: 'local',
            label: 'Throwaway server',
            hostname: '127.0.0.1',
            username: TestSshd.username,
            port: server.port,
            identityId: identity.id,
            authMethods: const [SshAuthMethod.publicKey],
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TerminoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hosts'));
    await tester.pumpAndSettle();
    expect(find.byType(HostsScreen), findsOneWidget);

    await tester.tap(find.text('Throwaway server'));
    await tester.pump();

    // The connection is real, and `pump` only advances the fake clock — the
    // socket needs wall-clock time, which is what `runAsync` gives it.
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      // First sight of this server's key: the trust prompt is expected, and
      // answering it is part of what a user does to connect.
      if (find.text('Trust and connect').evaluate().isNotEmpty) {
        await tester.tap(find.text('Trust and connect'));
        await tester.pump();
        continue;
      }

      if (find.byType(TerminalScreen).evaluate().isNotEmpty &&
          find.text('No sessions open').evaluate().isEmpty) {
        break;
      }
    }

    final onScreen = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();

    expect(
      find.byType(TerminalScreen),
      findsOneWidget,
      reason:
          'a successful connection should show the terminal it opened. '
          'On screen instead: $onScreen',
    );
    expect(
      find.text('No sessions open'),
      findsNothing,
      reason: 'the session should be the one on screen',
    );
    expect(find.text('Throwaway server'), findsWidgets);

    // A live SSH session keeps a real keepalive timer running, which the test
    // binding rightly refuses to leave behind.
    await tester.runAsync(
      () => container.read(sessionManagerProvider.notifier).closeAll(),
    );
    await tester.pump();
  });
}
