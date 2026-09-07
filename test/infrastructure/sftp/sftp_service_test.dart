@Timeout(Duration(seconds: 120))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/transfer_task.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/sftp/application/folder_transfer.dart';
import 'package:termino/features/sftp/application/transfer_queue.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_sshd.dart';

void main() {
  if (!TestSshd.isSupported) {
    test('SFTP tests need a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late SshConnection connection;
  late SftpService sftp;
  late SftpClient rawClient;
  late Directory workspace;

  setUp(() async {
    server = await TestSshd.start();
    workspace = await Directory.systemTemp.createTemp('termino-sftp-');

    final factory = SshConnectionFactory(
      verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
      onHostKeyPrompt: (_) async => true,
    );
    connection = await factory.connect(
      host: SshHost(
        id: 'sftp',
        label: 'sftp',
        hostname: '127.0.0.1',
        username: TestSshd.username,
        port: server.port,
      ),
      prompts: SshAuthPrompts(
        identities: SSHKeyPair.fromPem(TestSshd.clientPrivateKey),
      ),
    );
    rawClient = await connection.client.sftp();
    sftp = SftpService(rawClient);
  });

  tearDown(() async {
    await sftp.close();
    await connection.close();
    await server.stop();
    if (workspace.existsSync()) await workspace.delete(recursive: true);
  });

  group('browsing', () {
    test('lists a directory', () async {
      await File('${workspace.path}/alpha.txt').writeAsString('hello');
      await Directory('${workspace.path}/sub').create();

      final entries = await sftp.list(workspace.path);

      expect(entries.map((e) => e.name), containsAll(['alpha.txt', 'sub']));
    });

    test('puts directories first, then sorts by name', () async {
      for (final name in ['zeta.txt', 'alpha.txt']) {
        await File('${workspace.path}/$name').writeAsString('x');
      }
      for (final name in ['zdir', 'adir']) {
        await Directory('${workspace.path}/$name').create();
      }

      final names = (await sftp.list(workspace.path)).map((e) => e.name);

      expect(names, ['adir', 'zdir', 'alpha.txt', 'zeta.txt']);
    });

    test('reports type, size and permissions', () async {
      await File('${workspace.path}/data.bin').writeAsString('12345');

      final entry = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'data.bin');

      expect(entry.isDirectory, isFalse);
      expect(entry.size, 5);
      expect(entry.modeString, isNotNull);
      expect(entry.modeString, hasLength(9));
      expect(entry.modified, isNotNull);
    });

    test('omits . and ..', () async {
      final names = (await sftp.list(workspace.path)).map((e) => e.name);

      expect(names, isNot(contains('.')));
      expect(names, isNot(contains('..')));
    });

    test('marks dotfiles as hidden', () async {
      await File('${workspace.path}/.hidden').writeAsString('x');

      final entry = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == '.hidden');

      expect(entry.isHidden, isTrue);
    });

    test('resolves a relative path', () async {
      expect(await sftp.absolute('.'), startsWith('/'));
    });
  });

  group('modifying', () {
    test('creates a directory', () async {
      await sftp.makeDirectory('${workspace.path}/created');

      expect(Directory('${workspace.path}/created').existsSync(), isTrue);
    });

    test('renames a file', () async {
      await File('${workspace.path}/before.txt').writeAsString('x');

      await sftp.rename(
        '${workspace.path}/before.txt',
        '${workspace.path}/after.txt',
      );

      expect(File('${workspace.path}/after.txt').existsSync(), isTrue);
      expect(File('${workspace.path}/before.txt').existsSync(), isFalse);
    });

    test('deletes a file', () async {
      await File('${workspace.path}/doomed.txt').writeAsString('x');
      final entry = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'doomed.txt');

      await sftp.delete(entry);

      expect(File('${workspace.path}/doomed.txt').existsSync(), isFalse);
    });

    test('deletes an empty directory', () async {
      await Directory('${workspace.path}/empty').create();
      final entry = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'empty');

      await sftp.delete(entry);

      expect(Directory('${workspace.path}/empty').existsSync(), isFalse);
    });

    test('changes permissions', () async {
      final file = File('${workspace.path}/script.sh');
      await file.writeAsString('#!/bin/sh\n');

      await sftp.chmod(file.path, 0x1ED); // 0o755

      final entry = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'script.sh');
      expect(entry.modeString, 'rwxr-xr-x');
    });

    test('reports a file size', () async {
      await File('${workspace.path}/sized').writeAsString('abcdefgh');

      expect(await sftp.sizeOf('${workspace.path}/sized'), 8);
    });
  });

  group('transfers', () {
    late TransferQueue queue;

    setUp(() {
      queue = TransferQueue(
        runner: SftpTransferRunner(
          client: rawClient,
          openRead: (path) => File(path).openRead().map(Uint8List.fromList),
          openWrite: (path) async => File(path).openWrite(),
        ),
      );
    });

    tearDown(() => queue.dispose());

    Future<void> waitForQueue() async {
      for (var i = 0; i < 200 && queue.isBusy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    test('downloads a file byte for byte', () async {
      const content = 'the quick brown fox\njumps over the lazy dog\n';
      await File('${workspace.path}/source.txt').writeAsString(content);

      queue.enqueue(
        direction: TransferDirection.download,
        remotePath: '${workspace.path}/source.txt',
        localPath: '${workspace.path}/downloaded.txt',
        totalBytes: content.length,
      );
      await waitForQueue();

      expect(queue.tasks.single.status, TransferStatus.completed);
      expect(
        await File('${workspace.path}/downloaded.txt').readAsString(),
        content,
      );
    });

    test('uploads a file byte for byte', () async {
      final content = List.generate(5000, (i) => 'line $i').join('\n');
      await File('${workspace.path}/local.txt').writeAsString(content);

      queue.enqueue(
        direction: TransferDirection.upload,
        remotePath: '${workspace.path}/uploaded.txt',
        localPath: '${workspace.path}/local.txt',
        totalBytes: content.length,
      );
      await waitForQueue();

      expect(queue.tasks.single.status, TransferStatus.completed);
      expect(
        await File('${workspace.path}/uploaded.txt').readAsString(),
        content,
      );
    });

    test('reports progress as bytes move', () async {
      // Large enough to arrive in several chunks, so progress is observable.
      final content = 'x' * (512 * 1024);
      await File('${workspace.path}/big.bin').writeAsString(content);

      final seen = <int>[];
      queue
        ..addListener(() {
          final task = queue.tasks.singleOrNull;
          if (task != null) seen.add(task.transferredBytes);
        })
        ..enqueue(
          direction: TransferDirection.download,
          remotePath: '${workspace.path}/big.bin',
          localPath: '${workspace.path}/big-copy.bin',
          totalBytes: content.length,
        );
      await waitForQueue();

      expect(queue.tasks.single.status, TransferStatus.completed);
      expect(
        seen.where((bytes) => bytes > 0 && bytes < content.length),
        isNotEmpty,
        reason:
            'progress must be reported during the transfer, not only at '
            'the end',
      );
    });

    test('a missing remote file fails with a usable message', () async {
      queue.enqueue(
        direction: TransferDirection.download,
        remotePath: '${workspace.path}/not-there.txt',
        localPath: '${workspace.path}/nope.txt',
      );
      await waitForQueue();

      expect(queue.tasks.single.status, TransferStatus.failed);
      expect(queue.tasks.single.error, isNotNull);
      expect(queue.tasks.single.error, isNot(contains('Exception')));
    });

    test('a failed transfer can be retried once the file exists', () async {
      queue.enqueue(
        direction: TransferDirection.download,
        remotePath: '${workspace.path}/late.txt',
        localPath: '${workspace.path}/late-copy.txt',
      );
      await waitForQueue();
      expect(queue.tasks.single.status, TransferStatus.failed);

      await File('${workspace.path}/late.txt').writeAsString('now here');
      queue.retry(queue.tasks.single.id);
      await waitForQueue();

      expect(queue.tasks.single.status, TransferStatus.completed);
      expect(
        await File('${workspace.path}/late-copy.txt').readAsString(),
        'now here',
      );
    });
  });

  group('whole folders', () {
    // Moving a folder is the operation that actually touches a filesystem on
    // both ends, so these run against the real server rather than a plan.

    test('creating a directory that exists again is not an error', () async {
      // Uploading a folder twice must not fail on the directories that are
      // already there. SFTP has no `mkdir -p`.
      final path = '${workspace.path}/reports';

      await sftp.ensureDirectory(path);
      await sftp.ensureDirectory(path);

      expect(Directory(path).existsSync(), isTrue);
    });

    test('a file where a directory should be is still an error', () async {
      // "Already exists" is only acceptable when what exists is a directory.
      final path = '${workspace.path}/occupied';
      await File(path).writeAsString('in the way');

      await expectLater(sftp.ensureDirectory(path), throwsA(anything));
    });

    test('deleting a folder takes everything in it', () async {
      // `rmdir` refuses a directory that is not empty, so before folders could
      // be transferred there was nothing here to delete.
      await Directory('${workspace.path}/tree/deep').create(recursive: true);
      await File('${workspace.path}/tree/a.txt').writeAsString('a');
      await File('${workspace.path}/tree/deep/b.txt').writeAsString('b');

      final entry = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'tree');
      await sftp.deleteRecursively(entry);

      expect(Directory('${workspace.path}/tree').existsSync(), isFalse);
    });

    test('a planned download rebuilds the tree it walked', () async {
      // The plan and the filesystem have to agree: every directory it names
      // gets made, and every file it names is really there to fetch.
      await Directory('${workspace.path}/src/lib').create(recursive: true);
      await Directory('${workspace.path}/src/empty').create();
      await File('${workspace.path}/src/one.txt').writeAsString('1');
      await File('${workspace.path}/src/lib/two.txt').writeAsString('22');

      final root = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'src');
      final plan = await FolderTransfer.planDownload(
        root: root,
        destination: '${workspace.path}/out',
        list: sftp.list,
      );

      expect(
        plan.directories,
        containsAll([
          '${workspace.path}/out/src',
          '${workspace.path}/out/src/lib',
          '${workspace.path}/out/src/empty',
        ]),
      );
      expect(plan.files, hasLength(2));
      expect(plan.totalBytes, 3);
      for (final file in plan.files) {
        expect(await sftp.sizeOf(file.remotePath), file.size);
      }
    });

    test('a symbolic link in a real tree is skipped', () async {
      await Directory('${workspace.path}/app').create();
      await File('${workspace.path}/app/real.txt').writeAsString('x');
      await Link('${workspace.path}/app/loop').create('${workspace.path}/app');

      final root = (await sftp.list(workspace.path))
          .firstWhere((e) => e.name == 'app');
      final plan = await FolderTransfer.planDownload(
        root: root,
        destination: '${workspace.path}/out',
        list: sftp.list,
      );

      expect(plan.files, hasLength(1));
      expect(plan.skippedLinks, 1, reason: 'the link points at its own parent');
    });
  });
}
