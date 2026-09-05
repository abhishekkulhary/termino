import 'package:flutter/widgets.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:xterm/xterm.dart';

/// A named terminal colour scheme.
///
/// Wraps xterm's [TerminalTheme] so that feature code never constructs one
/// directly and so that a palette can carry a name and a brightness for the
/// settings UI. The full catalogue (Dracula, Solarized, Nord, Gruvbox, One
/// Dark) arrives in Phase 6; these two are the defaults.
class TerminalPalette {
  /// Creates a named palette.
  const new({
    required this.id,
    required this.name,
    required this.brightness,
    required this.theme,
  });

  /// Stable identifier, stored in settings.
  final String id;

  /// Human-readable name shown in the theme picker.
  final String name;

  /// Whether this palette is meant for a light or dark UI.
  final Brightness brightness;

  /// The colours themselves, in the form xterm renders.
  final TerminalTheme theme;

  /// The text style used to paint cells.
  ///
  /// Font size and line height are user settings (pinch-to-zoom changes the
  /// first), so they are parameters rather than constants; omitting both gives
  /// the defaults from [TerminalDefaults].
  TerminalStyle styleWith({double? fontSize, double? lineHeight}) =>
      TerminalStyle(
        fontFamily: Fonts.mono,
        fontFamilyFallback: Fonts.monoFallback,
        fontSize: fontSize ?? TerminalDefaults.fontSize,
        height: lineHeight ?? TerminalDefaults.lineHeight,
      );
}

/// The palettes shipped in Phase 1.
abstract final class TerminalPalettes {
  /// The default dark palette: high contrast, low glare, and a background that
  /// sits comfortably next to a dark Material surface.
  static const dark = TerminalPalette(
    id: 'termino-dark',
    name: 'Termino Dark',
    brightness: Brightness.dark,
    theme: TerminalTheme(
      cursor: Color(0xFF7FD6FF),
      selection: Color(0x407FD6FF),
      foreground: Color(0xFFD6DEEB),
      background: Color(0xFF11141B),
      black: Color(0xFF1C2029),
      red: Color(0xFFFF6B7F),
      green: Color(0xFF5BD98A),
      yellow: Color(0xFFF2C97D),
      blue: Color(0xFF6FA8FF),
      magenta: Color(0xFFD08BFF),
      cyan: Color(0xFF5BD6D6),
      white: Color(0xFFD6DEEB),
      brightBlack: Color(0xFF5A6478),
      brightRed: Color(0xFFFF8FA0),
      brightGreen: Color(0xFF7FE9A6),
      brightYellow: Color(0xFFFFD99B),
      brightBlue: Color(0xFF93C0FF),
      brightMagenta: Color(0xFFE0AEFF),
      brightCyan: Color(0xFF88E6E6),
      brightWhite: Color(0xFFF4F7FB),
      searchHitBackground: Color(0xFF3A4A63),
      searchHitBackgroundCurrent: Color(0xFFF2C97D),
      searchHitForeground: Color(0xFF11141B),
    ),
  );

  /// The default light palette. Terminal output must stay readable in light
  /// mode, which mostly means desaturating the brights rather than lightening
  /// them.
  static const light = TerminalPalette(
    id: 'termino-light',
    name: 'Termino Light',
    brightness: Brightness.light,
    theme: TerminalTheme(
      cursor: Color(0xFF0B6FB8),
      selection: Color(0x330B6FB8),
      foreground: Color(0xFF1F2430),
      background: Color(0xFFFBFCFE),
      black: Color(0xFF1F2430),
      red: Color(0xFFC0392F),
      green: Color(0xFF1F7A45),
      yellow: Color(0xFF9A6B00),
      blue: Color(0xFF1155CC),
      magenta: Color(0xFF8B2FB8),
      cyan: Color(0xFF00727A),
      white: Color(0xFFE4E8EF),
      brightBlack: Color(0xFF5C6675),
      brightRed: Color(0xFFD8453A),
      brightGreen: Color(0xFF268C51),
      brightYellow: Color(0xFFB07C00),
      brightBlue: Color(0xFF2166E0),
      brightMagenta: Color(0xFFA13BD1),
      brightCyan: Color(0xFF00858F),
      brightWhite: Color(0xFFFFFFFF),
      searchHitBackground: Color(0xFFCFE0F7),
      searchHitBackgroundCurrent: Color(0xFF9A6B00),
      searchHitForeground: Color(0xFFFBFCFE),
    ),
  );

  /// Every palette available, in display order.
  static const all = <TerminalPalette>[dark, light];

  /// The palette matching [brightness].
  static TerminalPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
