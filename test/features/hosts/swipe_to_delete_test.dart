import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/features/forwarding/presentation/forwarding_screen.dart';
import 'package:termino/features/hosts/presentation/hosts_screen.dart';
import 'package:termino/features/identities/presentation/identities_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// Swipe is a shortcut, not the only way, and never a shortcut past the
/// confirmation. These lists are flicked through on a phone in one hand, and a
/// horizontal drag is exactly the mis-gesture that happens there.
void main() {
  const capabilities = PlatformCapabilities(
    canRunLocalShell: true,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: true,
    canReadUserSshConfig: true,
  );

  /// Drags [row] far enough to the left to count as a dismissal.
  Future<void> swipeAway(WidgetTester tester, Finder row) async {
    await tester.drag(row, const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  group('hosts', () {
    Future<ProviderContainer> pumpHosts(WidgetTester tester) async {
      final container = testContainer(capabilities: capabilities);
      await container
          .read(sshHostRepositoryProvider)
          .save(
            const SshHost(
              id: 'a',
              label: 'Build server',
              hostname: 'build-01.example.com',
              username: 'deploy',
            ),
          );
      await pumpApp(
        tester,
        const HostsScreen(),
        container: container,
        size: compactSize,
      );
      return container;
    }

    testWidgets('a swipe asks before deleting', (tester) async {
      final container = await pumpHosts(tester);

      await swipeAway(tester, find.text('Build server'));
      expect(find.text('Delete Build server?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        await container.read(sshHostRepositoryProvider).all(),
        hasLength(1),
        reason: 'declining a swipe must leave the host alone',
      );
      expect(find.text('Build server'), findsOneWidget);
    });

    testWidgets('confirming a swipe deletes it', (tester) async {
      final container = await pumpHosts(tester);

      await swipeAway(tester, find.text('Build server'));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await container.read(sshHostRepositoryProvider).all(), isEmpty);
      expect(find.text('Build server'), findsNothing);
    });

    testWidgets('the row survives a swipe that was declined', (tester) async {
      // A declined swipe must leave the list in a usable state — no widget
      // half-dismissed, no exception, and the row still swipeable afterwards.
      // The row is dropped by the database stream, never by `Dismissible`.
      await pumpHosts(tester);

      await swipeAway(tester, find.text('Build server'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HostsScreen), findsOneWidget);

      // And it can be swiped again, so nothing was left half-dismissed.
      await swipeAway(tester, find.text('Build server'));
      expect(find.text('Delete Build server?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('deleting leaves no exception behind', (tester) async {
      await pumpHosts(tester);

      await swipeAway(tester, find.text('Build server'));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('keys', () {
    testWidgets('a swipe asks before deleting a key', (tester) async {
      final container = testContainer(capabilities: capabilities);
      final identity = SshIdentity(
        id: 'k1',
        name: 'Laptop key',
        keyType: SshKeyType.ed25519,
        publicKey: 'ssh-ed25519 AAAA',
        fingerprint: 'SHA256:abc',
        createdAt: DateTime.utc(2026),
      );
      await container.read(sshIdentityRepositoryProvider).save(identity);

      await pumpApp(
        tester,
        const IdentitiesScreen(),
        container: container,
        size: compactSize,
      );

      await swipeAway(tester, find.text('Laptop key'));
      expect(find.text('Delete Laptop key?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Laptop key'), findsOneWidget);
    });
  });

  group('tunnels', () {
    testWidgets('a swipe asks before deleting a tunnel', (tester) async {
      // This delete had no confirmation at all until a drag could reach it.
      final container = testContainer(capabilities: capabilities);
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

      await pumpApp(
        tester,
        const ForwardingScreen(),
        container: container,
        size: compactSize,
      );

      await swipeAway(tester, find.text('Staging web'));
      expect(find.text('Delete Staging web?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Staging web'), findsOneWidget);
    });
  });
}
