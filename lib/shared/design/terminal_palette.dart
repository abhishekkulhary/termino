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

  /// Dracula — the most widely ported terminal palette there is.
  static const dracula = TerminalPalette(
    id: 'dracula',
    name: 'Dracula',
    brightness: Brightness.dark,
    theme: TerminalTheme(
      cursor: Color(0xFFF8F8F2),
      selection: Color(0x8044475A),
      foreground: Color(0xFFF8F8F2),
      background: Color(0xFF282A36),
      black: Color(0xFF21222C),
      red: Color(0xFFFF5555),
      green: Color(0xFF50FA7B),
      yellow: Color(0xFFF1FA8C),
      blue: Color(0xFFBD93F9),
      magenta: Color(0xFFFF79C6),
      cyan: Color(0xFF8BE9FD),
      white: Color(0xFFF8F8F2),
      brightBlack: Color(0xFF6272A4),
      brightRed: Color(0xFFFF6E6E),
      brightGreen: Color(0xFF69FF94),
      brightYellow: Color(0xFFFFFFA5),
      brightBlue: Color(0xFFD6ACFF),
      brightMagenta: Color(0xFFFF92DF),
      brightCyan: Color(0xFFA4FFFF),
      brightWhite: Color(0xFFFFFFFF),
      searchHitBackground: Color(0xFF44475A),
      searchHitBackgroundCurrent: Color(0xFFF1FA8C),
      searchHitForeground: Color(0xFF282A36),
    ),
  );

  /// Solarized Dark — designed around fixed lightness relationships, which is
  /// why its greys look flat next to other palettes and read well for hours.
  static const solarizedDark = TerminalPalette(
    id: 'solarized-dark',
    name: 'Solarized Dark',
    brightness: Brightness.dark,
    theme: TerminalTheme(
      cursor: Color(0xFF93A1A1),
      selection: Color(0x80073642),
      foreground: Color(0xFF839496),
      background: Color(0xFF002B36),
      black: Color(0xFF073642),
      red: Color(0xFFDC322F),
      green: Color(0xFF859900),
      yellow: Color(0xFFB58900),
      blue: Color(0xFF268BD2),
      magenta: Color(0xFFD33682),
      cyan: Color(0xFF2AA198),
      white: Color(0xFFEEE8D5),
      brightBlack: Color(0xFF586E75),
      brightRed: Color(0xFFCB4B16),
      brightGreen: Color(0xFF586E75),
      brightYellow: Color(0xFF657B83),
      brightBlue: Color(0xFF839496),
      brightMagenta: Color(0xFF6C71C4),
      brightCyan: Color(0xFF93A1A1),
      brightWhite: Color(0xFFFDF6E3),
      searchHitBackground: Color(0xFF073642),
      searchHitBackgroundCurrent: Color(0xFFB58900),
      searchHitForeground: Color(0xFF002B36),
    ),
  );

  /// Solarized Light — the same relationships inverted.
  static const solarizedLight = TerminalPalette(
    id: 'solarized-light',
    name: 'Solarized Light',
    brightness: Brightness.light,
    theme: TerminalTheme(
      cursor: Color(0xFF586E75),
      selection: Color(0x80EEE8D5),
      foreground: Color(0xFF657B83),
      background: Color(0xFFFDF6E3),
      black: Color(0xFF073642),
      red: Color(0xFFDC322F),
      green: Color(0xFF859900),
      yellow: Color(0xFFB58900),
      blue: Color(0xFF268BD2),
      magenta: Color(0xFFD33682),
      cyan: Color(0xFF2AA198),
      white: Color(0xFFEEE8D5),
      brightBlack: Color(0xFF002B36),
      brightRed: Color(0xFFCB4B16),
      brightGreen: Color(0xFF586E75),
      brightYellow: Color(0xFF657B83),
      brightBlue: Color(0xFF839496),
      brightMagenta: Color(0xFF6C71C4),
      brightCyan: Color(0xFF93A1A1),
      brightWhite: Color(0xFFFDF6E3),
      searchHitBackground: Color(0xFFEEE8D5),
      searchHitBackgroundCurrent: Color(0xFFB58900),
      searchHitForeground: Color(0xFFFDF6E3),
    ),
  );

  /// Nord — cool, low contrast, easy on a bright room.
  static const nord = TerminalPalette(
    id: 'nord',
    name: 'Nord',
    brightness: Brightness.dark,
    theme: TerminalTheme(
      cursor: Color(0xFFD8DEE9),
      selection: Color(0x80434C5E),
      foreground: Color(0xFFD8DEE9),
      background: Color(0xFF2E3440),
      black: Color(0xFF3B4252),
      red: Color(0xFFBF616A),
      green: Color(0xFFA3BE8C),
      yellow: Color(0xFFEBCB8B),
      blue: Color(0xFF81A1C1),
      magenta: Color(0xFFB48EAD),
      cyan: Color(0xFF88C0D0),
      white: Color(0xFFE5E9F0),
      brightBlack: Color(0xFF4C566A),
      brightRed: Color(0xFFBF616A),
      brightGreen: Color(0xFFA3BE8C),
      brightYellow: Color(0xFFEBCB8B),
      brightBlue: Color(0xFF81A1C1),
      brightMagenta: Color(0xFFB48EAD),
      brightCyan: Color(0xFF8FBCBB),
      brightWhite: Color(0xFFECEFF4),
      searchHitBackground: Color(0xFF434C5E),
      searchHitBackgroundCurrent: Color(0xFFEBCB8B),
      searchHitForeground: Color(0xFF2E3440),
    ),
  );

  /// Gruvbox Dark — warm and high contrast.
  static const gruvboxDark = TerminalPalette(
    id: 'gruvbox-dark',
    name: 'Gruvbox Dark',
    brightness: Brightness.dark,
    theme: TerminalTheme(
      cursor: Color(0xFFEBDBB2),
      selection: Color(0x80504945),
      foreground: Color(0xFFEBDBB2),
      background: Color(0xFF282828),
      black: Color(0xFF282828),
      red: Color(0xFFCC241D),
      green: Color(0xFF98971A),
      yellow: Color(0xFFD79921),
      blue: Color(0xFF458588),
      magenta: Color(0xFFB16286),
      cyan: Color(0xFF689D6A),
      white: Color(0xFFA89984),
      brightBlack: Color(0xFF928374),
      brightRed: Color(0xFFFB4934),
      brightGreen: Color(0xFFB8BB26),
      brightYellow: Color(0xFFFABD2F),
      brightBlue: Color(0xFF83A598),
      brightMagenta: Color(0xFFD3869B),
      brightCyan: Color(0xFF8EC07C),
      brightWhite: Color(0xFFEBDBB2),
      searchHitBackground: Color(0xFF504945),
      searchHitBackgroundCurrent: Color(0xFFFABD2F),
      searchHitForeground: Color(0xFF282828),
    ),
  );

  /// One Dark — the Atom palette, familiar from many editors.
  static const oneDark = TerminalPalette(
    id: 'one-dark',
    name: 'One Dark',
    brightness: Brightness.dark,
    theme: TerminalTheme(
      cursor: Color(0xFF528BFF),
      selection: Color(0x803E4451),
      foreground: Color(0xFFABB2BF),
      background: Color(0xFF282C34),
      black: Color(0xFF282C34),
      red: Color(0xFFE06C75),
      green: Color(0xFF98C379),
      yellow: Color(0xFFE5C07B),
      blue: Color(0xFF61AFEF),
      magenta: Color(0xFFC678DD),
      cyan: Color(0xFF56B6C2),
      white: Color(0xFFABB2BF),
      brightBlack: Color(0xFF5C6370),
      brightRed: Color(0xFFE06C75),
      brightGreen: Color(0xFF98C379),
      brightYellow: Color(0xFFE5C07B),
      brightBlue: Color(0xFF61AFEF),
      brightMagenta: Color(0xFFC678DD),
      brightCyan: Color(0xFF56B6C2),
      brightWhite: Color(0xFFFFFFFF),
      searchHitBackground: Color(0xFF3E4451),
      searchHitBackgroundCurrent: Color(0xFFE5C07B),
      searchHitForeground: Color(0xFF282C34),
    ),
  );

  /// Every palette available, in display order.
  static const all = <TerminalPalette>[
    dark,
    light,
    dracula,
    solarizedDark,
    solarizedLight,
    nord,
    gruvboxDark,
    oneDark,
  ];

  /// The palette with [id], or null.
  static TerminalPalette? byId(String id) {
    for (final palette in all) {
      if (palette.id == id) return palette;
    }
    return null;
  }

  /// The default palette matching [brightness], used when the user has not
  /// chosen one.
  static TerminalPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
