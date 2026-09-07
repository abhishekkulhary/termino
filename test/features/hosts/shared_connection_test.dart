// One authentication per host, proved against a real OpenSSH server.
//
// The claim is that a shell and a file browser on the same host share one
// authenticated connection. That cannot be checked against a fake: the thing
// being relied on is SSH's own multiplexing — a shell channel and an SFTP
// subsystem alive on one transport at the same time.
@Timeout(Duration(seconds: 120))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/hosts/application/connection_pool.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_sshd.dart';

void main() {
  if (!TestSshd.isSupported) {
    test('shared connections need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late SshConnectionPool pool;
  late int authentications;

  setUp(() async {
    server = await TestSshd.start();
    authentications = 0;

    pool = SshConnectionPool(
      open: (host) async {
        authentications++;
        return await SshConnectionFactory(
          verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
          onHostKeyPrompt: (_) async => true,
        ).connect(
          host: host,
          prompts: SshAuthPrompts(
            identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
          ),
        );
      },
    );
  });

  tearDown(() async {
    await pool.disconnectAll();
    await server.stop();
  });

  SshHost hostProfile() => SshHost(
    id: 'shared',
    label: 'Test server',
    hostname: '127.0.0.1',
    username: TestSshd.username,
    port: server.port,
  );

  test('a shell and a file browser authenticate once between them', () async {
    final host = hostProfile();

    final shellLease = await pool.acquire(host);
    final filesLease = await pool.acquire(host);

    expect(
      authentications,
      1,
      reason: 'the second consumer must not be asked for credentials again',
    );

    // Both channels, alive at the same time on the one transport.
    final shell = await shellLease.client.shell();
    final sftp = await filesLease.client.sftp();

    final output = StringBuffer();
    shell.stdout.listen((chunk) => output.write(utf8.decode(chunk)));

    final listing = await sftp.listdir('/');
    expect(
      listing.map((entry) => entry.filename),
      contains('tmp'),
      reason: 'the file browser works on the shared connection',
    );

    shell.write(
      // The marker is assembled at runtime so it cannot match the terminal
      // echoing the command back rather than running it.
      Uint8List.fromList(utf8.encode('echo ${'sh'}${'ared'}\n')),
    );
    for (var i = 0; i < 60 && !output.toString().contains('shared'); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(
      output.toString(),
      contains('shared'),
      reason: 'the shell works on the same connection at the same time',
    );

    unawaited(sftp.close());
    shell.close();
  });

  test('closing the browser leaves the shell connected', () async {
    // The part of the old one-connection-each isolation worth keeping.
    final host = hostProfile();
    final shellLease = await pool.acquire(host);
    final filesLease = await pool.acquire(host);

    await filesLease.release();

    expect(pool.isConnected(host.id), isTrue);
    expect(shellLease.client.isClosed, isFalse);

    // Still usable, not merely still open.
    final sftp = await shellLease.client.sftp();
    expect(await sftp.listdir('/'), isNotEmpty);
    unawaited(sftp.close());
  });

  test('closing the last of them disconnects', () async {
    final host = hostProfile();
    final shellLease = await pool.acquire(host);
    final filesLease = await pool.acquire(host);
    final client = shellLease.client;

    await filesLease.release();
    await shellLease.release();

    expect(pool.isConnected(host.id), isFalse);
    expect(client.isClosed, isTrue);
  });

  test('reconnecting after everything let go authenticates again', () async {
    final host = hostProfile();
    await (await pool.acquire(host)).release();

    await pool.acquire(host);

    expect(authentications, 2, reason: 'the first connection really did close');
  });
}
