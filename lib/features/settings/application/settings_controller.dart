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

  /// Chooses the terminal font family, or null for the bundled one.
  ///
  /// Trimmed, and an empty choice means "back to the bundled font" rather than
  /// a family called "".
  Future<void> setFontFamily(String? family) => _update((s) {
    final trimmed = family?.trim();
    return s.copyWith(
      fontFamily: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  });

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

  /// Sets the relay used by the web build.
  Future<void> setRelayUrl(String? url) => _update(
    (s) => s.copyWith(relayUrl: (url?.trim().isEmpty ?? true) ? null : url),
  );

  /// Records that the first-run introduction has been seen.
  Future<void> completeOnboarding() =>
      _update((s) => s.copyWith(onboardingComplete: true));

  /// Replaces every preference at once.
  ///
  /// Used by a restore, which has a whole settings object rather than a
  /// sequence of individual changes.
  Future<void> replaceAll(TerminalSettings settings) =>
      _update((_) => settings);

  /// Returns every preference to its default.
  ///
  /// Except the record that the introduction has been seen. That is not a
  /// preference — it is a fact about this installation — and resetting it threw
  /// the user back into the first-run screens for asking to restore a default
  /// font size.
  Future<void> reset() => _update(
    (s) => TerminalSettings(onboardingComplete: s.onboardingComplete),
  );
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
