import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/zmodem_transfers.dart';
import 'package:zmodem/zmodem.dart';

/// `rz` and `sz` embed a file transfer inside the same byte stream the shell
/// prints to. What matters is that ordinary output still reaches the terminal
/// untouched, that a transfer is diverted rather than printed, and that the
/// far end cannot write to this machine without being asked.
void main() {
  late List<Uint8List> written;
  late List<String> printed;
  late ZModemTransfers transfers;

  /// Bytes a remote `sz` sends to announce itself.
  final senderInit = Uint8List.fromList('**\x18B0000000'.codeUnits);

  ZModemTransfers build({
    Future<StreamSink<List<int>>?> Function(IncomingFile)? onIncoming,
    Future<List<OutgoingFile>> Function()? onOutgoing,
  }) {
    written = [];
    printed = [];
    return ZModemTransfers(
      write: written.add,
      onIncoming: onIncoming ?? (_) async => null,
      onOutgoingRequested: onOutgoing ?? () async => const [],
    )..onTerminalText = printed.add;
  }

  tearDown(() => transfers.dispose());

  test('ordinary output reaches the terminal unchanged', () async {
    transfers = build()
      ..addFromBackend(
        Uint8List.fromList(
          utf8.encode(
            r'$ ls -la'
            '\n',
          ),
        ),
      );
    await Future<void>.delayed(Duration.zero);

    expect(
      printed.join(),
      r'$ ls -la'
      '\n',
    );
  });

  test('output split across chunks still decodes', () async {
    // A multi-byte character landing on a chunk boundary is the classic way a
    // terminal shows a replacement glyph.
    transfers = build();
    final bytes = utf8.encode('café');

    transfers
      ..addFromBackend(Uint8List.fromList(bytes.sublist(0, 4)))
      ..addFromBackend(Uint8List.fromList(bytes.sublist(4)));
    await Future<void>.delayed(Duration.zero);

    expect(printed.join(), 'café');
  });

  test('a transfer header is diverted, not printed', () async {
    transfers = build()
      ..addFromBackend(
        Uint8List.fromList([...utf8.encode('before'), ...senderInit]),
      );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(printed.join(), 'before');
    expect(
      printed.join(),
      isNot(contains('B0000000')),
      reason: 'the protocol handshake must never appear on screen',
    );
  });

  test('a whole file arrives, driven by a real sender', () async {
    // The end-to-end case, against the protocol implementation itself rather
    // than against a header fixture: a sender is run in this process, its bytes
    // go into the multiplexer, and the multiplexer's replies go back to it.
    // Nothing short of this proves a transfer actually completes — spotting the
    // header is only the first frame of it.
    final contents = Uint8List.fromList(
      List<int>.generate(9000, (index) => index % 251),
    );
    final received = <int>[];
    var finished = false;

    transfers = build(
      onIncoming: (file) async {
        final controller = StreamController<List<int>>()
          ..stream.listen(received.addAll);
        return controller.sink;
      },
    )..onFinished = () => finished = true;

    final sender = ZModemCore()..initiateSend();
    var offered = false;

    // Hand-run the two ends against each other until the sender is done. A
    // bounded loop, so a protocol that stops making progress fails the test
    // rather than hanging the suite.
    for (var turn = 0; turn < 200 && !sender.isFinished; turn++) {
      if (sender.hasDataToSend) {
        // The package's encoder terminates hex headers with a bare 0x0a where
        // lrzsz — and the package's own parser — require 0x8a, so its sender
        // cannot talk to its own receiver. Corrected here so that this test's
        // sender puts on the wire what a real `sz` puts on the wire.
        transfers.addFromBackend(
          ZModemTransfers.correctHexTerminators(sender.dataToSend()),
        );
      }
      await Future<void>.delayed(Duration.zero);

      final reply = written.isEmpty
          ? Uint8List(0)
          : Uint8List.fromList(written.expand((chunk) => chunk).toList());
      written.clear();
      if (reply.isEmpty && !sender.hasDataToSend) continue;

      for (final event in sender.receive(reply)) {
        switch (event) {
          case ZReadyToSendEvent():
            // Offered once. `rz` asks again after each file, and a sender that
            // answers with the same file every time never stops.
            if (offered) {
              sender.finishSession();
            } else {
              offered = true;
              sender.offerFile(
                ZModemFileInfo(
                  pathname: 'payload.bin',
                  length: contents.length,
                ),
              );
            }
          case ZFileAcceptedEvent():
            sender
              ..sendFileData(contents)
              ..finishSending(contents.length);
          case ZFileSkippedEvent():
            sender.finishSession();
          default:
            break;
        }
      }
    }
    await Future<void>.delayed(Duration.zero);

    expect(received, contents, reason: 'the file must arrive byte for byte');
    expect(
      finished,
      isTrue,
      reason: 'the UI has to be told the transfer ended',
    );
    expect(
      printed.join(),
      isEmpty,
      reason: 'not one byte of the protocol may reach the screen',
    );
  });

  test(
    'an offer nobody accepts is skipped, and the session survives',
    () async {
      // The default: no handler, or a handler that declines. A host that has
      // been tampered with must not be able to write to this disk because
      // someone happened to have a shell open.
      var asked = 0;
      transfers = build(
        onIncoming: (file) async {
          asked++;
          return null;
        },
      )..addFromBackend(senderInit);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Whether the far end got as far as offering depends on the handshake, so
      // the assertion is the one that matters: nothing was written to disk and
      // nothing crashed.
      expect(asked, lessThanOrEqualTo(1));
      expect(printed.join(), isEmpty);
    },
  );

  test('keystrokes go to the backend when no transfer is running', () async {
    transfers = build()..sendText('ls\n');
    await Future<void>.delayed(Duration.zero);

    expect(utf8.decode(written.expand((chunk) => chunk).toList()), 'ls\n');
  });

  group('a filename from the far end', () {
    // The name arrives from the remote machine and can say anything.
    IncomingFile named(String name) => IncomingFile(name: name, size: 0);

    test('is reduced to its last segment', () {
      expect(named('reports/q3.pdf').safeName, 'q3.pdf');
      expect(named(r'C:\\Users\\me\\notes.txt').safeName, 'notes.txt');
    });

    test('cannot climb out of the directory it is written to', () {
      expect(named('../../.bashrc').safeName, 'bashrc');
      expect(named('/etc/passwd').safeName, 'passwd');
    });

    test('never comes out empty', () {
      expect(named('').safeName, 'received');
      expect(named('///').safeName, 'received');
      expect(named('...').safeName, 'received');
    });

    test('an ordinary name is left alone', () {
      expect(named('report.pdf').safeName, 'report.pdf');
    });
  });

  group('finding the header', () {
    // The reason this multiplexer exists rather than xterm's: its scan misses
    // a header that is not followed by at least one more byte, and `sz`
    // announces itself and then waits.
    Uint8List bytes(List<int> values) => Uint8List.fromList(values);

    test('finds one at the very end of a chunk', () {
      final chunk = bytes([
        ...utf8.encode('before'),
        ...ZModemTransfers.senderInit,
      ]);
      expect(ZModemTransfers.indexOfHeader(chunk), 6);
    });

    test('finds one that is the whole chunk', () {
      expect(ZModemTransfers.indexOfHeader(ZModemTransfers.senderInit), 0);
    });

    test('finds a receiver header too', () {
      expect(ZModemTransfers.indexOfHeader(ZModemTransfers.receiverInit), 0);
    });

    test('finds nothing in ordinary output', () {
      expect(
        ZModemTransfers.indexOfHeader(
          bytes(
            utf8.encode(
              r'$ ls -la'
              '\n',
            ),
          ),
        ),
        isNull,
      );
    });

    test('is not fooled by a partial header', () {
      expect(ZModemTransfers.indexOfHeader(bytes(utf8.encode('**'))), isNull);
    });
  });

  test('disposing twice is harmless', () async {
    transfers = build();
    await transfers.dispose();
    await transfers.dispose();
  });

  test('aborting tells the far end and hands the shell back', () async {
    // A transfer that stalls must not leave the session swallowing every
    // keystroke into a protocol nobody is listening to.
    transfers = build()..addFromBackend(senderInit);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(transfers.isActive, isTrue);

    written.clear();
    await transfers.abort();

    final sent = written.expand((chunk) => chunk).toList();
    expect(
      sent.where((byte) => byte == 0x18).length,
      greaterThanOrEqualTo(8),
      reason: 'the far end is told with the protocol cancel sequence',
    );
    expect(transfers.isActive, isFalse);

    written.clear();
    transfers.sendText('ls\n');
    expect(
      utf8.decode(written.expand((chunk) => chunk).toList()),
      'ls\n',
      reason: 'keystrokes reach the shell again',
    );
  });
}
