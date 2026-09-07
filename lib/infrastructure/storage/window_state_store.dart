import 'dart:convert';
import 'dart:ui';

import 'package:termino/infrastructure/storage/database.dart';

/// Where the window was and how big, last time.
class WindowState {
  /// Creates a window state.
  const new({required this.bounds, this.maximized = false});

  /// Reads a state from stored JSON, or null when it is missing or damaged.
  static WindowState? decode(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return WindowState(
        bounds: Rect.fromLTWH(
          (map['x'] as num).toDouble(),
          (map['y'] as num).toDouble(),
          (map['width'] as num).toDouble(),
          (map['height'] as num).toDouble(),
        ),
        maximized: map['maximized'] as bool? ?? false,
      );
    } on Object {
      // A window that opens at its default size is a far better outcome than
      // an app that will not start.
      return null;
    }
  }

  /// Where the window sat, in logical pixels.
  final Rect bounds;

  /// Whether it was maximised, in which case [bounds] is where it would go on
  /// being restored.
  final bool maximized;

  /// The state as stored JSON.
  String encode() => jsonEncode({
    'x': bounds.left,
    'y': bounds.top,
    'width': bounds.width,
    'height': bounds.height,
    'maximized': maximized,
  });

  /// The saved bounds, or null if they would put the window somewhere the user
  /// cannot reach.
  ///
  /// A window remembered on a monitor that is no longer attached opens
  /// off-screen, and on most platforms there is then no way to drag it back.
  /// [displays] is the union of every screen's area.
  Rect? boundsWithin(Rect displays, {double minimumVisible = 120}) {
    final overlap = bounds.intersect(displays);
    if (overlap.width < minimumVisible || overlap.height < minimumVisible) {
      return null;
    }
    return bounds;
  }
}

/// Reads and writes where the window was.
///
/// Uses the same key/value table as the settings, under its own key: this is
/// not a preference — nobody chooses it — and putting it in the settings blob
/// would carry it into backups, where a window position from another machine
/// is at best noise.
class WindowStateStore {
  /// Creates a store over the database.
  const new(this._db);

  final TerminoDatabase _db;

  static const _key = 'window-state';

  /// The stored state, or null when there is none.
  Future<WindowState?> read() async {
    final query = _db.select(_db.settingRows)
      ..where((row) => row.key.equals(_key));
    final row = await query.getSingleOrNull();
    return WindowState.decode(row?.value);
  }

  /// Saves [state].
  Future<void> write(WindowState state) => _db
      .into(_db.settingRows)
      .insertOnConflictUpdate(SettingRow(key: _key, value: state.encode()));
}
