import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/features/known_hosts/presentation/known_hosts_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// A host key could be trusted and then never reviewed: the only route to
/// forgetting one was the mismatch dialog, which means something had already
/// gone wrong. This screen is the other half of taking verification seriously,
/// so what it shows and what forgetting actually does are pinned here.
void main() {
  const capabilities = PlatformCapabilities(
    canRunLocalShell: true,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: true,
    canReadUserSshConfig: true,
  );

  const noSshDirectory = PlatformCapabilities(
    canRunLocalShell: false,
    localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
  );

  final entry = KnownHost(
    host: 'build-01.example.com',
    port: 22,
    keyType: 'ssh-ed25519',
    fingerprint: 'SHA256:9pTx0hLKq1n7bWvR3sZmCd8yQeUj4aXfP2kNvB6tGwo',
    addedAt: DateTime.now().subtract(const Duration(days: 2)),
    source: KnownHostSource.trustOnFirstUse,
  );

  testWidgets('says so when nothing has been trusted', (tester) async {
    await pumpApp(
      tester,
      const KnownHostsScreen(),
      container: testContainer(capabilities: capabilities),
    );

    expect(find.text('Nothing trusted yet'), findsOneWidget);
  });

  testWidgets('lists a trusted key with its fingerprint', (tester) async {
    final container = testContainer(capabilities: capabilities);
    await container.read(knownHostsRepositoryProvider).add(entry);

    await pumpApp(tester, const KnownHostsScreen(), container: container);

    expect(find.text('build-01.example.com'), findsOneWidget);
    expect(
      find.textContaining('9pTx 0hLK'),
      findsOneWidget,
      reason: 'grouped the same way the dialogs show it',
    );
    expect(find.text('ssh-ed25519'), findsOneWidget);
    expect(find.textContaining('Trusted 2 days ago'), findsOneWidget);
  });

  testWidgets('a non-standard port is shown the way OpenSSH writes it', (
    tester,
  ) async {
    final container = testContainer(capabilities: capabilities);
    await container
        .read(knownHostsRepositoryProvider)
        .add(entry.copyWith(port: 2222));

    await pumpApp(tester, const KnownHostsScreen(), container: container);

    expect(find.text('[build-01.example.com]:2222'), findsOneWidget);
  });

  testWidgets('forgetting asks, and then really forgets', (tester) async {
    final container = testContainer(capabilities: capabilities);
    final repository = container.read(knownHostsRepositoryProvider);
    await repository.add(entry);

    await pumpApp(
      tester,
      const KnownHostsScreen(),
      container: container,
      size: compactSize,
    );

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Forget build-01.example.com?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Forget'));
    await tester.pumpAndSettle();
    // The list refetches from the database after being invalidated, and a
    // pending future schedules no frame — so `pumpAndSettle` can return before
    // the new, shorter list has arrived.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(
      await repository.all(),
      isEmpty,
      reason: 'the next connection should be a first sighting again',
    );
    expect(find.text('Nothing trusted yet'), findsOneWidget);
  });

  testWidgets('declining leaves the key trusted', (tester) async {
    final container = testContainer(capabilities: capabilities);
    final repository = container.read(knownHostsRepositoryProvider);
    await repository.add(entry);

    await pumpApp(
      tester,
      const KnownHostsScreen(),
      container: container,
      size: compactSize,
    );

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await repository.all(), hasLength(1));
  });

  group('the import', () {
    testWidgets('is offered where there is a ~/.ssh to read', (tester) async {
      await pumpApp(
        tester,
        const KnownHostsScreen(),
        container: testContainer(capabilities: capabilities),
      );

      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('is not offered where there is not', (tester) async {
      // A phone has no `~/.ssh`, and a button that cannot work is worse than
      // no button.
      await pumpApp(
        tester,
        const KnownHostsScreen(),
        container: testContainer(capabilities: noSshDirectory),
      );

      expect(find.text('Import'), findsNothing);
    });

    testWidgets('says plainly when it brought nothing across', (tester) async {
      // No saved hosts, so nothing in the user's file is relevant: importing
      // the whole thing would trust keys for machines this app has never been
      // asked about.
      await pumpApp(
        tester,
        const KnownHostsScreen(),
        container: testContainer(capabilities: capabilities),
      );

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing new to import'), findsOneWidget);
    });
  });
}
