import 'dart:math';

import 'package:flutter/painting.dart';

/// Keeps a colour legible against the surface it is drawn on.
///
/// A host's colour is chosen once and then drawn in both themes. The palette
/// people pick from is a neon one — it is built for a near-black canvas — so on
/// a white surface the same cyan is a pale smear and the bolt icon beside it
/// all but disappears. Storing two colours per host would push the problem onto
/// the user, who did not ask to art-direct anything. Adapting the one they
/// chose keeps their choice recognisable and readable in both.
///
/// Pure, and the arithmetic is the WCAG definition, so it is tested directly.
abstract final class Contrast {
  /// The WCAG contrast ratio between [a] and [b], from 1 to 21.
  static double ratio(Color a, Color b) {
    final first = _luminance(a);
    final second = _luminance(b);
    final lighter = first > second ? first : second;
    final darker = first > second ? second : first;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// [color], darkened or lightened until it reads against [background].
  ///
  /// Hue and saturation are held: what makes a host recognisable at a glance is
  /// that it is "the pink one", not its exact lightness. Only lightness moves,
  /// and only as far as it must.
  ///
  /// Returns [color] unchanged when it already passes, so the dark theme —
  /// where the palette was designed to be read — is untouched.
  static Color readableOn(
    Color color,
    Color background, {
    double minimum = 3.2,
  }) {
    if (ratio(color, background) >= minimum) return color;

    final hsl = HSLColor.fromColor(color);
    // Move away from the background: darker on a light surface, lighter on a
    // dark one. Stepping rather than solving keeps this obvious to read, and
    // fifty steps of 2% covers the whole range.
    final towardsDark = _luminance(background) > 0.35;

    var best = color;
    for (var step = 1; step <= 50; step++) {
      final lightness =
          (towardsDark
                  ? hsl.lightness - step * 0.02
                  : hsl.lightness + step * 0.02)
              .clamp(0.0, 1.0);
      final candidate = hsl.withLightness(lightness).toColor();
      best = candidate;
      if (ratio(candidate, background) >= minimum) return candidate;
      if (lightness == 0 || lightness == 1) break;
    }

    // Black or white was still not enough, which means the background is
    // mid-grey. The best available is better than the original.
    return best;
  }

  /// Relative luminance, as WCAG defines it.
  static double _luminance(Color color) {
    double channel(double value) => value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }
}
