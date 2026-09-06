import 'package:freezed_annotation/freezed_annotation.dart';

part 'terminal_settings.freezed.dart';
part 'terminal_settings.g.dart';

/// What the cursor looks like.
enum TerminalCursorShape {
  /// A filled block, as most terminals default to.
  block,

  /// A vertical bar, as most editors use.
  bar,

  /// An underline.
  underline;

  /// A label for the settings screen.
  String get label => switch (this) {
    TerminalCursorShape.block => 'Block',
    TerminalCursorShape.bar => 'Bar',
    TerminalCursorShape.underline => 'Underline',
  };
}

/// What happens when a program rings the bell.
enum BellBehaviour {
  /// Nothing at all.
  none,

  /// A brief flash of the terminal.
  visual,

  /// A short vibration, where the device has one.
  haptic;

  /// A label for the settings screen.
  String get label => switch (this) {
    BellBehaviour.none => 'Ignore',
    BellBehaviour.visual => 'Flash the screen',
    BellBehaviour.haptic => 'Vibrate',
  };
}

/// Which theme the app follows.
enum AppThemeMode {
  /// Follow the platform.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark;

  /// A label for the settings screen.
  String get label => switch (this) {
    AppThemeMode.system => 'System',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };
}

/// Everything the user can adjust about how a terminal looks and behaves.
@freezed
abstract class TerminalSettings with _$TerminalSettings {
  /// Creates a settings snapshot.
  const factory({
    /// The palette id, or null to follow the app theme.
    String? paletteId,
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(14) double fontSize,
    @Default(1.2) double lineHeight,
    @Default(TerminalCursorShape.block) TerminalCursorShape cursorShape,
    @Default(true) bool cursorBlinks,
    @Default(BellBehaviour.visual) BellBehaviour bell,
    @Default(10000) int scrollbackLines,

    /// Where the web build's SSH relay lives, e.g. `wss://relay.example.com/ssh`.
    ///
    /// Only meaningful on the web, where a browser cannot open a raw TCP
    /// socket. Everywhere else SSH connects directly and this is ignored.
    String? relayUrl,
  }) = _TerminalSettings;

  const new _();

  /// Restores settings from stored JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$TerminalSettingsFromJson(json);

  /// The smallest legible font size; below this box drawing stops joining up.
  static const minFontSize = 8.0;

  /// The largest useful size before a terminal holds too few columns.
  static const maxFontSize = 32.0;

  /// The scrollback sizes offered. Unbounded is not one of them: a terminal
  /// that keeps everything eventually keeps the user's memory too.
  static const scrollbackOptions = [1000, 5000, 10000, 50000];
}
