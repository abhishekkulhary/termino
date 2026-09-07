import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/settings/presentation/font_picker.dart';
import 'package:termino/features/settings/presentation/settings_screen.dart';
import 'package:termino/shared/design/terminal_palette.dart';
import 'package:termino/shared/design/tokens.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// Flutter cannot tell whether a font is installed, so an unknown name falls
/// back in silence. What this can guarantee is that the choice reaches the
/// grid, and that picking one never costs the box drawing a prompt is made of.
void main() {
  group('the style the grid is drawn in', () {
    test('uses the bundled font when nothing is chosen', () {
      final style = TerminalPalettes.neon.styleWith();

      expect(style.fontFamily, Fonts.mono);
      expect(style.fontFamilyFallback, Fonts.monoFallback);
    });

    test('uses the chosen family, keeping the bundled one behind it', () {
      final style = TerminalPalettes.neon.styleWith(fontFamily: 'Menlo');

      expect(style.fontFamily, 'Menlo');
      expect(
        style.fontFamilyFallback.first,
        Fonts.mono,
        reason:
            'Menlo has no Powerline or box-drawing glyphs; without the '
            'bundled font first in the fallbacks, choosing a font fills a '
            'prompt with tofu',
      );
    });

    test('keeps size and line height independent of the family', () {
      final style = TerminalPalettes.neon.styleWith(
        fontFamily: 'Fira Code',
        fontSize: 18,
        lineHeight: 1.5,
      );

      expect(style.fontSize, 18);
      expect(style.height, 1.5);
    });
  });

  group('choosing one', () {
    test(
      'an empty name means the bundled font, not a family called ""',
      () async {
        final container = testContainer();
        addTearDown(container.dispose);
        final controller = container.read(settingsProvider.notifier);

        // Awaited: updates are chained, so an unawaited change has not landed.
        await controller.setFontFamily('Menlo');
        expect(container.read(currentSettingsProvider).fontFamily, 'Menlo');

        await controller.setFontFamily('   ');
        expect(container.read(currentSettingsProvider).fontFamily, isNull);
      },
    );

    test('a name is trimmed', () async {
      final container = testContainer();
      addTearDown(container.dispose);

      await container
          .read(settingsProvider.notifier)
          .setFontFamily('  Fira Code  ');

      expect(container.read(currentSettingsProvider).fontFamily, 'Fira Code');
    });
  });

  group('suggestions', () {
    test('are platform-appropriate', () {
      expect(
        MonospaceSuggestions.forPlatform(platform: 'macos'),
        contains('Menlo'),
      );
      expect(
        MonospaceSuggestions.forPlatform(platform: 'windows'),
        contains('Consolas'),
      );
      expect(
        MonospaceSuggestions.forPlatform(platform: 'linux'),
        contains('DejaVu Sans Mono'),
      );
    });

    test('an unknown platform still offers something', () {
      // Better a generic name than an empty dropdown.
      expect(MonospaceSuggestions.forPlatform(platform: 'plan9'), isNotEmpty);
    });

    test('are short enough to read', () {
      for (final platform in ['macos', 'windows', 'linux', 'android']) {
        expect(
          MonospaceSuggestions.forPlatform(platform: platform).length,
          lessThanOrEqualTo(6),
          reason: 'a list of names nobody has is not a feature',
        );
      }
    });
  });

  testWidgets('the preview is drawn in the family that was chosen', (
    tester,
  ) async {
    // The preview is the only honest way to tell someone their font took,
    // since a missing family falls back without complaint. If it rendered in
    // the bundled font it would say nothing at all.
    final container = testContainer();
    await container.read(settingsProvider.notifier).setFontFamily('Menlo');

    await pumpApp(tester, const SettingsScreen(), container: container);
    await tester.scrollUntilVisible(
      find.text('Font'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final preview = tester.widget<Text>(find.textContaining('ILl1'));

    expect(preview.style?.fontFamily, 'Menlo');
    expect(
      preview.style?.fontFamilyFallback?.first,
      Fonts.mono,
      reason: 'the preview falls back exactly as the grid does',
    );
  });
}
