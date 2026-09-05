import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/shared/design/tokens.dart';

part 'terminal_settings.g.dart';

/// User-adjustable terminal appearance.
///
/// Font size lives here rather than in a widget because pinch-to-zoom on one
/// pane should change every pane: a terminal that is readable in one tab and
/// not another is a bug, not a feature. The full settings screen in Phase 6
/// persists these; for now they last as long as the app run.
@Riverpod(keepAlive: true)
class TerminalFontSize extends _$TerminalFontSize {
  /// The smallest legible size. Below this, box drawing stops joining up.
  static const minimum = 8.0;

  /// The largest useful size before a terminal holds too few columns.
  static const maximum = 32.0;

  @override
  double build() => TerminalDefaults.fontSize;

  /// Sets the size, clamped to a usable range.
  void set(double size) => state = size.clamp(minimum, maximum);

  /// Multiplies the size, for pinch gestures.
  void scale(double factor) => set(state * factor);

  /// Steps up by one point, for a keyboard shortcut.
  void increase() => set(state + 1);

  /// Steps down by one point.
  void decrease() => set(state - 1);

  /// Returns to the default.
  void reset() => state = TerminalDefaults.fontSize;
}
