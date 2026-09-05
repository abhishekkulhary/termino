import 'package:flutter/foundation.dart';
import 'package:termino/features/terminal/application/sticky_modifiers.dart';
import 'package:xterm/xterm.dart';

/// One button on the key accessory bar.
///
/// A button either toggles a sticky modifier, sends a named key, or types
/// literal text. Modelling it as data rather than as widgets is what makes the
/// extra row customisable and the bar testable.
@immutable
sealed class KeyBarAction {
  const new({required this.label, this.tooltip});

  /// What the button shows.
  final String label;

  /// A longer description, for hover and for screen readers.
  final String? tooltip;
}

/// A button that toggles Ctrl, Alt or Shift.
final class ModifierAction extends KeyBarAction {
  /// Creates a modifier button.
  const new({required this.modifier, required super.label, super.tooltip});

  /// Which modifier this button toggles.
  final StickyModifier modifier;
}

/// A button that sends a named key, such as Escape or an arrow.
final class NamedKeyAction extends KeyBarAction {
  /// Creates a named-key button.
  const new({required this.key, required super.label, super.tooltip});

  /// The key to send.
  final TerminalKey key;
}

/// A button that types literal text.
final class TextAction extends KeyBarAction {
  /// Creates a button that types [text].
  const new({required this.text, required super.label, super.tooltip});

  /// What to type.
  final String text;
}

/// The rows the accessory bar shows.
abstract final class KeyBarLayout {
  /// The always-present row: the keys a touch keyboard has no room for.
  ///
  /// Chosen from what a shell session actually needs — interrupting a command,
  /// completing a path, editing a pipeline, and moving through history —
  /// rather than from what a full keyboard happens to have.
  static const primary = <KeyBarAction>[
    NamedKeyAction(key: TerminalKey.escape, label: 'Esc', tooltip: 'Escape'),
    NamedKeyAction(key: TerminalKey.tab, label: 'Tab', tooltip: 'Tab'),
    NamedKeyAction(
      key: TerminalKey.arrowUp,
      label: '↑',
      tooltip: 'Up — previous command',
    ),
    NamedKeyAction(key: TerminalKey.arrowDown, label: '↓', tooltip: 'Down'),
    NamedKeyAction(key: TerminalKey.arrowLeft, label: '←', tooltip: 'Left'),
    NamedKeyAction(key: TerminalKey.arrowRight, label: '→', tooltip: 'Right'),
    TextAction(text: '|', label: '|', tooltip: 'Pipe'),
    TextAction(text: '-', label: '-', tooltip: 'Dash'),
    TextAction(text: '~', label: '~', tooltip: 'Home directory'),
    TextAction(text: '/', label: '/', tooltip: 'Slash'),
  ];

  /// The function keys, shown when the user expands the bar.
  static const functionKeys = <KeyBarAction>[
    NamedKeyAction(key: TerminalKey.f1, label: 'F1'),
    NamedKeyAction(key: TerminalKey.f2, label: 'F2'),
    NamedKeyAction(key: TerminalKey.f3, label: 'F3'),
    NamedKeyAction(key: TerminalKey.f4, label: 'F4'),
    NamedKeyAction(key: TerminalKey.f5, label: 'F5'),
    NamedKeyAction(key: TerminalKey.f6, label: 'F6'),
    NamedKeyAction(key: TerminalKey.f7, label: 'F7'),
    NamedKeyAction(key: TerminalKey.f8, label: 'F8'),
    NamedKeyAction(key: TerminalKey.f9, label: 'F9'),
    NamedKeyAction(key: TerminalKey.f10, label: 'F10'),
    NamedKeyAction(key: TerminalKey.f11, label: 'F11'),
    NamedKeyAction(key: TerminalKey.f12, label: 'F12'),
  ];

  /// Navigation and editing keys, shown alongside the function keys.
  static const navigation = <KeyBarAction>[
    NamedKeyAction(key: TerminalKey.home, label: 'Home'),
    NamedKeyAction(key: TerminalKey.end, label: 'End'),
    NamedKeyAction(key: TerminalKey.pageUp, label: 'PgUp'),
    NamedKeyAction(key: TerminalKey.pageDown, label: 'PgDn'),
    NamedKeyAction(key: TerminalKey.insert, label: 'Ins'),
    NamedKeyAction(key: TerminalKey.delete, label: 'Del'),
  ];
}
