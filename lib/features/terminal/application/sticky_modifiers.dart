import 'package:flutter/foundation.dart';

/// How a modifier key on the accessory bar is currently behaving.
enum ModifierState {
  /// Not applied to anything.
  off,

  /// Applied to the next key press only, then released.
  armed,

  /// Applied to every key press until switched off.
  locked;

  /// Whether the modifier should be applied to a key press right now.
  bool get isActive => this != ModifierState.off;
}

/// The modifiers a phone keyboard has no keys for.
enum StickyModifier {
  /// Control.
  ctrl,

  /// Alt, sent as Meta/Escape-prefix by the terminal.
  alt,

  /// Shift.
  shift;

  /// The label shown on the accessory bar.
  String get label => switch (this) {
    StickyModifier.ctrl => 'Ctrl',
    StickyModifier.alt => 'Alt',
    StickyModifier.shift => 'Shift',
  };
}

/// Sticky modifier behaviour for a touch keyboard.
///
/// A phone keyboard has no Ctrl key, so `Ctrl+C` has to be two taps: arm the
/// modifier, then press the key. Tapping again locks it, which is what makes a
/// run of `Ctrl+` presses bearable; tapping a third time clears it. This is the
/// same three-state behaviour as a platform accessibility keyboard, and it is
/// what users of other terminal apps already expect.
///
/// Kept apart from the widget so the state machine can be tested on its own —
/// it is small, but it is the difference between the bar feeling right and
/// feeling broken.
class StickyModifiers extends ChangeNotifier {
  final Map<StickyModifier, ModifierState> _states = {
    for (final modifier in StickyModifier.values) modifier: ModifierState.off,
  };

  /// The current state of [modifier].
  ModifierState stateOf(StickyModifier modifier) =>
      _states[modifier] ?? ModifierState.off;

  /// Whether [modifier] would apply to a key press now.
  bool isActive(StickyModifier modifier) => stateOf(modifier).isActive;

  /// Whether any modifier is currently applied.
  bool get anyActive => StickyModifier.values.any(isActive);

  /// Advances [modifier] one step: off → armed → locked → off.
  void tap(StickyModifier modifier) {
    _states[modifier] = switch (stateOf(modifier)) {
      ModifierState.off => ModifierState.armed,
      ModifierState.armed => ModifierState.locked,
      ModifierState.locked => ModifierState.off,
    };
    notifyListeners();
  }

  /// Forces [modifier] to [state].
  void set(StickyModifier modifier, ModifierState state) {
    if (stateOf(modifier) == state) return;
    _states[modifier] = state;
    notifyListeners();
  }

  /// Releases every armed modifier, leaving locked ones alone.
  ///
  /// Called after a key has been sent. Locked modifiers survive, which is the
  /// whole point of locking them.
  void consume() {
    var changed = false;
    for (final modifier in StickyModifier.values) {
      if (stateOf(modifier) == ModifierState.armed) {
        _states[modifier] = ModifierState.off;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Clears everything, including locks.
  void clear() {
    var changed = false;
    for (final modifier in StickyModifier.values) {
      if (stateOf(modifier) != ModifierState.off) {
        _states[modifier] = ModifierState.off;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
