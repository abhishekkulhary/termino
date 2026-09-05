import 'package:flutter/material.dart';
import 'package:termino/shared/design/terminal_palette.dart';
import 'package:termino/shared/design/tokens.dart';

/// Builds the app's Material 3 themes from the design tokens.
///
/// Nothing outside this file names a colour. Feature widgets read from
/// `Theme.of(context).colorScheme` and the token classes, so that a change of
/// palette is a change in one place.
abstract final class AppTheme {
  /// The seed the Material colour scheme is derived from — a cool blue that
  /// sits quietly next to terminal output rather than competing with it.
  static const seed = Color(0xFF3B7DD8);

  /// The light theme.
  static ThemeData light() => _build(Brightness.light);

  /// The dark theme.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final palette = TerminalPalettes.forBrightness(brightness);

    return ThemeData(
      colorScheme: scheme,
      // The app scaffold matches the terminal background so that a maximised
      // terminal reads as one surface rather than a panel inside a window.
      scaffoldBackgroundColor: palette.theme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: Radii.borderMd),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: Radii.borderSm),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: Radii.borderSm),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.borderSm),
        backgroundColor: scheme.inverseSurface,
      ),
      // The terminal grid has its own size setting and must not be scaled by
      // the platform text-scale factor, but UI chrome should honour it. The
      // terminal opts out locally; everything else inherits this.
      visualDensity: VisualDensity.standard,
    );
  }
}
