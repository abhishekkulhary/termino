@Timeout(Duration(seconds: 120))
library;

import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/transfer_task.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/sftp/application/sftp_session.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_sshd.dart';

/// The whole upload path as the screen drives it: pick a local file, hand its
/// path to the session, and let the queue and runner do the rest. The pieces
/// were each tested on their own; nothing tested them joined together, which
/// is where uploading turned out to be broken.
void main() {
  if (!TestSshd.isSupported) {
    test('SFTP session tests need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late SshConnection connection;
  late SftpClient rawClient;
  late SftpSession session;
  late Directory workspace;

  setUp(() async {
    server = await TestSshd.start();
    workspace = await Directory.systemTemp.createTemp('termino-session-');

    final factory = SshConnectionFactory(
      verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
      onHostKeyPrompt: (_) async => true,
    );
    final host = SshHost(
      id: 'sftp',
      label: 'sftp',
      hostname: '127.0.0.1',
      username: TestSshd.username,
      port: server.port,
    );
    connection = await factory.connect(
      host: host,
      prompts: SshAuthPrompts(
        identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
      ),
    );
    rawClient = await connection.client.sftp();
    session = SftpSession(
      host: host,
      connection: connection,
      service: SftpService(rawClient),
      client: rawClient,
    );
    await session.start();
    await session.open(workspace.path);
  });

  tearDown(() async {
    await session.dispose();
    await connection.close();
    await server.stop();
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  /// Waits for the queue to stop having work in flight.
  Future<TransferTask> settle() async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (session.queue.isBusy && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(session.queue.tasks, hasLength(1));
    return session.queue.tasks.single;
  }

  test('uploads a file the user picked into the current directory', () async {
    final source = File('${workspace.path}/source.txt')
      ..writeAsStringSync('the quick brown fox\n');
    await session.open(workspace.path);

    await session.upload(source.path);
    final task = await settle();

    expect(
      task.status,
      TransferStatus.completed,
      reason: 'upload reported: ${task.error}',
    );

    final uploaded = File('${workspace.path}/source.txt');
    expect(uploaded.existsSync(), isTrue);
  });

  test('uploads into whichever directory is open', () async {
    final target = Directory('${workspace.path}/nested')..createSync();
    await session.open(target.path);

    final source = File('${workspace.path}/payload.bin')
      ..writeAsBytesSync(List<int>.generate(64 * 1024, (i) => i % 256));

    await session.upload(source.path);
    final task = await settle();

    expect(
      task.status,
      TransferStatus.completed,
      reason: 'upload reported: ${task.error}',
    );

    final uploaded = File('${target.path}/payload.bin');
    expect(
      uploaded.existsSync(),
      isTrue,
      reason: 'wrote to ${task.remotePath}',
    );
    expect(uploaded.readAsBytesSync(), source.readAsBytesSync());
  });

  test('deleting through the session removes the file', () async {
    // The path the swipe and the menu both take. Swiping a file row is
    // reachable by accident in a way swiping a host is not — a directory is
    // hundreds of rows and gets flicked through — so the confirmation in front
    // of this is the whole safety of the gesture.
    final doomed = File('${workspace.path}/doomed.txt')..writeAsStringSync('x');
    await session.open(workspace.path);
    await session.refresh();

    final entry = session.entries.firstWhere((e) => e.name == 'doomed.txt');
    await session.delete(entry);

    expect(doomed.existsSync(), isFalse);
  });

  test('the uploaded file appears in the listing afterwards', () async {
    final source = File('${workspace.path}/visible.txt')
      ..writeAsStringSync('hello');
    final nested = Directory('${workspace.path}/dir')..createSync();
    await session.open(nested.path);

    await session.upload(source.path);
    await settle();
    await session.refresh();

    expect(
      session.entries.map((e) => e.name),
      contains('visible.txt'),
      reason: 'a transfer the user can see finishing should be visible',
    );
  });
}
