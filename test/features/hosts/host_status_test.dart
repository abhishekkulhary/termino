import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/application/connection_pool.dart';
import 'package:termino/features/hosts/presentation/host_editor_screen.dart';
import 'package:termino/features/hosts/presentation/hosts_screen.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';
import 'package:termino/shared/widgets/neon.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// What a host row says about itself: whether it is up, and when it last was.
/// Both were wrong in ways that only show after doing something — connecting
/// and then disconnecting, or editing a host that had been connected to.
void main() {
  // Truncated to the millisecond, which is the resolution the store keeps:
  // comparing microseconds would fail on a round trip that is working.
  final connectedAt = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().subtract(const Duration(minutes: 7)).millisecondsSinceEpoch,
  );

  SshHost hostRow() => SshHost(
    id: 'a',
    label: 'Build server',
    hostname: 'build-01.example.com',
    username: 'deploy',
    lastConnectedAt: connectedAt,
  );

  /// What the host card is currently showing.
  ConnectionHealth? shownHealth(WidgetTester tester) =>
      tester.widget<NeonListCard>(find.byType(NeonListCard)).status;

  testWidgets('the dot goes out when the last thing on a host lets go', (
    tester,
  ) async {
    // It did not. The pool was read with `ref.watch`, which hands back the
    // same long-lived object every time, so nothing rebuilt when the
    // connection closed and the host sat there looking connected.
    final pool = SshConnectionPool(
      open: (_) async => SshConnection(client: _FakeClient(), hops: const []),
    );
    addTearDown(pool.dispose);

    final container = testContainer(connectionPool: pool);
    addTearDown(container.dispose);
    await container.read(sshHostRepositoryProvider).save(hostRow());

    // Connected with no terminal tab open — the file browser alone, say.
    final lease = await pool.acquire(hostRow());
    await pumpApp(tester, const HostsScreen(), container: container);

    expect(shownHealth(tester), ConnectionHealth.online);

    await lease.release();
    await tester.pumpAndSettle();

    expect(
      shownHealth(tester),
      ConnectionHealth.idle,
      reason: 'nothing is on the host any more, and the row should say so',
    );
  });

  testWidgets('a host nothing is attached to is idle from the start', (
    tester,
  ) async {
    final pool = SshConnectionPool(
      open: (_) async => SshConnection(client: _FakeClient(), hops: const []),
    );
    addTearDown(pool.dispose);

    final container = testContainer(connectionPool: pool);
    addTearDown(container.dispose);
    await container.read(sshHostRepositoryProvider).save(hostRow());

    await pumpApp(tester, const HostsScreen(), container: container);

    expect(shownHealth(tester), ConnectionHealth.idle);
  });

  testWidgets('the row says when it was last connected', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);
    await container.read(sshHostRepositoryProvider).save(hostRow());

    await pumpApp(tester, const HostsScreen(), container: container);

    expect(find.textContaining('7 minutes ago'), findsOneWidget);
  });

  testWidgets('reaching a host any way records that it was reached', (
    tester,
  ) async {
    // Recorded when a shell opened, and nowhere else: an afternoon in the file
    // browser left the host looking untouched. It is now recorded by the pool,
    // which every route to a host goes through.
    final marked = <String>[];
    final pool = SshConnectionPool(
      open: (_) async => SshConnection(client: _FakeClient(), hops: const []),
      onUsed: (host) => marked.add(host.id),
    );
    addTearDown(pool.dispose);

    await pool.acquire(hostRow());
    await pool.acquire(hostRow());

    expect(marked, [
      'a',
      'a',
    ], reason: 'attaching to a connection already up still counts as using it');
  });

  testWidgets('editing a host keeps when it was last connected', (
    tester,
  ) async {
    // The form has no field for this, so saving must carry it over. It does
    // survive without the editor's help — drift's upsert treats a null as
    // "leave it alone" — and this pins the behaviour to the screen rather than
    // to that detail of the storage layer.
    final container = testContainer();
    addTearDown(container.dispose);

    final repository = container.read(sshHostRepositoryProvider);
    await repository.save(hostRow());

    await pumpApp(
      tester,
      HostEditorScreen(host: hostRow()),
      container: container,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Renamed',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await repository.all()).single;
    expect(saved.label, 'Renamed');
    expect(
      saved.lastConnectedAt,
      connectedAt,
      reason: 'the connection history is not one of the fields being edited',
    );
  });
}

/// An `SSHClient` that never touches a network.
class _FakeClient implements SSHClient {
  var _closed = false;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> get done => Completer<void>().future;

  @override
  Future<void> close() async => _closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
