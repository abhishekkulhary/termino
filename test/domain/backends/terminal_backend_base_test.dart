import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/backends/terminal_backend_base.dart';

/// A backend whose connect/disconnect behaviour each test controls directly.
class TestBackend extends TerminalBackendBase {
  new({this.onConnect, this.source});

  final Future<void> Function(TestBackend backend)? onConnect;
  final Stream<Uint8List>? source;

  final List<Uint8List> sent = [];
  final List<String> resizes = [];
  int disconnectCount = 0;

  @override
  Future<void> connect() async {
    await onConnect?.call(this);
    final stream = source;
    if (stream != null) pipeOutput(stream);
  }

  @override
  Future<void> disconnect() async => disconnectCount++;

  @override
  void send(Uint8List data) => sent.add(data);

  @override
  void resize(
    int columns,
    int rows, {
    int pixelWidth = 0,
    int pixelHeight = 0,
  }) => resizes.add('${columns}x$rows');
}

Uint8List b(List<int> values) => Uint8List.fromList(values);

void main() {
  group('BackendConnectionState', () {
    test('knows which states are terminal', () {
      expect(BackendConnectionState.idle.isTerminal, isFalse);
      expect(BackendConnectionState.connecting.isTerminal, isFalse);
      expect(BackendConnectionState.connected.isTerminal, isFalse);
      expect(BackendConnectionState.closed.isTerminal, isTrue);
      expect(BackendConnectionState.error.isTerminal, isTrue);
    });

    test('only allows writes while connected', () {
      expect(BackendConnectionState.connected.canWrite, isTrue);
      for (final state in BackendConnectionState.values.where(
        (state) => state != BackendConnectionState.connected,
      )) {
        expect(
          state.canWrite,
          isFalse,
          reason: '$state must not accept writes',
        );
      }
    });
  });

  group('TerminalBackendBase lifecycle', () {
    test('starts idle', () {
      final backend = TestBackend();
      expect(backend.state, BackendConnectionState.idle);
      expect(backend.failure, isNull);
    });

    test('start moves idle -> connecting -> connected', () async {
      final backend = TestBackend();
      final seen = <BackendConnectionState>[];
      backend.states.listen(seen.add);

      await backend.start();
      await pumpEventQueue();

      expect(backend.state, BackendConnectionState.connected);
      expect(seen, [
        BackendConnectionState.idle,
        BackendConnectionState.connecting,
        BackendConnectionState.connected,
      ]);
    });

    test('a late subscriber immediately sees the current state', () async {
      final backend = TestBackend();
      await backend.start();

      final seen = <BackendConnectionState>[];
      backend.states.listen(seen.add);
      await pumpEventQueue();

      expect(
        seen.first,
        BackendConnectionState.connected,
        reason: 'a listener attaching late must not sit on idle forever',
      );
    });

    test(
      'a subscriber attaching after a terminal state gets it and done',
      () async {
        final backend = TestBackend();
        await backend.start();
        await backend.close();

        final seen = <BackendConnectionState>[];
        var done = false;
        backend.states.listen(seen.add, onDone: () => done = true);
        await pumpEventQueue();

        expect(seen, [BackendConnectionState.closed]);
        expect(done, isTrue);
      },
    );

    test('starting twice is a programming error', () async {
      final backend = TestBackend();
      await backend.start();

      expect(backend.start, throwsA(isA<StateError>()));
    });

    test('a failure during connect is recorded and rethrown', () async {
      const failure = TerminalBackendFailure(
        TerminalBackendFailureKind.authentication,
        'Authentication failed.',
      );
      final backend = TestBackend(onConnect: (_) => throw failure);

      await expectLater(
        backend.start(),
        throwsA(
          isA<TerminalBackendFailure>().having(
            (failure) => failure.kind,
            'kind',
            TerminalBackendFailureKind.authentication,
          ),
        ),
      );
      expect(backend.state, BackendConnectionState.error);
      expect(backend.failure, same(failure));
    });

    test(
      'an unexpected error during connect is mapped, never leaked',
      () async {
        final backend = TestBackend(
          onConnect: (_) => throw const FormatException('socket gibberish'),
        );

        await expectLater(
          backend.start(),
          throwsA(isA<TerminalBackendFailure>()),
        );
        expect(backend.failure!.kind, TerminalBackendFailureKind.unknown);
        expect(
          backend.failure!.message,
          isNot(contains('gibberish')),
          reason: 'a raw exception string must never reach the user',
        );
        expect(backend.failure!.cause, isA<FormatException>());
      },
    );

    test('exitCode completes when the session closes', () async {
      final backend = TestBackend();
      await backend.start();
      backend.setClosed(42);

      expect(await backend.exitCode, 42);
    });

    test('exitCode completes with null when the session fails', () async {
      final backend = TestBackend();
      await backend.start();
      backend.setFailed(
        const TerminalBackendFailure(
          TerminalBackendFailureKind.network,
          'Connection lost.',
        ),
      );

      expect(await backend.exitCode, isNull);
    });

    test('terminal states are final', () async {
      final backend = TestBackend();
      await backend.start();

      backend
        ..setClosed(1)
        ..setFailed(
          const TerminalBackendFailure(
            TerminalBackendFailureKind.unknown,
            'too late',
          ),
        )
        ..setClosed(2);

      expect(backend.state, BackendConnectionState.closed);
      expect(backend.failure, isNull);
      expect(await backend.exitCode, 1);
    });

    test('close is idempotent and disconnects exactly once', () async {
      final backend = TestBackend();
      await backend.start();

      await backend.close();
      await backend.close();

      expect(backend.disconnectCount, 1);
      expect(backend.state, BackendConnectionState.closed);
    });

    test('close before start is safe', () async {
      final backend = TestBackend();
      await backend.close();
      expect(backend.state, BackendConnectionState.closed);
    });
  });

  group('TerminalBackendBase writes', () {
    test('writes reach the peer while connected', () async {
      final backend = TestBackend();
      await backend.start();

      backend.write(b([1, 2, 3]));

      expect(backend.sent, [
        b([1, 2, 3]),
      ]);
    });

    test('writes before start are dropped', () async {
      // The write happens while the backend is still idle.
      final backend = TestBackend()..write(b([1]));

      expect(backend.sent, isEmpty);
    });

    test('writes after close are dropped rather than throwing', () async {
      final backend = TestBackend();
      await backend.start();
      await backend.close();

      // A keystroke racing a disconnect must not throw at the key handler.
      backend.write(b([2]));

      expect(backend.sent, isEmpty);
    });
  });

  group('TerminalBackendBase output', () {
    test('pipeOutput forwards bytes', () async {
      final source = StreamController<Uint8List>();
      final backend = TestBackend(source: source.stream);
      await backend.start();

      final received = <Uint8List>[];
      backend.output.listen(received.add);

      source.add(b([7, 8]));
      await pumpEventQueue();

      expect(received, [
        b([7, 8]),
      ]);
      await source.close();
    });

    test('the session closes when its source completes', () async {
      final source = StreamController<Uint8List>();
      final backend = TestBackend(source: source.stream);
      await backend.start();
      backend.output.listen((_) {});

      await source.close();
      await pumpEventQueue();

      expect(backend.state, BackendConnectionState.closed);
    });

    test('a source error fails the session as a lost connection', () async {
      final source = StreamController<Uint8List>();
      final backend = TestBackend(source: source.stream);
      await backend.start();
      backend.output.listen((_) {});

      source.addError(const FormatException('reset by peer'));
      await pumpEventQueue();

      expect(backend.state, BackendConnectionState.error);
      expect(backend.failure!.kind, TerminalBackendFailureKind.disconnected);
      expect(backend.failure!.message, isNot(contains('reset by peer')));
    });

    test('output pauses propagate to the source', () async {
      var paused = false;
      final source = StreamController<Uint8List>(
        onPause: () => paused = true,
        onResume: () => paused = false,
      );
      final backend = TestBackend(source: source.stream);
      await backend.start();

      final subscription = backend.output.listen((_) {});
      await pumpEventQueue();

      subscription.pause();
      await pumpEventQueue();
      expect(paused, isTrue);
      expect(backend.isOutputPaused, isTrue);

      subscription.resume();
      await pumpEventQueue();
      expect(paused, isFalse);

      await subscription.cancel();
      await source.close();
    });
  });
}
