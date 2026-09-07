import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The application's own keyboard shortcuts, and which keys they may take.
///
/// The hard constraint is that a terminal owns almost every key. `Ctrl+W`
/// deletes a word, `Ctrl+T` transposes characters, `Ctrl+D` sends EOF — those
/// belong to readline and the shell, and an app that swallows them has broken
/// the thing it exists to be.
///
/// So: on macOS the modifier is Command, which no terminal program uses, and
/// the shortcuts read as they do in every other Mac app. Everywhere else the
/// modifier is `Ctrl+Shift`, which is exactly the convention GNOME Terminal,
/// Konsole and Windows Terminal adopted for the same reason.
abstract final class AppShortcuts {
  /// Whether this platform puts app shortcuts on Command.
  static bool get usesCommand =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// A shortcut for [key] on whichever modifier this platform uses.
  static SingleActivator activator(LogicalKeyboardKey key) => usesCommand
      ? SingleActivator(key, meta: true)
      : SingleActivator(key, control: true, shift: true);

  /// How that shortcut reads to a human.
  static String label(String key) => usesCommand ? '⌘$key' : 'Ctrl+Shift+$key';

  /// Open a new session.
  static SingleActivator get newSession => activator(LogicalKeyboardKey.keyT);

  /// Close the session in front.
  static SingleActivator get closeSession => activator(LogicalKeyboardKey.keyW);

  /// Search the scrollback.
  static SingleActivator get find => activator(LogicalKeyboardKey.keyF);

  /// Show the session beside this one.
  static SingleActivator get split => activator(LogicalKeyboardKey.keyD);

  /// The command palette.
  ///
  /// On the same modifier as everything else, which is a correction: it was
  /// bound to a bare `Ctrl+K` on Linux and Windows, and that is readline's
  /// kill-to-end-of-line. Binding it swallowed a keystroke terminal users
  /// press constantly — the exact mistake the rest of this file exists to
  /// avoid. Command still works alone on macOS, where nothing claims it.
  static SingleActivator get palette => activator(LogicalKeyboardKey.keyK);
}
