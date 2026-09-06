import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';

/// Builds the app's themes from the design tokens.
///
/// Nothing outside this file and [NeonAccents] names a colour. Feature widgets
/// read from `Theme.of(context).colorScheme`, `NeonAccents.of(context)` and the
/// token classes, so that a change of palette is a change in one place.
///
/// The scheme is written out rather than derived with `ColorScheme.fromSeed`.
/// A seeded scheme is tonally consistent by construction, which is exactly what
/// this design is not: it wants a near-black canvas with two or three colours
/// that are far brighter than anything around them. Handing that to the tonal
/// algorithm produces muted, evenly-lit surfaces — a perfectly nice theme, and
/// not this one.
abstract final class AppTheme {
  // --- Dark: the primary theme -----------------------------------------------

  /// The deepest surface. Nearly black, with just enough blue to stop it
  /// looking like a dead pixel field next to the terminal.
  static const _void = Color(0xFF05070C);
  static const _surface = Color(0xFF0A0E16);
  static const _surfaceLow = Color(0xFF0E141F);
  static const _surfaceHigh = Color(0xFF141C2A);
  static const _surfaceHighest = Color(0xFF1B2436);

  static const _cyan = Color(0xFF2BE3FF);
  static const _violet = Color(0xFF9D6BFF);
  static const _magenta = Color(0xFFFF4D9D);
  static const _green = Color(0xFF2BE58B);
  static const _amber = Color(0xFFFFC24D);
  static const _red = Color(0xFFFF5470);

  static const _text = Color(0xFFDCE6F2);
  static const _textDim = Color(0xFF8698B2);
  static const _outline = Color(0xFF223047);
  static const _outlineDim = Color(0xFF16202F);

  // --- Light: the same design in daylight ------------------------------------
  //
  // Neon is a dark-room idea; a light theme cannot glow. What carries across is
  // the structure — the same accents, the same shapes, the same hierarchy —
  // drawn as ink rather than light. Glow is switched off entirely rather than
  // faded, because a soft halo on white reads as a rendering fault.

  static const _lightCanvas = Color(0xFFE9EEF5);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightCyan = Color(0xFF04697F);
  static const _lightViolet = Color(0xFF6B3FD4);
  static const _lightMagenta = Color(0xFFC2185B);
  static const _lightText = Color(0xFF101725);
  static const _lightTextDim = Color(0xFF54637A);
  static const _lightOutline = Color(0xFFD2DCE8);

  /// The light theme.
  static ThemeData light() => _build(Brightness.light);

  /// The dark theme.
  static ThemeData dark() => _build(Brightness.dark);

  /// The window background, needed before a theme exists — by the native shell
  /// on desktop and by the splash screen.
  static const Color canvas = _void;

