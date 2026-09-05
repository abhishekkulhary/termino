import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';

Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

String joined(List<Uint8List> chunks) =>
    chunks.map((chunk) => utf8.decode(chunk)).join();

void main() {
  group('TerminalOutputBatcher', () {
    test('coalesces chunks arriving inside the window into one emission', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add);
        async.flushMicrotasks();

        for (final part in ['a', 'b', 'c']) {
          source.add(bytes(part));
        }
        async.flushMicrotasks();

        // Nothing yet: the window has not expired.
        expect(emitted, isEmpty);

        async.elapse(const Duration(milliseconds: 8));
        expect(emitted, hasLength(1));
        expect(joined(emitted), 'abc');
      });
    });

    test('emits separately once the window has expired between chunks', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add);
        async.flushMicrotasks();

        source.add(bytes('first'));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(milliseconds: 8));

        source.add(bytes('second'));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(milliseconds: 8));

        expect(emitted, hasLength(2));
        expect(joined(emitted), 'firstsecond');
      });
    });

    test('flushes immediately once maxBufferedBytes is reached', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        source.stream
            .transform(const TerminalOutputBatcher(maxBufferedBytes: 4))
            .listen(emitted.add);
        async.flushMicrotasks();

        source.add(bytes('abcdef'));
        async.flushMicrotasks();

        // No clock has advanced; the size rule alone forced the emission.
        expect(emitted, hasLength(1));
        expect(joined(emitted), 'abcdef');
      });
    });

    test('flushes buffered bytes when the source completes', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        var done = false;
        source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add, onDone: () => done = true);
        async.flushMicrotasks();

        source.add(bytes('tail'));
        async.flushMicrotasks();
        expect(emitted, isEmpty, reason: 'window has not expired');

        unawaited(source.close());
        async.flushMicrotasks();

        expect(joined(emitted), 'tail', reason: 'nothing may be dropped');
        expect(done, isTrue);
      });
    });

    test('preserves order and loses nothing across a large burst', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add);
        async.flushMicrotasks();

        final expected = StringBuffer();
        for (var i = 0; i < 5000; i++) {
          final chunk = 'line $i\n';
          expected.write(chunk);
          source.add(bytes(chunk));
          // Advance a little every so often so several windows elapse.
          if (i % 500 == 0) async.elapse(const Duration(milliseconds: 9));
        }
        unawaited(source.close());
        async.flushMicrotasks();

        expect(joined(emitted), expected.toString());
        expect(
          emitted.length,
          lessThan(100),
          reason: '5000 chunks must collapse into very few terminal writes',
        );
      });
    });

    test('pausing the output pauses the source (backpressure)', () {
      fakeAsync((async) {
        var sourcePaused = false;
        final source = StreamController<Uint8List>(
          onPause: () => sourcePaused = true,
          onResume: () => sourcePaused = false,
        );
        final emitted = <Uint8List>[];
        final subscription = source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add);
        async.flushMicrotasks();

        subscription.pause();
        async.flushMicrotasks();
        expect(
          sourcePaused,
          isTrue,
          reason: 'a paused terminal must pause the socket, not buffer forever',
        );

        subscription.resume();
        async.flushMicrotasks();
        expect(sourcePaused, isFalse);

        unawaited(subscription.cancel());
      });
    });

    test('holds bytes while paused and emits them after resuming', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        final subscription = source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add);
        async.flushMicrotasks();

        subscription.pause();
        source.add(bytes('while-paused'));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(milliseconds: 50));
        expect(emitted, isEmpty);

        subscription.resume();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(milliseconds: 8));

        expect(joined(emitted), 'while-paused');

        unawaited(subscription.cancel());
      });
    });

    test('forwards errors from the source', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        Object? seen;
        source.stream
            .transform(const TerminalOutputBatcher())
            .listen((_) {}, onError: (Object error) => seen = error);
        async.flushMicrotasks();

        source.addError(const SocketFailure());
        async.flushMicrotasks();

        expect(seen, isA<SocketFailure>());
      });
    });

    test('ignores empty chunks', () {
      fakeAsync((async) {
        final source = StreamController<Uint8List>();
        final emitted = <Uint8List>[];
        source.stream
            .transform(const TerminalOutputBatcher())
            .listen(emitted.add);
        async.flushMicrotasks();

        source.add(Uint8List(0));
        async
          ..flushMicrotasks()
          ..elapse(const Duration(milliseconds: 20));

        expect(emitted, isEmpty);
      });
    });

    test('cancelling the subscription cancels the source', () {
      fakeAsync((async) {
        var cancelled = false;
        final source = StreamController<Uint8List>(
          onCancel: () => cancelled = true,
        );
        final subscription = source.stream
            .transform(const TerminalOutputBatcher())
            .listen((_) {});
        async.flushMicrotasks();

        unawaited(subscription.cancel());
        async.flushMicrotasks();

        expect(cancelled, isTrue);
      });
    });
  });
}

/// A stand-in for a transport error.
class SocketFailure implements Exception {
  const new();
}
