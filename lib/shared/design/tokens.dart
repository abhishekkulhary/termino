import 'package:flutter/widgets.dart';

/// Spacing scale, in logical pixels.
///
/// Feature widgets use these rather than raw numbers so that density can be
/// tuned in one place. The scale is a 4-point grid; anything off it is a bug,
/// not a nuance.
abstract final class Spacing {
  /// 2 — hairline separation, e.g. between a label and its value.
  static const xxs = 2.0;

  /// 4 — tight grouping inside a control.
  static const xs = 4.0;

  /// 8 — the default gap between related elements.
  static const sm = 8.0;

  /// 12 — padding inside compact containers.
  static const md = 12.0;

  /// 16 — standard screen and card padding.
  static const lg = 16.0;

  /// 24 — separation between sections.
  static const xl = 24.0;

  /// 32 — page-level breathing room.
  static const xxl = 32.0;
}

/// Corner radii.
abstract final class Radii {
  /// 4 — chips, small badges.
  static const xs = Radius.circular(4);

  /// 8 — buttons, inputs.
  static const sm = Radius.circular(8);

  /// 12 — cards, panes.
  static const md = Radius.circular(12);

  /// 20 — dialogs and sheets.
  static const lg = Radius.circular(20);

  /// Rounded rectangle at [xs].
  static const borderXs = BorderRadius.all(xs);

  /// Rounded rectangle at [sm].
  static const borderSm = BorderRadius.all(sm);

  /// Rounded rectangle at [md].
  static const borderMd = BorderRadius.all(md);

  /// Rounded rectangle at [lg].
  static const borderLg = BorderRadius.all(lg);
}

/// Animation durations.
///
/// Kept short deliberately: this is a tool people use all day, and the terminal
/// itself must never feel like it is waiting for an animation.
abstract final class Motion {
  /// 90ms — state changes on a control the user just touched.
  static const fast = Duration(milliseconds: 90);

  /// 160ms — the default for layout and navigation transitions.
  static const normal = Duration(milliseconds: 160);

  /// 240ms — sheets and dialogs.
  static const slow = Duration(milliseconds: 240);
}

/// Font families bundled with the app.
abstract final class Fonts {
  /// The terminal typeface: JetBrains Mono, patched with Nerd Font glyphs.
  ///
  /// Bundled rather than taken from the system because terminal output is full
  /// of box drawing, block elements and Powerline separators, and a system
  /// monospace font that lacks them renders tofu in the middle of `htop`.
  static const mono = 'JetBrainsMono';

  /// Fallbacks for glyphs even the Nerd Font lacks, notably CJK and emoji.
  static const monoFallback = <String>[
    'Menlo',
    'Consolas',
    'DejaVu Sans Mono',
    'Noto Color Emoji',
    'monospace',
  ];
}

/// Terminal grid defaults. These are user-configurable in settings; the values
/// here are only the starting point.
abstract final class TerminalDefaults {
  /// Starting font size in logical pixels. Slightly larger than xterm's own
  /// default of 13, which is cramped on a modern display.
  static const fontSize = 14.0;

  /// Line height as a multiple of the font size. 1.2 keeps box-drawing
  /// characters connected while staying readable.
  static const lineHeight = 1.2;

  /// How many lines of scrollback to keep by default.
  static const scrollbackLines = 10000;
}