  static ColorScheme _scheme(Brightness brightness) =>
      brightness == Brightness.dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: _cyan,
          onPrimary: Color(0xFF00222B),
          primaryContainer: Color(0xFF0B3A46),
          onPrimaryContainer: _cyan,
          secondary: _violet,
          onSecondary: Color(0xFF1B0B33),
          secondaryContainer: Color(0xFF2A1B4A),
          onSecondaryContainer: Color(0xFFD9C6FF),
          tertiary: _magenta,
          onTertiary: Color(0xFF3A0620),
          tertiaryContainer: Color(0xFF4A1030),
          onTertiaryContainer: Color(0xFFFFC2DC),
          error: _red,
          onError: Color(0xFF3A0410),
          errorContainer: Color(0xFF4B0C1D),
          onErrorContainer: Color(0xFFFFC7D0),
          surface: _surface,
          onSurface: _text,
          surfaceDim: _void,
          surfaceBright: _surfaceHighest,
          surfaceContainerLowest: _void,
          surfaceContainerLow: _surfaceLow,
          surfaceContainer: _surfaceLow,
          surfaceContainerHigh: _surfaceHigh,
          surfaceContainerHighest: _surfaceHighest,
          onSurfaceVariant: _textDim,
          outline: _outline,
          outlineVariant: _outlineDim,
          inverseSurface: _text,
          onInverseSurface: _void,
          inversePrimary: Color(0xFF00566B),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: _lightCyan,
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFD3F1F9),
          onPrimaryContainer: Color(0xFF00323F),
          secondary: _lightViolet,
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFE7DEFF),
          onSecondaryContainer: Color(0xFF23104F),
          tertiary: _lightMagenta,
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFFFD9E5),
          onTertiaryContainer: Color(0xFF3E0021),
          error: Color(0xFFB3261E),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFF9DEDC),
          onErrorContainer: Color(0xFF410E0B),
          surface: _lightSurface,
          onSurface: _lightText,
          surfaceDim: Color(0xFFE2E8F0),
          surfaceBright: Color(0xFFFFFFFF),
          surfaceContainerLowest: Color(0xFFFFFFFF),
          surfaceContainerLow: Color(0xFFF7FAFD),
          surfaceContainer: _lightCanvas,
          surfaceContainerHigh: Color(0xFFEAF0F7),
          surfaceContainerHighest: Color(0xFFE2EAF3),
          onSurfaceVariant: _lightTextDim,
          outline: _lightOutline,
          outlineVariant: Color(0xFFE1E8F1),
          inverseSurface: Color(0xFF101725),
          onInverseSurface: Color(0xFFF4F7FB),
          inversePrimary: Color(0xFF6EDCF5),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
        );

  static NeonAccents _accents(Brightness brightness) =>
      brightness == Brightness.dark
      ? const NeonAccents(
          online: _green,
          busy: _amber,
          offline: _red,
          grid: Color(0xFF101A28),
          panelBorder: _outline,
          panelTop: Color(0xFF121A28),
          panelBottom: Color(0xFF0B111B),
          glowStrength: 1,
          surface: _surface,
          // Nothing for a shadow to fall on, and nothing it could darken.
          shadow: Color(0x00000000),
        )
      : const NeonAccents(
          online: Color(0xFF0E7A47),
          busy: Color(0xFF8A6100),
          offline: Color(0xFFB3261E),
          grid: Color(0xFFDCE4EE),
          panelBorder: _lightOutline,
          panelTop: Color(0xFFFFFFFF),
          panelBottom: Color(0xFFFAFCFE),
          glowStrength: 0,
          surface: _lightSurface,
          // A cool shadow rather than a black one: on a blue-grey ground a
          // neutral drop shadow reads as dirt.
          shadow: Color(0xFF16324F),
        );

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);
    final accents = _accents(brightness);
    final canvasColor = brightness == Brightness.dark ? _void : _lightCanvas;

    return ThemeData(
      colorScheme: scheme,
      extensions: [accents],
      scaffoldBackgroundColor: canvasColor,
      canvasColor: canvasColor,
      splashFactory: InkSparkle.splashFactory,

      // Chrome is set in the terminal's own typeface. It is the strongest,
      // cheapest signal of what this app is: every label reads as something
      // typed rather than something designed, and it costs no extra asset
      // because the font is already bundled for the grid.
      textTheme: _textTheme(scheme),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _mono(
          size: 15,
          weight: FontWeight.w600,
          color: scheme.onSurface,
          spacing: 0.4,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => _mono(
            size: 11,
            weight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            spacing: 0.3,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: _mono(
          size: 12,
          weight: FontWeight.w600,
          color: scheme.primary,
          spacing: 0.3,
        ),
        unselectedLabelTextStyle: _mono(
          size: 12,
          color: scheme.onSurfaceVariant,
          spacing: 0.3,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: accents.grid,
        space: 1,
        thickness: 1,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.borderMd,
          side: BorderSide(color: accents.panelBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: _mono(
          size: 14,
          weight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: _mono(size: 12, color: scheme.onSurfaceVariant),
        iconColor: scheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(borderRadius: Radii.borderSm),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: Radii.borderSm),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          textStyle: _mono(size: 13, weight: FontWeight.w600, spacing: 0.4),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: Radii.borderSm),
          side: BorderSide(color: accents.panelBorder),
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          textStyle: _mono(size: 13, weight: FontWeight.w500, spacing: 0.4),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: _mono(size: 13, weight: FontWeight.w500, spacing: 0.4),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.borderMd),
      ),

      // Material picks the secondary container for a selected segment, which
      // here is violet and reads as a different app's control next to
      // everything else. Selection is the accent, as it is everywhere else.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            _mono(size: 12, weight: FontWeight.w600, spacing: 0.4),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: accents.panelBorder)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.borderSm),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: accents.panelBorder),
        shape: const RoundedRectangleBorder(borderRadius: Radii.borderXs),
        labelStyle: _mono(
          size: 11,
          weight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
          spacing: 0.4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: Radii.borderSm,
          borderSide: BorderSide(color: accents.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.borderSm,
          borderSide: BorderSide(color: accents.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.borderSm,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        labelStyle: _mono(size: 13, color: scheme.onSurfaceVariant),
        hintStyle: _mono(size: 13, color: scheme.onSurfaceVariant),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.borderLg,
          side: BorderSide(color: accents.panelBorder),
        ),
        titleTextStyle: _mono(
          size: 16,
          weight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.borderSm,
          side: BorderSide(color: accents.panelBorder),
        ),
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: _mono(size: 13, color: scheme.onSurface),
        elevation: 0,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: Radii.borderXs,
          border: Border.all(color: accents.panelBorder),
        ),
        textStyle: _mono(size: 11, color: scheme.onSurface),
        waitDuration: const Duration(milliseconds: 400),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 2,
        linearTrackColor: scheme.surfaceContainerHigh,
      ),

      visualDensity: VisualDensity.standard,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle title(double size, FontWeight weight) =>
        _mono(size: size, weight: weight, color: scheme.onSurface);

    return TextTheme(
      displaySmall: title(30, FontWeight.w300),
      headlineMedium: title(24, FontWeight.w400),
      headlineSmall: title(20, FontWeight.w500),
      titleLarge: title(18, FontWeight.w600),
      titleMedium: title(15, FontWeight.w600),
      titleSmall: title(13, FontWeight.w600),
      // Prose stays in the platform's own face. A paragraph of explanation set
      // in a monospace is harder to read, and there is no style point worth
      // that — the mono is for labels, values and anything the user could
      // imagine typing.
      bodyLarge: TextStyle(fontSize: 15, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 13.5, color: scheme.onSurface),
      bodySmall: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      labelLarge: _mono(
        size: 13,
        weight: FontWeight.w600,
        color: scheme.onSurface,
        spacing: 0.4,
      ),
      labelMedium: _mono(
        size: 11,
        weight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
        spacing: 0.6,
      ),
      labelSmall: _mono(
        size: 10,
        weight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
        spacing: 0.8,
      ),
    );
  }

  static TextStyle _mono({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: Fonts.mono,
    fontFamilyFallback: Fonts.monoFallback,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
  );
}
