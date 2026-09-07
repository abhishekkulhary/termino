import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Monospace families that are usually present, by platform.
///
/// Flutter cannot enumerate installed fonts, so this is a list of suggestions
/// rather than a list of what is actually there. An unknown name falls back
/// silently — which is exactly why the settings screen shows a live preview
/// beside the choice: seeing it is the only way anyone can tell whether their
/// font took.
abstract final class MonospaceSuggestions {
  /// Families worth offering on this platform, best first.
  ///
  /// Deliberately short. A list of forty names nobody has is not a feature,
  /// and anything missing can still be typed in.
  static List<String> forPlatform({String? platform}) {
    final target = platform ?? _currentPlatform;
    return switch (target) {
      'macos' || 'ios' => const ['SF Mono', 'Menlo', 'Monaco', 'Courier New'],
      'windows' => const [
        'Cascadia Mono',
        'Consolas',
        'Lucida Console',
        'Courier New',
      ],
      'linux' => const [
        'DejaVu Sans Mono',
        'Liberation Mono',
        'Ubuntu Mono',
        'Noto Sans Mono',
      ],
      'android' => const ['Roboto Mono', 'Droid Sans Mono'],
      _ => const ['monospace', 'Courier New'],
    };
  }

  static String get _currentPlatform {
    if (kIsWeb) return 'web';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }
}
