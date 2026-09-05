@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/settings/presentation/settings_screen.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/terminal_pane.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';
import 'package:termino/shared/design/terminal_palette.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';
import '../../support/test_fonts.dart';

/// Exercises the colours a palette is judged by.
const _normal =
    '\x1b[31m██\x1b[32m██\x1b[33m██\x1b[34m██\x1b[35m██\x1b[36m██\x1b[37m██';
const _bright =
    '\x1b[91m██\x1b[92m██\x1b[93m██\x1b[94m██\x1b[95m██\x1b[96m██\x1b[97m██';

const _fixture =
    '\x1b[1mTermino\x1b[0m — palette check\r\n'
    '\r\n'
    '  $_normal\x1b[0m\r\n'
    '  $_bright\x1b[0m\r\n'
    '\r\n'
    '  \x1b[32m✓\x1b[0m ok   \x1b[31m✗\x1b[0m failed   '
    '\x1b[33m!\x1b[0m warning\r\n'
    '  ┌────────┬────────┐\r\n'
    '  │ vim    │ htop   │\r\n'
    '  └────────┴────────┘\r\n'
    '\r\n'
    '\x1b[34m~/projects\x1b[0m \x1b[32m\$\x1b[0m ';

void main() {
  setUpAll(loadTerminalFont);

  group('terminal palettes', () {
    for (final palette in TerminalPalettes.all) {
      testWidgets('${palette.name} renders', (tester) async {
        final container = testContainer();
        addTearDown(container.dispose);
        await container.read(settingsProvider.notifier).setPalette(palette.id);

        final session = TerminalSession(
          id: 'golden-${palette.id}',
          backend: MockBackend(
            frames: [MockOutputFrame.text(_fixture)],
            closeWhenDrained: false,
          ),
          batcher: const TerminalOutputBatcher(window: Duration.zero),
        );
        addTearDown(session.dispose);
        await session.start();

        await pumpApp(
          tester,
          Scaffold(body: TerminalPane(session: session)),
          size: const Size(420, 260),
          brightness: palette.brightness,
          container: container,
        );

        await expectLater(
          find.byType(TerminalPane),
          matchesGoldenFile('goldens/palette_${palette.id}.png'),
        );

        expect(session.connectionState.value, BackendConnectionState.connected);
      });
    }
  });

  testWidgets('the settings screen shows every palette as a swatch', (
    tester,
  ) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await pumpApp(
      tester,
      const Scaffold(body: SettingsScreen()),
      size: const Size(560, 900),
      container: container,
    );

    for (final palette in TerminalPalettes.all) {
      expect(find.text(palette.name), findsOneWidget, reason: palette.name);
    }
    expect(find.text('Automatic'), findsOneWidget);

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });
}
