import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/infrastructure/storage/database.dart';
import 'package:termino/infrastructure/storage/drift_repositories.dart';

import '../../support/test_database.dart';

/// The host list leads with what the user actually uses. That is a promise the
/// card design makes — "Connected 7 minutes ago" at the top — so the ordering
/// it depends on is pinned here rather than left to the default.
void main() {
  late TerminoDatabase db;
  late DriftSshHostRepository hosts;

  setUp(() {
    db = TerminoDatabase.withExecutor(NativeDatabase.memory());
    hosts = DriftSshHostRepository(db, InMemorySecretStore());
  });

  tearDown(() => db.close());

  SshHost host(String id, String label, {DateTime? connected}) => SshHost(
    id: id,
    label: label,
    hostname: '$id.example.com',
    username: 'user',
    lastConnectedAt: connected,
  );

  final now = DateTime.utc(2026, 9, 6, 12);

  test('most recently connected comes first', () async {
    await hosts.save(
      host('a', 'Alpha', connected: now.subtract(const Duration(days: 2))),
    );
    await hosts.save(
      host('b', 'Bravo', connected: now.subtract(const Duration(minutes: 5))),
    );
    await hosts.save(
      host('c', 'Charlie', connected: now.subtract(const Duration(hours: 3))),
    );

    expect((await hosts.all()).map((h) => h.label), [
      'Bravo',
      'Charlie',
      'Alpha',
    ]);
  });

  test('hosts never connected sort last, among themselves by label', () async {
    await hosts.save(host('z', 'Zulu'));
    await hosts.save(host('a', 'Alpha'));
    await hosts.save(
      host('u', 'Used', connected: now.subtract(const Duration(days: 400))),
    );

    expect((await hosts.all()).map((h) => h.label), ['Used', 'Alpha', 'Zulu']);
  });

  test('markConnected moves a host to the top', () async {
    await hosts.save(
      host('a', 'Alpha', connected: now.subtract(const Duration(minutes: 1))),
    );
    await hosts.save(host('b', 'Bravo'));

    expect((await hosts.all()).first.label, 'Alpha');

    await hosts.markConnected('b', now);

    expect((await hosts.all()).first.label, 'Bravo');
  });

  test('markConnected touches only the timestamp', () async {
    // It exists so that recording a connection cannot write back a stale copy
    // of everything else about the host.
    await hosts.save(
      host('a', 'Alpha').copyWith(port: 2222, folder: 'prod', colorValue: 42),
    );

    await hosts.markConnected('a', now);

    final saved = (await hosts.byId('a'))!;
    expect(saved.port, 2222);
    expect(saved.folder, 'prod');
    expect(saved.colorValue, 42);
    expect(saved.lastConnectedAt, now.toLocal());
  });

  test('the timestamp survives a round trip', () async {
    await hosts.save(host('a', 'Alpha', connected: now));
    expect((await hosts.byId('a'))?.lastConnectedAt, now.toLocal());
  });

  test('a host that has never connected reads as null, not as zero', () async {
    await hosts.save(host('a', 'Alpha'));
    expect((await hosts.byId('a'))?.lastConnectedAt, isNull);
  });
}
