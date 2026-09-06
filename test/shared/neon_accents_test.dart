import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/shared/design/app_theme.dart';
import 'package:termino/shared/design/contrast.dart';
import 'package:termino/shared/design/neon_accents.dart';

/// The two themes say the same things with different physics: the dark one
/// with emitted light, the light one with cast shadow and ink. These assert
/// that both actually say them, because the light theme has quietly stopped
/// once already.
void main() {
  late NeonAccents dark;
  late NeonAccents light;

  setUp(() {
    dark = AppTheme.dark().extension<NeonAccents>()!;
    light = AppTheme.light().extension<NeonAccents>()!;
  });

  // A colour from the palette a host's colour is chosen from.
  const neonCyan = Color(0xFF2BE3FF);

  test('both themes ship the accents', () {
    expect(dark, isNotNull);
    expect(light, isNotNull);
  });

  group('depth', () {
    test('the dark theme glows in the accent colour', () {
      final shadows = dark.depth(neonCyan);
      expect(shadows, isNotEmpty);
      expect(
        shadows.first.color.toARGB32() & 0x00FFFFFF,
        neonCyan.toARGB32() & 0x00FFFFFF,
        reason: 'a halo is the accent itself, spread out',
      );
      expect(shadows.first.offset, Offset.zero, reason: 'light does not fall');
    });

    test('the light theme casts a shadow instead', () {
      final shadows = light.depth(neonCyan);
      expect(shadows, isNotEmpty);
      expect(
        shadows.first.offset.dy,
        greaterThan(0),
        reason: 'a shadow falls downwards; a glow does not fall',
      );
      expect(
        shadows.first.color.toARGB32() & 0x00FFFFFF,
        isNot(neonCyan.toARGB32() & 0x00FFFFFF),
        reason: 'a cast shadow is not the colour of the thing casting it',
      );
    });

    test('selection is stronger than rest, in both', () {
      for (final accents in [dark, light]) {
        final resting = accents.depth(neonCyan).first;
        final selected = accents.depth(neonCyan, selected: true).first;
        expect(selected.blurRadius, greaterThan(resting.blurRadius));
      }
    });
  });

  group('selection', () {
    test('the dark theme leaves the fill alone, because the glow says it', () {
      expect(dark.selectionFill(neonCyan), isNull);
    });

    test('the light theme tints — and stays opaque', () {
      final fill = light.selectionFill(neonCyan);
      expect(fill, isNotNull);
      expect(
        fill!.a,
        1,
        reason:
            'a translucent fill used as a panel surface makes the panel '
            'translucent, which is exactly what it did the first time',
      );
      expect(fill, isNot(light.panelTop), reason: 'it has to be visible');
    });
  });

  group('readable', () {
    test('the dark theme leaves a neon accent as it was chosen', () {
      expect(dark.readable(neonCyan), neonCyan);
    });

    test('the light theme brings it up to a legible contrast', () {
      final adapted = light.readable(neonCyan);
      expect(adapted, isNot(neonCyan));
      expect(Contrast.ratio(adapted, light.surface), greaterThanOrEqualTo(3.2));
    });

    test('each theme adapts against its own surface', () {
      expect(dark.surface, isNot(light.surface));
      expect(
        Contrast.ratio(dark.readable(neonCyan), dark.surface),
        greaterThanOrEqualTo(3.2),
      );
    });
  });

  test('glow is switched off in the light theme, not merely faded', () {
    // A soft halo on white reads as a rendering fault, not as light.
    expect(light.glowStrength, 0);
    expect(light.glow(neonCyan), isEmpty);
    expect(light.glowStrong(neonCyan), isEmpty);
    expect(dark.glow(neonCyan), isNotEmpty);
  });

  test('an accent fills and edges more strongly where there is no glow', () {
    expect(light.accentEdge, greaterThan(dark.accentEdge));
  });
}
