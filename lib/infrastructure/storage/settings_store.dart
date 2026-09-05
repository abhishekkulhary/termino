import 'dart:convert';

import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/infrastructure/storage/database.dart';

/// Reads and writes the user's settings.
///
/// Stored as a single JSON blob under one key rather than as one row per
/// field. Settings are read and written as a whole, so splitting them buys
/// nothing and costs a migration every time one is added.
class SettingsStore {
  /// Creates a store over the database.
  const new(this._db);

  final TerminoDatabase _db;

  static const _key = 'terminal-settings';

  /// The stored settings, or the defaults when nothing is saved.
  ///
  /// A stored blob that cannot be parsed — an older or corrupted format —
  /// yields the defaults rather than an error. Losing a preference is a far
  /// better outcome than an app that will not start.
  Future<TerminalSettings> read() async {
    final query = _db.select(_db.settingRows)
      ..where((row) => row.key.equals(_key));
    final row = await query.getSingleOrNull();
    if (row == null) return const TerminalSettings();

    try {
      return TerminalSettings.fromJson(
        jsonDecode(row.value) as Map<String, dynamic>,
      );
    } on Object {
      return const TerminalSettings();
    }
  }

  /// Emits the settings whenever they change.
  Stream<TerminalSettings> watch() {
    final query = _db.select(_db.settingRows)
      ..where((row) => row.key.equals(_key));
    return query.watchSingleOrNull().map((row) {
      if (row == null) return const TerminalSettings();
      try {
        return TerminalSettings.fromJson(
          jsonDecode(row.value) as Map<String, dynamic>,
        );
      } on Object {
        return const TerminalSettings();
      }
    });
  }

  /// Saves [settings], replacing whatever was there.
  Future<void> write(TerminalSettings settings) => _db
      .into(_db.settingRows)
      .insertOnConflictUpdate(
        SettingRow(key: _key, value: jsonEncode(settings.toJson())),
      );
}
