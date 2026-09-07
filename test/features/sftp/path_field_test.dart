// The path field against a real SFTP server.
//
// Split deliberately. What the widget does on its own — becoming a field,
// cancelling, offering where the session has been — is tested by pumping it.
// What needs the server is tested through the session directly, because real
// socket I/O does not complete inside the test binding's fake-async zone: a
// widget test that awaited it would hang rather than fail.
@Timeout(Duration(seconds: 120))
library;

import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/sftp/application/sftp_session.dart';
import 'package:termino/features/sftp/presentation/path_field.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

import '../../support/direct_hold.dart';
import '../../support/in_memory_known_hosts.dart';
import '../../support/pump.dart';
import '../../support/test_sshd.dart';

void main() {
  if (!TestSshd.isSupported) {
    test('the path field needs a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late SftpSession session;
  late Directory workspace;

  setUp(() async {
    server = await TestSshd.start();
    workspace = await Directory.systemTemp.createTemp('termino-path-');

    // A tree with names that share prefixes, which is where completion is
    // either useful or wrong.
    for (final name in ['projects', 'project-notes', 'public']) {
      await Directory('${workspace.path}/$name').create();
    }
    await Directory('${workspace.path}/projects/inner').create();
    await File('${workspace.path}/prospectus.txt').writeAsString('not a dir');

    final host = SshHost(
      id: 'paths',
      label: 'Test server',
      hostname: '127.0.0.1',
      username: TestSshd.username,
      port: server.port,
    );
    final connection =
        await SshConnectionFactory(
          verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
          onHostKeyPrompt: (_) async => true,
        ).connect(
          host: host,
          prompts: SshAuthPrompts(
            identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
          ),
        );
    final client = await connection.client.sftp();

    session = SftpSession(
      host: host,
      lease: DirectHold(connection),
      service: SftpService(client),
      client: client,
    );
    await session.open(workspace.path);
  });

  tearDown(() async {
    await session.dispose();
    await server.stop();
    if (workspace.existsSync()) await workspace.delete(recursive: true);
  });

  /// Pumps the field and opens it for editing.
  Future<void> pumpEditing(WidgetTester tester) async {
    await pumpApp(tester, Scaffold(body: PathField(session: session)));
    await tester.tap(find.byType(PathField));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the path, and turns into a field when tapped', (
    tester,
  ) async {
    await pumpApp(tester, Scaffold(body: PathField(session: session)));

    expect(find.text(session.path), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(PathField));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  test('typing a path navigates there', () async {
    await session.open('${workspace.path}/projects/inner');

    expect(session.path, endsWith('/projects/inner'));
  });

  test('a path that does not exist reports rather than moves', () async {
    final before = session.path;

    await session.open('/no/such/place');

    expect(session.path, before);
    expect(session.error, isNotNull);
  });

  test('completion offers the directories under what was typed', () async {
    // `prospectus.txt` starts with `pro` and is not somewhere you can go.
    final names = await session.completionsFor('${workspace.path}/pro');

    expect(names, containsAll(['projects', 'project-notes', 'public']));
    expect(names, isNot(contains('prospectus.txt')));
  });

  test('completing a relative fragment looks where the browser is', () async {
    final names = await session.completionsFor('pro');

    expect(names, contains('projects'));
  });

  test('completing somewhere that does not exist offers nothing', () async {
    // The ordinary case while somebody is still typing, not an error.
    expect(await session.completionsFor('/no/such/place/x'), isEmpty);
  });

  testWidgets('Escape puts the path back and navigates nowhere', (
    tester,
  ) async {
    final before = session.path;
    await pumpEditing(tester);

    await tester.enterText(find.byType(TextField), '/etc');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(session.path, before);
  });

  test('where the session has been is remembered, newest first', () async {
    await session.open('${workspace.path}/projects');
    await session.open('${workspace.path}/public');
    await session.open('${workspace.path}/projects');

    expect(session.recentPaths.first, endsWith('/projects'));
    expect(
      session.recentPaths.where((path) => path.endsWith('/projects')),
      hasLength(1),
      reason: 'going back somewhere does not list it twice',
    );
    // Against a suffix, not the path typed: the server resolves it, and on
    // macOS `/var` comes back as `/private/var`. What is remembered is what
    // the server said, which is what navigating back to it needs.
    expect(session.recentPaths.any((path) => path.endsWith('/public')), isTrue);
  });

  testWidgets('editing offers where the session has been', (tester) async {
    // Navigating happens in `setUp`, outside the widget binding: real socket
    // I/O does not complete inside its fake-async zone, so a test that awaited
    // a listing here would hang rather than fail.
    await pumpEditing(tester);

    expect(
      find.text(session.path),
      findsWidgets,
      reason: 'the menu offers somewhere already visited',
    );
  });

  group('the keys, against a stubbed listing', () {
    // The server is stubbed here for one reason: a widget test cannot await a
    // socket, because the binding's fake-async zone never lets one finish —
    // checked directly, and the listing came back empty and late. What the
    // server would actually have said is tested above, against a real one.
    const names = ['projects', 'project-notes', 'public'];

    Future<void> pumpStubbed(WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: PathField(session: session, completions: (_) async => names),
        ),
      );
      await tester.tap(find.byType(PathField));
      await tester.pumpAndSettle();
    }

    /// What the field currently reads.
    String text(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('Tab fills in as far as the names agree', (tester) async {
      await pumpStubbed(tester);

      await tester.enterText(find.byType(TextField), '/srv/pro');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        text(tester),
        '/srv/project',
        reason: 'projects and project-notes agree this far and no further',
      );
    });

    testWidgets('Tab completes a single match and descends', (tester) async {
      await pumpStubbed(tester);

      await tester.enterText(find.byType(TextField), '/srv/pub');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(text(tester), '/srv/public/');
    });

    testWidgets('Tab on nothing matching leaves the typing alone', (
      tester,
    ) async {
      await pumpStubbed(tester);

      await tester.enterText(find.byType(TextField), '/srv/zzz');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(text(tester), '/srv/zzz');
    });

    testWidgets('what is typed is offered as a list to pick from', (
      tester,
    ) async {
      await pumpStubbed(tester);

      await tester.enterText(find.byType(TextField), '/srv/pro');
      await tester.pumpAndSettle();

      expect(find.text('/srv/projects'), findsOneWidget);
      expect(find.text('/srv/project-notes'), findsOneWidget);
      expect(
        find.text('/srv/public'),
        findsNothing,
        reason: 'it does not start with what was typed',
      );
    });
  });
}
