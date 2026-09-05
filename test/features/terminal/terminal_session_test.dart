import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';
import 'package:xterm/xterm.dart';

/// Batching with a zero window keeps the wiring tests synchronous-ish without
/// changing what is being tested: the batcher has its own suite.
const _immediate = TerminalOutputBatcher(window: Duration.zero);

TerminalSession sessionFor(MockBackend backend, {String title = 'Terminal'}) =>
    TerminalSession(
      id: 'test',
      backend: backend,
      initialTitle: title,
      batcher: _immediate,
    );

/// The visible text of the terminal, trailing blanks trimmed.
String screenText(TerminalSession session) => session.terminal.buffer
    .getText()
    .split('\n')
    .map((line) => line.trimRight())
    .join('\n')
    .trimRight();

void main() {
  group('TerminalSession wiring', () {
    test('backend output reaches the terminal buffer', () async {
      final backend = MockBackend.text('hello world');
      final session = sessionFor(backend);

      await session.start();
      await pumpEventQueue();

      expect(screenText(session), contains('hello world'));
      await session.dispose();
    });

    test('decodes a multi-byte character split across two chunks', () async {
      // 'é' is 0xC3 0xA9. Splitting it across reads is exactly what a socket
      // does, and decoding each chunk independently would render two
      // replacement characters instead of one letter.
      final backend = MockBackend(
        frames: [
          MockOutputFrame(Uint8List.fromList([0xC3])),
          MockOutputFrame(
            Uint8List.fromList([0xA9]),
            delay: const Duration(milliseconds: 20),
          ),
        ],
        closeWhenDrained: false,
      );
      final session = sessionFor(backend);

      await session.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(screenText(session), 'é');
      await session.dispose();
    });

    test('malformed bytes are replaced, not fatal', () async {
      final backend = MockBackend(
        frames: [
          MockOutputFrame(Uint8List.fromList([0xFF, 0xFE])),
          MockOutputFrame.text('ok'),
        ],
        closeWhenDrained: false,
      );
      final session = sessionFor(backend);

      await session.start();
      await pumpEventQueue();

      expect(screenText(session), contains('ok'));
      await session.dispose();
    });

    test('terminal input reaches the backend', () async {
      final backend = MockBackend.text('');
      final session = sessionFor(backend);
      await session.start();

      session.terminal.textInput('ls -la');
      session.terminal.keyInput(TerminalKey.enter);
      await pumpEventQueue();

      expect(backend.writtenText, 'ls -la\r');
      await session.dispose();
    });

    test('sendText writes to the backend as if typed', () async {
      final backend = MockBackend.text('');
      final session = sessionFor(backend);
      await session.start();

      session.sendText('whoami\r');

      expect(backend.writtenText, 'whoami\r');
      await session.dispose();
    });

    test('resizing the terminal resizes the backend', () async {
      final backend = MockBackend.text('');
      final session = sessionFor(backend);
      await session.start();

      session.terminal.resize(100, 40, 800, 600);
      await pumpEventQueue();

      expect(backend.resizes, isNotEmpty);
      expect(backend.resizes.last.columns, 100);
      expect(backend.resizes.last.rows, 40);
      expect(backend.resizes.last.pixelWidth, 800);
      await session.dispose();
    });

    test('an OSC 2 title sequence updates the session title', () async {
      final backend = MockBackend.text('\x1b]2;abhishek@host: ~\x07');
      final session = sessionFor(backend);

      await session.start();
      await pumpEventQueue();

      expect(session.title.value, 'abhishek@host: ~');
      await session.dispose();
    });

    test('an empty title is ignored rather than blanking the tab', () async {
      final backend = MockBackend.text('\x1b]2;\x07');
      final session = sessionFor(backend, title: 'Demo');

      await session.start();
      await pumpEventQueue();

      expect(session.title.value, 'Demo');
      await session.dispose();
    });

    test('the bell is counted', () async {
      final backend = MockBackend.text('ding\x07\x07');
      final session = sessionFor(backend);

      await session.start();
      await pumpEventQueue();

      expect(session.bellCount.value, 2);
      await session.dispose();
    });

    test('connection state mirrors the backend', () async {
      final backend = MockBackend.text('');
      final session = sessionFor(backend);
      expect(session.connectionState.value, BackendConnectionState.idle);

      await session.start();
      await pumpEventQueue();
      expect(session.connectionState.value, BackendConnectionState.connected);

      await session.dispose();
    });

    test(
      'a failing backend leaves the session usable and explains itself',
      () async {
        const failure = TerminalBackendFailure(
          TerminalBackendFailureKind.network,
          'The host could not be reached.',
        );
        final session = sessionFor(MockBackend.failing(failure));

        await expectLater(session.start(), throwsA(same(failure)));
        await pumpEventQueue();

        expect(session.connectionState.value, BackendConnectionState.error);
        expect(session.backend.failure, same(failure));
        await session.dispose();
      },
    );

    test('disposing closes the backend and stops forwarding', () async {
      final backend = MockBackend.text('before');
      final session = sessionFor(backend);
      await session.start();
      await pumpEventQueue();

      await session.dispose();

      expect(backend.state, BackendConnectionState.closed);
      // Input after disposal must not reach a closed backend.
      final writesBefore = backend.writes.length;
      session.sendText('after');
      expect(backend.writes, hasLength(writesBefore));
    });

    test('disposing twice is safe', () async {
      final session = sessionFor(MockBackend.text(''));
      await session.start();

      await session.dispose();
      await session.dispose();
    });

    test('bytes emitted during connection are not missed', () async {
      // Callbacks are wired in the constructor, before start(), precisely so
      // that a banner printed the moment the session attaches still lands.
      final backend = MockBackend(
        frames: [MockOutputFrame.text('motd line')],
        closeWhenDrained: false,
      );
      final session = sessionFor(backend);

      await session.start();
      await pumpEventQueue();

      expect(screenText(session), contains('motd line'));
      await session.dispose();
    });
  });
}
