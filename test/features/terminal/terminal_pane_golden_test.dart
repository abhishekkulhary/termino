@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/terminal_pane.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';

import '../../support/pump.dart';
import '../../support/test_fonts.dart';

/// A fixture with no delays, so a golden is deterministic. It exercises the
/// things a terminal must get right: the 16 ANSI colours, truecolour, box
/// drawing, block elements and bold/dim/italic attributes.
const _fixture =
    '\x1b[1;36mTermino\x1b[0m \x1b[2m— rendering check\x1b[0m\r\n'
    '\r\n'
    '  ANSI     '
    '\x1b[31m██\x1b[32m██\x1b[33m██\x1b[34m██\x1b[35m██\x1b[36m██\x1b[37m██'
    '\x1b[0m\r\n'
    '  bright   '
    '\x1b[91m██\x1b[92m██\x1b[93m██\x1b[94m██\x1b[95m██\x1b[96m██\x1b[97m██'
    '\x1b[0m\r\n'
    '  true     '
    '\x1b[38;2;255;110;80m███\x1b[38;2;255;190;90m███'
    '\x1b[38;2;110;255;140m███\x1b[38;2;110;170;255m███'
    '\x1b[38;2;208;139;255m███\x1b[0m\r\n'
    '\r\n'
    '  ┌──────────────┬──────────────┐\r\n'
    '  │ box drawing  │ ░▒▓█▉▊▋▌▍▎▏  │\r\n'
    '  ├──────────────┼──────────────┤\r\n'
    '  │ \x1b[1mbold\x1b[0m \x1b[3mitalic\x1b[0m  │ '
    '\x1b[4munderline\x1b[0m    │\r\n'
    '  └──────────────┴──────────────┘\r\n'
    '\r\n'
    '\x1b[32m➜\x1b[0m  \x1b[34m~/projects/Termino\x1b[0m ';

TerminalSession _fixtureSession() => TerminalSession(
  id: 'golden',
  backend: MockBackend(
    frames: [MockOutputFrame.text(_fixture)],
    closeWhenDrained: false,
  ),
  batcher: const TerminalOutputBatcher(window: Duration.zero),
);

Future<void> _pumpPane(
  WidgetTester tester,
  TerminalSession session, {
  required Brightness brightness,
}) async {
  await session.start();
  await pumpApp(
    tester,
    Scaffold(body: TerminalPane(session: session)),
    size: const Size(720, 420),
    brightness: brightness,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTerminalFont);

  testWidgets('renders terminal output on the dark palette', (tester) async {
    final session = _fixtureSession();
    addTearDown(session.dispose);

    await _pumpPane(tester, session, brightness: Brightness.dark);

    await expectLater(
      find.byType(TerminalPane),
      matchesGoldenFile('goldens/terminal_pane_dark.png'),
    );
  });

  testWidgets('renders terminal output on the light palette', (tester) async {
    final session = _fixtureSession();
    addTearDown(session.dispose);

    await _pumpPane(tester, session, brightness: Brightness.light);

    await expectLater(
      find.byType(TerminalPane),
      matchesGoldenFile('goldens/terminal_pane_light.png'),
    );
  });

  testWidgets('shows a banner when the session failed', (tester) async {
    final session = TerminalSession(
      id: 'golden-error',
      backend: MockBackend.failing(
        const TerminalBackendFailure(
          TerminalBackendFailureKind.hostKeyMismatch,
          'The host key for build-01 has changed since you last connected.',
        ),
      ),
      batcher: const TerminalOutputBatcher(window: Duration.zero),
    );
    addTearDown(session.dispose);

    await expectLater(session.start(), throwsA(isA<TerminalBackendFailure>()));
    await pumpApp(
      tester,
      Scaffold(body: TerminalPane(session: session)),
      size: const Size(720, 200),
    );

    await expectLater(
      find.byType(TerminalPane),
      matchesGoldenFile('goldens/terminal_pane_error.png'),
    );
  });
}
