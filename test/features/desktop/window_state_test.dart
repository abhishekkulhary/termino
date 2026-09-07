import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/desktop/presentation/app_shortcuts.dart';
import 'package:termino/infrastructure/storage/window_state_store.dart';

/// A window remembered on a monitor that is no longer attached opens where
/// nobody can reach it, and on most platforms there is then no way to drag it
/// back. That is the failure worth testing here.
void main() {
  const onScreen = Rect.fromLTWH(0, 0, 2560, 1440);

  group('restoring where the window was', () {
    test('keeps bounds that are on a display', () {
      const state = WindowState(bounds: Rect.fromLTWH(100, 80, 1100, 720));
      expect(state.boundsWithin(onScreen), state.bounds);
    });

    test('refuses bounds on a display that is gone', () {
      // A second monitor that used to sit to the right.
      const state = WindowState(bounds: Rect.fromLTWH(3200, 200, 1100, 720));
      expect(state.boundsWithin(onScreen), isNull);
    });

    test('refuses a window that is only just peeking in', () {
      // Twenty pixels of title bar is not something anyone can grab.
      const state = WindowState(bounds: Rect.fromLTWH(2540, 100, 1100, 720));
      expect(state.boundsWithin(onScreen), isNull);
    });

    test('keeps a window that overlaps enough to grab', () {
      const state = WindowState(bounds: Rect.fromLTWH(2200, 100, 1100, 720));
      expect(state.boundsWithin(onScreen), isNotNull);
    });
  });

  group('storing it', () {
    test('round-trips through JSON', () {
      const state = WindowState(
        bounds: Rect.fromLTWH(10, 20, 1200, 800),
        maximized: true,
      );

      final restored = WindowState.decode(state.encode())!;

      expect(restored.bounds, state.bounds);
      expect(restored.maximized, isTrue);
    });

    test('damaged or missing state yields nothing, not an error', () {
      // The app opening at its default size is a far better outcome than the
      // app not opening.
      expect(WindowState.decode(null), isNull);
      expect(WindowState.decode('not json'), isNull);
      expect(WindowState.decode('{"x":1}'), isNull);
    });
  });

  group('keyboard shortcuts', () {
    test('use Command on macOS, where nothing else claims it', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(AppShortcuts.newSession.meta, isTrue);
      expect(AppShortcuts.newSession.control, isFalse);
      expect(AppShortcuts.label('K'), '⌘K');
    });

    test('use Ctrl+Shift elsewhere, because the terminal owns Ctrl', () {
      // Ctrl+W deletes a word, Ctrl+T transposes, Ctrl+K kills to end of line.
      // Taking any of those would break the thing this app exists to be, which
      // is why every terminal emulator on Linux and Windows uses Ctrl+Shift.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      for (final shortcut in [
        AppShortcuts.newSession,
        AppShortcuts.closeSession,
        AppShortcuts.find,
        AppShortcuts.split,
        AppShortcuts.palette,
      ]) {
        expect(shortcut.control, isTrue);
        expect(
          shortcut.shift,
          isTrue,
          reason: 'a bare Ctrl combination belongs to the shell',
        );
      }
      expect(AppShortcuts.label('K'), 'Ctrl+Shift+K');
    });

    test('the palette follows the same rule as everything else', () {
      // It did not: it was a bare Ctrl+K, which is readline's kill-line.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(AppShortcuts.palette.trigger, LogicalKeyboardKey.keyK);
      expect(AppShortcuts.palette.shift, isTrue);
    });
  });
}
