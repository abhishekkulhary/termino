// Folder transfers against a real OpenSSH server, through the session the UI
// actually calls. The planner is tested separately; what is tested here is the
// half that touches two filesystems: directories really created, files really
// queued, and a second upload into the same place not falling over.
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

void main() {
  if (!TestSshd.isSupported) {
    test('folder transfers need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late SftpSession session;
  late Directory workspace;

  setUp(() async {
    server = await TestSshd.start();
    workspace = await Directory.systemTemp.createTemp('termino-folder-');

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
    final connection = await factory.connect(
      host: host,
      prompts: SshAuthPrompts(
        identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
      ),
    );
    final client = await connection.client.sftp();

    session = SftpSession(
      host: host,
      connection: connection,
      service: SftpService(client),
      client: client,
    );
  });

  tearDown(() async {
    await session.dispose();
    await server.stop();
    if (workspace.existsSync()) await workspace.delete(recursive: true);
  });

  /// The remote entry for [name] in the workspace.
  Future<RemoteEntry> entryNamed(String name) async {
    final entries = await session.service.list(workspace.path);
    return entries.firstWhere((entry) => entry.name == name);
  }

  group('downloading a folder', () {
    test('creates the tree and queues every file in it', () async {
      await Directory('${workspace.path}/src/lib').create(recursive: true);
      await Directory('${workspace.path}/src/empty').create();
      await File('${workspace.path}/src/one.txt').writeAsString('1');
      await File('${workspace.path}/src/lib/two.txt').writeAsString('22');

      final destination = '${workspace.path}/out';
      final plan = await session.downloadFolder(
        await entryNamed('src'),
        destination,
      );

      expect(plan, isNotNull);
      expect(plan!.files, hasLength(2));

      // The directories exist *before* any byte moves, so a transfer that
      // fails half way leaves the shape it was going to fill, not a
      // half-built tree with files in the wrong places.
      expect(Directory('$destination/src/lib').existsSync(), isTrue);
      expect(
        Directory('$destination/src/empty').existsSync(),
        isTrue,
        reason: 'an empty directory is part of the folder',
      );

      expect(session.queue.tasks, hasLength(2));
      expect(
        session.queue.tasks.every(
          (task) => task.direction == TransferDirection.download,
        ),
        isTrue,
      );
    });

    test('a folder that cannot be read reports rather than throws', () async {
      final plan = await session.downloadFolder(
        RemoteEntry(
          name: 'nowhere',
          path: '${workspace.path}/nowhere',
          isDirectory: true,
          isLink: false,
          size: 0,
        ),
        '${workspace.path}/out',
      );

      expect(plan, isNull);
      expect(session.error, isNotNull);
      expect(session.queue.tasks, isEmpty);
    });
  });

  group('uploading a folder', () {
    test('recreates the tree on the server and queues its files', () async {
      final source = Directory('${workspace.path}/project');
      await Directory('${source.path}/src').create(recursive: true);
      await Directory('${source.path}/empty').create();
      await File('${source.path}/README.md').writeAsString('hello');
      await File('${source.path}/src/main.dart').writeAsString('void main(){}');

      final target = await Directory('${workspace.path}/remote').create();
      await session.open(target.path);

      final plan = await session.uploadFolder(source.path);

      expect(plan, isNotNull);
      expect(plan!.files, hasLength(2));
      expect(Directory('${target.path}/project/src').existsSync(), isTrue);
      expect(Directory('${target.path}/project/empty').existsSync(), isTrue);
      expect(session.queue.tasks, hasLength(2));
      // Against `session.path`, not the local path: the server resolves the
      // directory, and on macOS `/var` comes back as `/private/var`. The
      // remote paths must be the ones the server gave, or the upload would be
      // written somewhere other than where the user is looking.
      expect(
        session.queue.tasks.map((task) => task.remotePath),
        containsAll([
          '${session.path}/project/README.md',
          '${session.path}/project/src/main.dart',
        ]),
      );
    });

    test('uploading the same folder twice does not fail', () async {
      // The second pass finds every directory already there. SFTP has no
      // `mkdir -p`, so this failed outright until `ensureDirectory`.
      final source = Directory('${workspace.path}/project');
      await Directory('${source.path}/src').create(recursive: true);
      await File('${source.path}/src/main.dart').writeAsString('x');

      final target = await Directory('${workspace.path}/remote').create();
      await session.open(target.path);

      expect(await session.uploadFolder(source.path), isNotNull);
      expect(await session.uploadFolder(source.path), isNotNull);
      expect(session.error, isNull);
    });

    test('a symbolic link is left behind, and counted', () async {
      final source = Directory('${workspace.path}/project');
      await source.create(recursive: true);
      await File('${source.path}/real.txt').writeAsString('x');
      await Link('${source.path}/self').create(source.path);

      final target = await Directory('${workspace.path}/remote').create();
      await session.open(target.path);

      final plan = await session.uploadFolder(source.path);

      expect(plan!.files, hasLength(1));
      expect(plan.skippedLinks, 1);
      expect(File('${target.path}/project/self').existsSync(), isFalse);
    });

    test('a folder that is not there reports rather than throws', () async {
      final plan = await session.uploadFolder('${workspace.path}/missing');

      expect(plan, isNull);
      expect(session.error, isNotNull);
    });
  });

  test('a downloaded folder really arrives, byte for byte', () async {
    // The end of the whole thing: plan, directories, queue, transfer. Queuing
    // the right paths proves nothing if the bytes never land.
    await Directory('${workspace.path}/src/lib').create(recursive: true);
    await File('${workspace.path}/src/one.txt').writeAsString('first');
    await File('${workspace.path}/src/lib/two.txt').writeAsString('second');

    final destination = '${workspace.path}/out';
    await session.downloadFolder(await entryNamed('src'), destination);

    await _drain(session);

    expect(File('$destination/src/one.txt').readAsStringSync(), 'first');
    expect(File('$destination/src/lib/two.txt').readAsStringSync(), 'second');
    expect(
      session.queue.tasks.map((task) => task.status),
      everyElement(TransferStatus.completed),
    );
  });

  test('an uploaded folder really arrives, byte for byte', () async {
    final source = Directory('${workspace.path}/project');
    await Directory('${source.path}/src').create(recursive: true);
    await File('${source.path}/README.md').writeAsString('readme');
    await File('${source.path}/src/main.dart').writeAsString('void main(){}');

    final target = await Directory('${workspace.path}/remote').create();
    await session.open(target.path);
    await session.uploadFolder(source.path);

    await _drain(session);

    expect(
      File('${target.path}/project/README.md').readAsStringSync(),
      'readme',
    );
    expect(
      File('${target.path}/project/src/main.dart').readAsStringSync(),
      'void main(){}',
    );
  });
}

/// Waits for the transfer queue to empty.
Future<void> _drain(SftpSession session, {int seconds = 30}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (session.queue.isBusy && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  if (session.queue.isBusy) {
    throw StateError(
      'the queue never drained: ${session.queue.active.length} '
      'still going',
    );
  }
}
