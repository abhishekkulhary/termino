import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:termino/core/logging/redaction.dart';

/// The application's logging entry point.
///
/// Every record passes through a [Redactor] before it reaches any sink, so a
/// secret that slips into a message is removed on the way out rather than
/// relied upon never to be there. See SECURITY.md.
///
/// Two things are deliberately absent: there is no remote sink of any kind, and
/// the session byte stream is never logged. Terminal output contains whatever
/// the user typed and whatever the far end printed, which routinely includes
/// credentials.
class AppLogger {
  /// Creates a logger writing through [redactor].
  new({Redactor? redactor, this.onOutput}) : redactor = redactor ?? Redactor();

  /// Strips secrets from every message.
  final Redactor redactor;

  /// Where redacted lines go. Defaults to the debug console.
  final void Function(String line)? onOutput;

  final _records = <String>[];
  StreamSubscription<LogRecord>? _subscription;

  /// Recent redacted lines, for the in-app diagnostics view.
  ///
  /// Capped, because an unbounded buffer of terminal-adjacent text is both a
  /// memory leak and a larger blast radius if it were ever exported.
  List<String> get recent => List.unmodifiable(_records);

  /// The most lines [recent] will hold.
  static const maxRecords = 500;

  /// Starts listening to the `logging` package's root logger.
  void attach({Level level = kDebugMode ? Level.INFO : Level.WARNING}) {
    Logger.root.level = level;
    _subscription ??= Logger.root.onRecord.listen(_handle);
  }

  /// Stops listening.
  Future<void> detach() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handle(LogRecord record) {
    final buffer = StringBuffer()
      ..write('[${record.level.name}] ')
      ..write('${record.loggerName}: ')
      ..write(record.message);

    if (record.error != null) buffer.write(' | error: ${record.error}');

    final line = redactor.redact(buffer.toString());

    _records.add(line);
    if (_records.length > maxRecords) _records.removeAt(0);

    final sink = onOutput;
    if (sink != null) {
      sink(line);
    } else {
      debugPrint(line);
    }
  }

  /// Clears the buffered lines.
  void clear() => _records.clear();
}

/// Named loggers, so that filtering by subsystem is possible.
abstract final class Loggers {
  /// SSH transport, authentication and host key checks.
  static final ssh = Logger('ssh');

  /// Local pseudo-terminals.
  static final pty = Logger('pty');

  /// Session and tab lifecycle.
  static final session = Logger('session');

  /// Persistence.
  static final storage = Logger('storage');
}
