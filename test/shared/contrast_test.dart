import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/shared/design/contrast.dart';

void main() {
  const white = Color(0xFFFFFFFF);
  const black = Color(0xFF000000);

  // The two the app actually draws on.
  const lightSurface = Color(0xFFFFFFFF);
  const darkSurface = Color(0xFF0A0E16);

  // The neon palette a host colour is chosen from.
  const neonCyan = Color(0xFF2BE3FF);
  const neonGreen = Color(0xFF2BE58B);
  const neonMagenta = Color(0xFFFF4D9D);

  group('ratio', () {
    test('matches the WCAG extremes', () {
      expect(Contrast.ratio(black, white), closeTo(21, 0.1));
      expect(Contrast.ratio(white, white), closeTo(1, 0.001));
    });

    test('is symmetric', () {
      expect(
        Contrast.ratio(neonCyan, white),
        closeTo(Contrast.ratio(white, neonCyan), 0.001),
      );
    });

    test('agrees with the known value for mid grey on white', () {
      // #767676 on white is the canonical 4.5:1 boundary case.
      expect(
        Contrast.ratio(const Color(0xFF767676), white),
        closeTo(4.54, 0.05),
      );
    });
  });

  group('readableOn a light surface', () {
    test('every neon accent starts out illegible', () {
      // The premise of the whole exercise: this palette was designed for a
      // near-black canvas and none of it survives a white one.
      for (final colour in [neonCyan, neonGreen, neonMagenta]) {
        expect(
          Contrast.ratio(colour, lightSurface),
          lessThan(3.2),
          reason: '$colour was expected to be too pale for white',
        );
      }
    });

    test('darkens them until they read', () {
      for (final colour in [neonCyan, neonGreen, neonMagenta]) {
        final fixed = Contrast.readableOn(colour, lightSurface);
        expect(
          Contrast.ratio(fixed, lightSurface),
          greaterThanOrEqualTo(3.2),
          reason: '$colour was not brought up to the minimum',
        );
      }
    });

    test('keeps the hue, so a host stays "the pink one"', () {
      final fixed = Contrast.readableOn(neonMagenta, lightSurface);
      expect(
        HSLColor.fromColor(fixed).hue,
        closeTo(HSLColor.fromColor(neonMagenta).hue, 1),
      );
      expect(
        HSLColor.fromColor(fixed).lightness,
        lessThan(HSLColor.fromColor(neonMagenta).lightness),
      );
    });

    test('leaves a colour that already reads exactly as it was', () {
      const alreadyDark = Color(0xFF0A3D62);
      expect(Contrast.readableOn(alreadyDark, lightSurface), alreadyDark);
    });
  });

  group('readableOn a dark surface', () {
    test('leaves the neon palette untouched', () {
      // The dark theme is where these colours were designed to be read;
      // adapting them there would be changing something that works.
      for (final colour in [neonCyan, neonGreen, neonMagenta]) {
        expect(Contrast.readableOn(colour, darkSurface), colour);
      }
    });

    test('lightens something too dark to see', () {
      const nearlyBlack = Color(0xFF101418);
      final fixed = Contrast.readableOn(nearlyBlack, darkSurface);

      expect(fixed, isNot(nearlyBlack));
      expect(Contrast.ratio(fixed, darkSurface), greaterThanOrEqualTo(3.2));
    });
  });

  test('a colour identical to its background is still moved somewhere', () {
    // Nothing can reach the minimum against a mid grey, but returning the
    // original unchanged would leave it invisible.
    const grey = Color(0xFF808080);
    expect(Contrast.readableOn(grey, grey), isNot(grey));
  });

  test('honours a stricter minimum', () {
    final relaxed = Contrast.readableOn(neonCyan, lightSurface);
    final strict = Contrast.readableOn(neonCyan, lightSurface, minimum: 7);

    expect(Contrast.ratio(strict, lightSurface), greaterThanOrEqualTo(7));
    expect(
      HSLColor.fromColor(strict).lightness,
      lessThan(HSLColor.fromColor(relaxed).lightness),
    );
  });
}
