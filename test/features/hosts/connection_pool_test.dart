import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/application/connection_pool.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

/// One authentication per host, shared by the shell, the file browser and any
/// forwards. Everything here is about the two ways that goes wrong: asking for
/// a password twice, and closing a connection somebody is still using.
void main() {
  const host = SshHost(
    id: 'a',
    label: 'Build server',
    hostname: 'build.example.com',
    username: 'deploy',
  );
  const other = SshHost(
    id: 'b',
    label: 'Other',
    hostname: 'other.example.com',
    username: 'deploy',
  );

  late int authentications;
  late List<_FakeClient> opened;
  late Completer<void>? gate;

  /// A pool whose connections are fakes, so nothing here touches a network.
  SshConnectionPool poolThat({Exception? failsWith}) {
    authentications = 0;
    opened = [];
    return SshConnectionPool(
      open: (host) async {
        authentications++;
        if (gate != null) await gate!.future;
        if (failsWith != null) throw failsWith;

        final client = _FakeClient();
        opened.add(client);
        return SshConnection(client: client, hops: const []);
      },
    );
  }

  setUp(() => gate = null);

  test(
    'a second consumer of the same host does not authenticate again',
    () async {
      // The whole point: opening the file browser for a host you already have a
      // shell on must not ask for a password.
      final pool = poolThat();

      final shell = await pool.acquire(host);
      final files = await pool.acquire(host);

      expect(authentications, 1);
      expect(identical(shell.client, files.client), isTrue);
    },
  );

  test('two consumers asking at once share one authentication', () async {
    // Opening the terminal and the browser together used to prompt twice.
    gate = Completer<void>();
    final pool = poolThat();

    final both = Future.wait([pool.acquire(host), pool.acquire(host)]);
    gate!.complete();
    final leases = await both;

    expect(authentications, 1);
    expect(identical(leases.first.client, leases.last.client), isTrue);
  });

  test('different hosts get their own connections', () async {
    final pool = poolThat();

    await pool.acquire(host);
    await pool.acquire(other);

    expect(authentications, 2);
    expect(opened, hasLength(2));
  });

  test(
    'releasing one lease leaves the connection open for the other',
    () async {
      // The part of the old isolation worth keeping: closing the file browser
      // must not kill a shell someone has work in progress in.
      final pool = poolThat();
      final shell = await pool.acquire(host);
      final files = await pool.acquire(host);

      await files.release();

      expect(opened.single.closed, isFalse);
      expect(pool.isConnected(host.id), isTrue);
      expect(pool.leaseCount(host.id), 1);
      expect(shell.isReleased, isFalse);
    },
  );

  test('releasing the last lease closes the connection', () async {
    final pool = poolThat();
    final shell = await pool.acquire(host);
    final files = await pool.acquire(host);

    await files.release();
    await shell.release();

    expect(opened.single.closed, isTrue);
    expect(pool.isConnected(host.id), isFalse);
  });

  test('releasing twice does not close somebody else out', () async {
    // A dispose that runs twice is ordinary; double-counting it would close a
    // connection another feature is still holding.
    final pool = poolThat();
    final shell = await pool.acquire(host);
    final files = await pool.acquire(host);

    await files.release();
    await files.release();

    expect(pool.leaseCount(host.id), 1);
    expect(opened.single.closed, isFalse);
    expect(shell.isReleased, isFalse);
  });

  test('a connection that dropped is replaced, not handed out again', () async {
    final pool = poolThat();
    final first = await pool.acquire(host);
    opened.single.drop();
    await pumpEventQueue();

    final second = await pool.acquire(host);

    expect(authentications, 2, reason: 'a dead connection is reconnected');
    expect(identical(first.client, second.client), isFalse);
  });

  test('a drop is noticed even before its handler runs', () async {
    // `done` completes asynchronously. Between the transport dying and the
    // pool hearing about it, an acquire must not be handed the corpse.
    final pool = poolThat();
    await pool.acquire(host);
    opened.single.closeWithoutNotifying();

    final replacement = await pool.acquire(host);

    expect(authentications, 2);
    expect(replacement.client, isNot(same(opened.first)));
  });

  test('a failed connection is not cached', () async {
    // Handing out the same exception forever would mean a host that was down
    // once stays broken until the app restarts.
    final failing = poolThat(failsWith: const FormatException('refused'));

    await expectLater(failing.acquire(host), throwsFormatException);
    await expectLater(failing.acquire(host), throwsFormatException);

    expect(authentications, 2);
    expect(failing.isConnected(host.id), isFalse);
  });

  test('disconnecting closes it whatever is holding it', () async {
    final pool = poolThat();
    await pool.acquire(host);
    await pool.acquire(host);

    await pool.disconnect(host.id);

    expect(opened.single.closed, isTrue);
    expect(pool.isConnected(host.id), isFalse);
  });

  test('disconnecting everything leaves nothing open', () async {
    final pool = poolThat();
    await pool.acquire(host);
    await pool.acquire(other);

    await pool.disconnectAll();

    expect(opened.every((client) => client.closed), isTrue);
    expect(pool.isConnected(host.id), isFalse);
    expect(pool.isConnected(other.id), isFalse);
  });

  test('a close that throws does not take the caller down', () async {
    // Closing happens in disposes, which cannot handle an exception.
    final pool = SshConnectionPool(
      open: (_) async => SshConnection(
        client: _FakeClient(throwOnClose: true),
        hops: const [],
      ),
    );
    final lease = await pool.acquire(host);

    await expectLater(lease.release(), completes);
  });
}

/// An `SSHClient` that never touches a network.
///
/// Only the three things the pool actually uses are implemented — `isClosed`,
/// `done` and `close` — because those are the whole of its contract with a
/// connection, and a fake that pretended to more would be pretending.
class _FakeClient implements SSHClient {
  new({this.throwOnClose = false});

  /// Whether closing blows up, as a connection already gone can.
  final bool throwOnClose;

  final _done = Completer<void>();
  var _closed = false;

  bool get closed => _closed;

  /// The transport dies, and says so.
  void drop() {
    _closed = true;
    if (!_done.isCompleted) _done.complete();
  }

  /// The transport dies without `done` having fired yet.
  void closeWithoutNotifying() => _closed = true;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    if (throwOnClose) throw StateError('already gone');
    _closed = true;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
