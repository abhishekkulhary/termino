import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/shared/design/terminal_palette.dart';

import '../../support/test_database.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = testContainer());
  tearDown(() => container.dispose());

  /// Loads the stored settings, as the app does at startup, and returns them.
  Future<TerminalSettings> settings() => container
      .read(settingsProvider.notifier)
      .load()
      .then((_) => container.read(settingsProvider));

  group('defaults', () {
    test('are sensible before anything is saved', () async {
      final current = await settings();

      expect(current.paletteId, isNull);
      expect(current.themeMode, AppThemeMode.system);
      expect(current.fontSize, 14);
      expect(current.lineHeight, 1.2);
      expect(current.cursorShape, TerminalCursorShape.block);
      expect(current.cursorBlinks, isTrue);
      expect(current.scrollbackLines, 10000);
    });
  });

  group('persistence', () {
    test('a change survives a reload', () async {
      await settings();
      await container.read(settingsProvider.notifier).setFontSize(20);

      // A fresh read goes back to storage.
      final stored = await container.read(settingsStoreProvider).read();

      expect(stored.fontSize, 20);
    });

    test('each setting round-trips', () async {
      await settings();
      final controller = container.read(settingsProvider.notifier);

      await controller.setPalette('dracula');
      await controller.setThemeMode(AppThemeMode.dark);
      await controller.setLineHeight(1.5);
      await controller.setCursorShape(TerminalCursorShape.bar);
      await controller.setCursorBlinks(blinks: false);
      await controller.setBell(BellBehaviour.haptic);
      await controller.setScrollback(50000);

      final stored = await container.read(settingsStoreProvider).read();

      expect(stored.paletteId, 'dracula');
      expect(stored.themeMode, AppThemeMode.dark);
      expect(stored.lineHeight, 1.5);
      expect(stored.cursorShape, TerminalCursorShape.bar);
      expect(stored.cursorBlinks, isFalse);
      expect(stored.bell, BellBehaviour.haptic);
      expect(stored.scrollbackLines, 50000);
    });

    test('reset returns everything to the defaults', () async {
      await settings();
      final controller = container.read(settingsProvider.notifier);
      await controller.setFontSize(28);
      await controller.setPalette('nord');

      await controller.reset();

      final stored = await container.read(settingsStoreProvider).read();
      expect(stored.fontSize, 14);
      expect(stored.paletteId, isNull);
    });
  });

  group('clamping', () {
    test('font size stays within a legible range', () async {
      await settings();
      final controller = container.read(settingsProvider.notifier);

      await controller.setFontSize(1000);
      expect(
        (await container.read(settingsStoreProvider).read()).fontSize,
        TerminalSettings.maxFontSize,
      );

      await controller.setFontSize(-5);
      expect(
        (await container.read(settingsStoreProvider).read()).fontSize,
        TerminalSettings.minFontSize,
      );
    });

    test('line height stays within a usable range', () async {
      await settings();
      final controller = container.read(settingsProvider.notifier);

      await controller.setLineHeight(9);
      expect(
        (await container.read(settingsStoreProvider).read()).lineHeight,
        2.0,
      );
    });
  });

  group('palette selection', () {
    test('follows the app theme when nothing is chosen', () async {
      await settings();

      expect(
        container.read(activePaletteProvider(Brightness.dark)).id,
        TerminalPalettes.dark.id,
      );
      expect(
        container.read(activePaletteProvider(Brightness.light)).id,
        TerminalPalettes.light.id,
      );
    });

    test('an explicit choice wins over the app theme', () async {
      await settings();
      await container
          .read(settingsProvider.notifier)
          .setPalette('gruvbox-dark');

      expect(
        container.read(activePaletteProvider(Brightness.light)).id,
        'gruvbox-dark',
        reason: 'a chosen palette applies whatever the app theme is',
      );
    });

    test('an unknown palette id falls back rather than failing', () async {
      await settings();
      await container.read(settingsProvider.notifier).setPalette('deleted');

      expect(
        container.read(activePaletteProvider(Brightness.dark)).id,
        TerminalPalettes.dark.id,
      );
    });
  });

  group('palette catalogue', () {
    test('ships the palettes the brief names', () {
      final ids = TerminalPalettes.all.map((p) => p.id);

      expect(
        ids,
        containsAll([
          'dracula',
          'solarized-dark',
          'solarized-light',
          'nord',
          'gruvbox-dark',
          'one-dark',
        ]),
      );
    });

    test('every palette has a distinct id and a name', () {
      final ids = TerminalPalettes.all.map((p) => p.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      for (final palette in TerminalPalettes.all) {
        expect(palette.name, isNotEmpty);
      }
    });

    test('every palette keeps foreground and background distinct', () {
      // A palette whose text matches its background is unreadable, and the
      // mistake is easy to make when transcribing colour values by hand.
      for (final palette in TerminalPalettes.all) {
        expect(
          palette.theme.foreground,
          isNot(palette.theme.background),
          reason: palette.name,
        );
      }
    });

    test('byId finds a palette and returns null for an unknown one', () {
      expect(TerminalPalettes.byId('nord')?.name, 'Nord');
      expect(TerminalPalettes.byId('nope'), isNull);
    });
  });
}
