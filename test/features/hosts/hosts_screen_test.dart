import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/presentation/host_editor_screen.dart';
import 'package:termino/features/hosts/presentation/hosts_screen.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

void main() {
  testWidgets('shows an empty state when nothing is saved', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, const HostsScreen(), container: container);

    expect(find.text('No saved hosts'), findsOneWidget);
    expect(find.text('Add host'), findsOneWidget);
  });

  testWidgets('the empty state points at where hosts are actually added', (
    tester,
  ) async {
    // It used to send people to Settings to import their ~/.ssh/config. There
    // is no importer in Settings — it lives behind the Add host button on this
    // screen — so anyone who followed the instruction found nothing.
    final container = testContainer(
      capabilities: PlatformCapabilities.detect(platform: TargetPlatform.macOS),
    );
    addTearDown(container.dispose);

    await pumpApp(tester, const HostsScreen(), container: container);

    expect(find.textContaining('Add host'), findsWidgets);
    expect(
      find.textContaining('Settings'),
      findsNothing,
      reason: 'nothing about hosts is in Settings',
    );
    expect(find.textContaining('~/.ssh/config'), findsOneWidget);
  });

  testWidgets('and does not offer an import where there is none', (
    tester,
  ) async {
    // A phone has no ~/.ssh to read, so the Add host button carries no import
    // option there and the empty state must not promise one.
    final container = testContainer(
      capabilities: PlatformCapabilities.detect(
        platform: TargetPlatform.android,
      ),
    );
    addTearDown(container.dispose);

    await pumpApp(tester, const HostsScreen(), container: container);

    expect(find.text('No saved hosts'), findsOneWidget);
    expect(find.textContaining('~/.ssh/config'), findsNothing);
  });

  testWidgets('lists saved hosts with their target', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await container
        .read(sshHostRepositoryProvider)
        .save(
          const SshHost(
            id: 'a',
            label: 'Build server',
            hostname: 'build-01.example.com',
            username: 'deploy',
            port: 2222,
          ),
        );

    await pumpApp(tester, const HostsScreen(), container: container);

    expect(find.text('Build server'), findsOneWidget);
    expect(find.text('deploy@build-01.example.com:2222'), findsOneWidget);
  });

  testWidgets('the editor validates required fields', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, const HostEditorScreen(), container: container);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give the connection a name'), findsOneWidget);
    expect(find.text('Enter a hostname or address'), findsOneWidget);
    expect(find.text('Enter a username'), findsOneWidget);
  });

  testWidgets('the editor rejects an out-of-range port', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, const HostEditorScreen(), container: container);

    await tester.enterText(find.widgetWithText(TextFormField, 'Port'), '70000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('1–65535'), findsOneWidget);
  });

  testWidgets('the editor saves a valid host', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, const HostEditorScreen(), container: container);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Web');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Host'),
      'web.example.com',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'User'), 'root');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await container.read(sshHostRepositoryProvider).all();
    expect(saved, hasLength(1));
    expect(saved.single.label, 'Web');
    expect(saved.single.hostname, 'web.example.com');
    expect(saved.single.username, 'root');
    expect(saved.single.port, 22);
  });

  testWidgets('editing an existing host keeps its id', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    const existing = SshHost(
      id: 'keep-me',
      label: 'Old',
      hostname: 'old.example.com',
      username: 'root',
    );
    await container.read(sshHostRepositoryProvider).save(existing);

    await pumpApp(
      tester,
      const HostEditorScreen(host: existing),
      container: container,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'New');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await container.read(sshHostRepositoryProvider).all();
    expect(saved, hasLength(1), reason: 'editing must not create a duplicate');
    expect(saved.single.id, 'keep-me');
    expect(saved.single.label, 'New');
  });
}
