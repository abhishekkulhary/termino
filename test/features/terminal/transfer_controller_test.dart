import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/transfer_controller.dart';
import 'package:termino/features/terminal/application/zmodem_transfers.dart';

/// A file arriving from a machine on the other end of an SSH connection is the
/// one place in this app where a remote host writes to local disk. What matters
/// is that nobody's files are overwritten, that a decline really declines, and
/// that the user is told where the file went.
void main() {
  late Directory directory;
  late ProviderContainer container;
  late TransferController controller;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('termino-transfers');
    container = ProviderContainer();
    controller = container.read(transferControllerProvider.notifier)
      ..destinationOverride = () async => directory;
  });

  tearDown(() {
    container.dispose();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  TransferState state() => container.read(transferControllerProvider);

  test('an offer is a question, not an action', () async {
    // Nothing may be written until somebody says yes.
    unawaited(
      controller.askToReceive(
        const IncomingFile(name: 'notes.txt', size: 12),
        sessionId: 'session-1',
      ),
    );

    expect(state().request, isA<IncomingRequest>());
    expect(state().sessionId, 'session-1');
    expect(directory.listSync(), isEmpty);
  });

  test('declining resolves the protocol with no sink', () async {
    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 12),
      sessionId: 'session-1',
    );

    controller.decline();

    expect(await answer, isNull);
    expect(state().isIdle, isTrue);
    expect(directory.listSync(), isEmpty);
  });

  test('accepting opens a file and reports where it went', () async {
    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 5),
      sessionId: 'session-1',
    );

    await controller.accept();
    final sink = await answer;

    expect(sink, isNotNull);
    sink!.add(utf8.encode('hello'));
    await sink.close();

    expect(File('${directory.path}/notes.txt').readAsStringSync(), 'hello');
    expect(state().progress?.path, '${directory.path}/notes.txt');
    expect(state().progress?.total, 5);
  });

  test('a second file of the same name does not overwrite the first', () async {
    // The name is chosen by the remote machine, which will happily send
    // `notes.txt` twice. Replacing a file someone already has is not something
    // a host on the other end of a socket gets to do.
    File('${directory.path}/notes.txt').writeAsStringSync('mine');

    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 0),
      sessionId: 'session-1',
    );
    await controller.accept();
    await (await answer)!.close();

    expect(File('${directory.path}/notes.txt').readAsStringSync(), 'mine');
    expect(File('${directory.path}/notes-2.txt').existsSync(), isTrue);
  });

  test('a path from the far end cannot escape the directory', () async {
    final answer = controller.askToReceive(
      const IncomingFile(name: '../../escaped.txt', size: 0),
      sessionId: 'session-1',
    );
    await controller.accept();
    await (await answer)!.close();

    expect(File('${directory.path}/escaped.txt').existsSync(), isTrue);
    expect(state().progress?.path, startsWith(directory.path));
  });

  test('somewhere unwritable is reported, not crashed on', () async {
    controller.destinationOverride = () async =>
        throw const FileSystemException('no such directory');

    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 0),
      sessionId: 'session-1',
    );
    await controller.accept();

    // Declining is the only safe answer: a sink that cannot be written to
    // would strand the transfer half way through.
    expect(await answer, isNull);
    expect(state().error, isNotNull);
  });

  test('a send request with no files ends politely', () async {
    final answer = controller.askToSend(sessionId: 'session-1');
    expect(state().request, isA<OutgoingRequest>());

    await controller.send(const []);

    expect(await answer, isEmpty);
    expect(state().isIdle, isTrue);
  });

  test('a send request offers the files that exist', () async {
    final file = File('${directory.path}/report.pdf')
      ..writeAsStringSync('12345');

    final answer = controller.askToSend(sessionId: 'session-1');
    await controller.send([file.path, '${directory.path}/gone.txt']);

    final files = await answer;
    expect(files, hasLength(1));
    expect(files.single.info.pathname, 'report.pdf');
    expect(files.single.info.length, 5);
    expect(state().progress?.incoming, isFalse);
  });

  test('progress advances and finishing keeps what was transferred', () async {
    final answer = controller.askToReceive(
      const IncomingFile(name: 'big.bin', size: 100),
      sessionId: 'session-1',
    );
    await controller.accept();
    await (await answer)!.close();

    controller.report('big.bin', 40);
    expect(state().progress?.fraction, closeTo(0.4, 0.001));

    controller.finish();
    expect(state().progress, isNull);
    expect(state().completed?.bytes, 40);
    expect(state().completed?.path, isNotNull);
  });

  test('a size the far end never gave shows as indeterminate', () async {
    const progress = TransferProgress(
      name: 'stream.bin',
      bytes: 900,
      total: 0,
      incoming: true,
    );
    expect(progress.fraction, isNull);
  });

  test('a session going away answers its own question', () async {
    final incoming = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 0),
      sessionId: 'session-1',
    );

    await controller.abort();

    expect(await incoming, isNull);
    expect(state().isIdle, isTrue);
  });

  test('cancelling removes the half-written file', () async {
    // A truncated download sitting under the name of a real file is worse than
    // no file: nothing about it says it is incomplete.
    final answer = controller.askToReceive(
      const IncomingFile(name: 'big.bin', size: 5000),
      sessionId: 'session-1',
    );
    await controller.accept();
    final sink = (await answer)!..add(List.filled(64, 0));

    final path = state().progress!.path!;
    expect(File(path).existsSync(), isTrue);

    await controller.abort();

    expect(File(path).existsSync(), isFalse);
    expect(state().isIdle, isTrue);
    expect(sink, isNotNull);
  });

  test('cancelling a send leaves local files alone', () async {
    final file = File('${directory.path}/report.pdf')
      ..writeAsStringSync('12345');

    final answer = controller.askToSend(sessionId: 'session-1');
    await controller.send([file.path]);
    await controller.abort();

    expect(await answer, hasLength(1));
    expect(file.existsSync(), isTrue);
  });
}
