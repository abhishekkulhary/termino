// The wiring, end to end: opening a shell and then the file browser on the
// same host must authenticate once between them.
//
// Against a real server, through the real providers. The pool has its own unit
// tests; what this checks is that the launcher and the SFTP provider actually
// go through it — which is exactly the sort of thing that gets wired up and
// then quietly bypassed later.
@Timeout(Duration(seconds: 120))
library;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/hosts/application/connection_pool.dart';
import 'package:termino/features/sftp/application/sftp_providers.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_database.dart';
import '../../support/test_sshd.dart';

void main() {
  if (!TestSshd.isSupported) {
    test('one-login tests need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late ProviderContainer container;
  late int authentications;
  late SshHost host;
  late SshConnectionPool pool;

  setUp(() async {
    server = await TestSshd.start();
    authentications = 0;

    host = SshHost(
      id: 'shared',
      label: 'Test server',
      hostname: '127.0.0.1',
      username: TestSshd.username,
      port: server.port,
    );

    pool = SshConnectionPool(
      open: (target) async {
        authentications++;
        return await SshConnectionFactory(
          verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
          onHostKeyPrompt: (_) async => true,
        ).connect(
          host: target,
          prompts: SshAuthPrompts(
            identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
          ),
        );
      },
    );

    container = testContainer(connectionPool: pool);
    await container.read(sshHostRepositoryProvider).save(host);
  });

  // The container disposes itself — `ProviderContainer.test` registers that —
  // so the pool is held here rather than read back out of a container that has
  // already gone.
  tearDown(() async {
    await pool.disconnectAll();
    await server.stop();
  });

  test('the file browser does not ask again after a shell is open', () async {
    final session = await container
        .read(sessionLauncherProvider.notifier)
        .openSsh(host);
    expect(session.connectionState.value, BackendConnectionState.connected);
    expect(authentications, 1);

    container.read(selectedSftpHostProvider.notifier).select(host);
    final browser = await container.read(sftpSessionProvider.future);

    expect(browser, isNotNull);
    expect(browser!.entries, isNotEmpty, reason: 'the browser really listed');
    expect(
      authentications,
      1,
      reason: 'the browser attached to the connection the shell opened',
    );
  });

  test('a shell does not ask again after the browser is open', () async {
    // The other order, because the user can start from either.
    container.read(selectedSftpHostProvider.notifier).select(host);
    await container.read(sftpSessionProvider.future);
    expect(authentications, 1);

    final session = await container
        .read(sessionLauncherProvider.notifier)
        .openSsh(host);

    expect(session.connectionState.value, BackendConnectionState.connected);
    expect(authentications, 1);
  });

  test('closing the browser leaves the shell working', () async {
    final session = await container
        .read(sessionLauncherProvider.notifier)
        .openSsh(host);

    container.read(selectedSftpHostProvider.notifier).select(host);
    await container.read(sftpSessionProvider.future);

    // Deselecting disposes the SFTP session, which releases its lease.
    container.read(selectedSftpHostProvider.notifier).select(null);
    await container.read(sftpSessionProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      session.connectionState.value,
      BackendConnectionState.connected,
      reason: 'closing the file browser must not disconnect the shell',
    );
    expect(
      container.read(sshConnectionPoolProvider).isConnected(host.id),
      isTrue,
    );
  });

  test('a second host is its own connection', () async {
    final other = host.copyWith(id: 'second', label: 'Second');
    await container.read(sshHostRepositoryProvider).save(other);

    await container.read(sessionLauncherProvider.notifier).openSsh(host);
    await container.read(sessionLauncherProvider.notifier).openSsh(other);

    expect(authentications, 2);
  });

  test('closing the last thing on a host disconnects it', () async {
    // The other half of reference counting: a lease that is never given up
    // would keep a connection — and an authenticated one at that — open for
    // the life of the app.
    final session = await container
        .read(sessionLauncherProvider.notifier)
        .openSsh(host);
    expect(pool.isConnected(host.id), isTrue);

    await container.read(sessionManagerProvider.notifier).close(session.id);

    expect(
      pool.isConnected(host.id),
      isFalse,
      reason: "closing the tab released the shell's hold",
    );
  });

  test('a second tab on the same host reuses the connection', () async {
    // Two shells on one machine is ordinary, and it should cost one login.
    final first = await container
        .read(sessionLauncherProvider.notifier)
        .openSsh(host);
    await container.read(sessionLauncherProvider.notifier).openSsh(host);

    expect(authentications, 1);
    expect(pool.leaseCount(host.id), 2);

    await container.read(sessionManagerProvider.notifier).close(first.id);

    expect(
      pool.isConnected(host.id),
      isTrue,
      reason: 'the second tab is still on it',
    );
  });
}
