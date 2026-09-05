import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';

Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('MockBackend', () {
    test('replays its frames in order', () async {
      final backend = MockBackend(
        frames: [
          MockOutputFrame.text('one '),
          MockOutputFrame.text('two '),
          MockOutputFrame.text('three'),
        ],
      );
      final received = StringBuffer();
      backend.output.listen((chunk) => received.write(utf8.decode(chunk)));

      await backend.start();
      await pumpEventQueue();

      expect(received.toString(), 'one two three');
    });

    test('closes and reports its exit status once drained', () async {
      final backend = MockBackend(
        frames: [MockOutputFrame.text('done')],
        exitStatus: 7,
      );
      backend.output.listen((_) {});

      await backend.start();
      await pumpEventQueue();

      expect(backend.state, BackendConnectionState.closed);
      expect(await backend.exitCode, 7);
    });

    test('stays connected when closeWhenDrained is false', () async {
      final backend = MockBackend.text(r'prompt$ ');
      backend.output.listen((_) {});

      await backend.start();
      await pumpEventQueue();

      expect(backend.state, BackendConnectionState.connected);
      await backend.close();
    });

    test('records what was written to it', () async {
      final backend = MockBackend.text('');
      backend.output.listen((_) {});
      await backend.start();

      backend
        ..write(bytes('ls'))
        ..write(bytes('\r'));

      expect(backend.writes, hasLength(2));
      expect(backend.writtenText, 'ls\r');
      await backend.close();
    });

    test('records resizes', () async {
      final backend = MockBackend.text('');
      await backend.start();

      backend.resize(80, 24, pixelWidth: 640, pixelHeight: 384);

      expect(backend.resizes, hasLength(1));
      expect(backend.resizes.single.columns, 80);
      expect(backend.resizes.single.rows, 24);
      expect(backend.resizes.single.pixelWidth, 640);
      await backend.close();
    });

    test('echoes input back when asked to', () async {
      final backend = MockBackend(echoInput: true, closeWhenDrained: false);
      final received = StringBuffer();
      backend.output.listen((chunk) => received.write(utf8.decode(chunk)));
      await backend.start();

      backend.write(bytes('hello'));
      await pumpEventQueue();

      expect(received.toString(), 'hello');
      await backend.close();
    });

    test('a failing mock reports its failure through start', () async {
      const failure = TerminalBackendFailure(
        TerminalBackendFailureKind.hostKeyMismatch,
        'The host key has changed.',
      );
      final backend = MockBackend.failing(failure);

      await expectLater(backend.start(), throwsA(same(failure)));
      expect(backend.state, BackendConnectionState.error);
      expect(backend.failure, same(failure));
    });

    test('honours frame delays', () async {
      final backend = MockBackend(
        frames: [
          MockOutputFrame.text('a'),
          MockOutputFrame.text('b', delay: const Duration(milliseconds: 40)),
        ],
        closeWhenDrained: false,
      );
      final received = StringBuffer();
      backend.output.listen((chunk) => received.write(utf8.decode(chunk)));

      await backend.start();
      await pumpEventQueue();
      expect(received.toString(), 'a');

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(received.toString(), 'ab');
      await backend.close();
    });
  });
}
