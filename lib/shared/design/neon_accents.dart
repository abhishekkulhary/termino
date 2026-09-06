import 'package:flutter/material.dart';
import 'package:termino/shared/design/contrast.dart';

/// The parts of the neon look that Material's [ColorScheme] has no name for.
///
/// Glow, grid lines and status colours are as much a part of this design as
/// the palette is, and feature widgets need them. Putting them in a
/// [ThemeExtension] rather than a constants file keeps the existing rule
/// intact — nothing outside the design layer names a colour — while letting a
/// widget ask the theme for `neon.glow(neon.online)` and get something that
/// changes with the palette.
@immutable
class NeonAccents extends ThemeExtension<NeonAccents> {
  /// Creates the accent set.
  const new({
    required this.online,
    required this.busy,
    required this.offline,
    required this.grid,
    required this.panelBorder,
    required this.panelTop,
    required this.panelBottom,
    required this.glowStrength,
    required this.surface,
    required this.shadow,
  });

  /// A live, healthy connection.
  final Color online;

  /// Connecting, reconnecting, or a transfer in flight.
  final Color busy;

  /// Disconnected, failed, or unreachable.
  final Color offline;

  /// Hairline rules: grid backdrops, dividers between dense rows.
  final Color grid;

  /// The 1px edge that gives a panel its shape against a near-black canvas.
  final Color panelBorder;

  /// Top of the subtle vertical wash inside a panel.
  final Color panelTop;

  /// Bottom of that wash.
  final Color panelBottom;

  /// How much glow to draw, 0–1.
  ///
  /// A single dial rather than per-widget opacities: glow is the signature of
  /// this theme and also the first thing that becomes tiring, so it is tunable
  /// in one place — and set to zero for the light theme, where it only looks
  /// like a printing error.
  final double glowStrength;

  /// The surface an accent will be drawn against, for [readable].
  final Color surface;

  /// The colour of a cast shadow. Transparent where shadows are not used.
  ///
  /// The dark theme has no use for one: a shadow needs something to fall on,
  /// and there is nothing behind a panel on a near-black ground. Light is the
  /// opposite — it has no glow to give, and a shadow is how it says "above".
  final Color shadow;

  /// [color], adjusted so it can actually be seen on [surface].
  ///
  /// Host colours are chosen once, from a palette built for the dark theme, and
  /// then drawn in both. Without this the same cyan that reads as a bright mark
  /// on black is a pale smear on white.
  Color readable(Color color) => Contrast.readableOn(color, surface);

  /// How solidly an accent fills a chip or an avatar behind its glyph.
  ///
  /// A wash that reads on black is nearly invisible on white, where the eye has
  /// no glow to help it.
  double get accentFill => glowStrength > 0 ? 0.14 : 0.12;

  /// How strongly an accent draws its own edge.
  double get accentEdge => glowStrength > 0 ? 0.55 : 0.65;

  /// The fill that marks a panel as the current selection.
  ///
  /// Null in the dark theme, where the glow already says it. Light has to say
  /// it some other way, and a tint is quieter than a border alone is loud.
  ///
  /// Blended to an opaque colour rather than returned as a translucent one: a
  /// panel is a surface, and a 7% tint used as the surface makes the whole
  /// thing 93% transparent — which is exactly what it did the first time.
  Color? selectionFill(Color accent) => glowStrength > 0
      ? null
      : Color.alphaBlend(readable(accent).withValues(alpha: 0.08), panelTop);

  /// What lifts a panel off the page: a halo in the dark, a cast shadow in the
  /// light. One call site, two physics.
  List<BoxShadow> depth(Color accent, {bool selected = false}) {
    if (glowStrength > 0) {
      return selected ? glowStrong(accent) : glow(accent, blur: 10);
    }
    return [
      BoxShadow(
        color: shadow.withValues(alpha: selected ? 0.14 : 0.07),
        blurRadius: selected ? 18 : 10,
        offset: Offset(0, selected ? 4 : 2),
      ),
    ];
  }

  /// A glow suitable for a resting element of [color].
  List<BoxShadow> glow(Color color, {double blur = 14, double spread = -2}) {
    if (glowStrength <= 0) return const [];
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.34 * glowStrength),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  /// A brighter glow, for something focused, hovered or actively running.
  List<BoxShadow> glowStrong(Color color) {
    if (glowStrength <= 0) return const [];
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.50 * glowStrength),
        blurRadius: 22,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.22 * glowStrength),
        blurRadius: 40,
        spreadRadius: 2,
      ),
    ];
  }

  /// The vertical wash that gives a panel depth.
  LinearGradient get panelGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [panelTop, panelBottom],
  );

  /// The accents for the current theme.
  static NeonAccents of(BuildContext context) =>
      Theme.of(context).extension<NeonAccents>()!;

  @override
  NeonAccents copyWith({
    Color? online,
    Color? busy,
    Color? offline,
    Color? grid,
    Color? panelBorder,
    Color? panelTop,
    Color? panelBottom,
    double? glowStrength,
    Color? surface,
    Color? shadow,
  }) => NeonAccents(
    online: online ?? this.online,
    busy: busy ?? this.busy,
    offline: offline ?? this.offline,
    grid: grid ?? this.grid,
    panelBorder: panelBorder ?? this.panelBorder,
    panelTop: panelTop ?? this.panelTop,
    panelBottom: panelBottom ?? this.panelBottom,
    glowStrength: glowStrength ?? this.glowStrength,
    surface: surface ?? this.surface,
    shadow: shadow ?? this.shadow,
  );

  @override
  NeonAccents lerp(covariant NeonAccents? other, double t) {
    if (other == null) return this;
    return NeonAccents(
      online: Color.lerp(online, other.online, t)!,
      busy: Color.lerp(busy, other.busy, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      panelTop: Color.lerp(panelTop, other.panelTop, t)!,
      panelBottom: Color.lerp(panelBottom, other.panelBottom, t)!,
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
      surface: Color.lerp(surface, other.surface, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
