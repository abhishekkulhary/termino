import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/shared/design/terminal_palette.dart';

part 'settings_controller.g.dart';

/// The user's settings.
///
/// Synchronous, with an explicit [load]. An async notifier looked like the
/// natural fit and was not: its `build` re-ran while writes were in flight and
/// raced the state assignments after them, so every other change was silently
/// discarded. Starting from the defaults and loading into them has no such
/// window, and costs one frame of default appearance at startup.
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  /// Updates run one at a time, chained onto this, so two changes in quick
  /// succession — which a slider makes on every frame — cannot lose one
  /// another.
  Future<void> _pending = Future.value();

  @override
  TerminalSettings build() => const TerminalSettings();

  /// Loads the stored settings. Called once at startup.
  Future<void> load() async {
    state = await ref.read(settingsStoreProvider).read();
  }

  Future<void> _update(TerminalSettings Function(TerminalSettings) change) =>
      _pending = _pending.then((_) async {
        final next = change(state);
        state = next;
        await ref.read(settingsStoreProvider).write(next);
      });

  /// Chooses a terminal palette, or null to follow the app theme.
  Future<void> setPalette(String? id) =>
      _update((s) => s.copyWith(paletteId: id));

  /// Chooses light, dark or system.
  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  /// Sets the terminal font size, clamped to a usable range.
  Future<void> setFontSize(double size) => _update(
    (s) => s.copyWith(
      fontSize: size.clamp(
        TerminalSettings.minFontSize,
        TerminalSettings.maxFontSize,
      ),
    ),
  );

  /// Sets the line height as a multiple of the font size.
  Future<void> setLineHeight(double height) =>
      _update((s) => s.copyWith(lineHeight: height.clamp(1.0, 2.0)));

  /// Sets the cursor shape.
  Future<void> setCursorShape(TerminalCursorShape shape) =>
      _update((s) => s.copyWith(cursorShape: shape));

  /// Turns cursor blinking on or off.
  Future<void> setCursorBlinks({required bool blinks}) =>
      _update((s) => s.copyWith(cursorBlinks: blinks));

  /// Chooses what the bell does.
  Future<void> setBell(BellBehaviour bell) =>
      _update((s) => s.copyWith(bell: bell));

  /// Sets how many lines of scrollback to keep.
  Future<void> setScrollback(int lines) =>
      _update((s) => s.copyWith(scrollbackLines: lines));

  /// Returns everything to its default.
  Future<void> reset() => _update((_) => const TerminalSettings());
}

/// The settings as a plain value.
@Riverpod(keepAlive: true)
TerminalSettings currentSettings(Ref ref) => ref.watch(settingsProvider);

/// The palette to paint terminals with, honouring the user's choice and
/// falling back to one that matches the app theme.
@riverpod
TerminalPalette activePalette(Ref ref, Brightness brightness) {
  final chosen = ref.watch(currentSettingsProvider).paletteId;
  return (chosen == null ? null : TerminalPalettes.byId(chosen)) ??
      TerminalPalettes.forBrightness(brightness);
}
