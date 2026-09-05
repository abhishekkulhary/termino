import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

var _loaded = false;

/// Loads the real fonts so that golden tests are worth looking at.
///
/// By default `flutter test` substitutes a placeholder that renders every glyph
/// as an identical box. For a terminal emulator that makes goldens actively
/// misleading: boxes are exactly what a *missing* glyph looks like, so a golden
/// full of them proves nothing about box drawing, Powerline separators or the
/// bundled typeface. With the real fonts loaded, a golden that shows connected
/// box drawing is evidence the font and palette work.
///
/// Three families are loaded:
///
/// * **JetBrainsMono** — the bundled terminal font, from `assets/fonts/`.
/// * **Roboto** and **MaterialIcons** — the UI font and icon set, taken from
///   the Flutter SDK's own artifact cache via `FLUTTER_ROOT`, which the tool
///   sets for every `flutter test` run, on CI as well as locally.
///
/// Missing fonts are a hard failure rather than a silent fallback: goldens
/// generated with placeholder glyphs would be committed and then never match
/// anywhere else.
Future<void> loadTerminalFont() async {
  if (_loaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  await _load('JetBrainsMono', const [
    'assets/fonts/JetBrainsMonoNerdFontMono-Regular.ttf',
    'assets/fonts/JetBrainsMonoNerdFontMono-Bold.ttf',
    'assets/fonts/JetBrainsMonoNerdFontMono-Italic.ttf',
    'assets/fonts/JetBrainsMonoNerdFontMono-BoldItalic.ttf',
  ]);

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError(
      'FLUTTER_ROOT is not set, so the UI fonts cannot be loaded and any '
      'golden generated now would be wrong. Run these tests with '
      '`flutter test`.',
    );
  }
  final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  await _load('Roboto', [
    '$fonts/Roboto-Regular.ttf',
    '$fonts/Roboto-Medium.ttf',
    '$fonts/Roboto-Bold.ttf',
    '$fonts/Roboto-Italic.ttf',
  ]);
  await _load('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);

  _loaded = true;
}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Missing font for golden tests: $path');
    }
    loader.addFont(file.readAsBytes().then(ByteData.sublistView));
  }
  await loader.load();
}
