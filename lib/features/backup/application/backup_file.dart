import 'dart:convert';

import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/terminal_settings.dart';

/// What a backup contains, and what it deliberately does not.
///
/// **No private keys, no passwords, no passphrases.** Those live in the
/// platform keystore and stay there. A backup is a file people email to
/// themselves, drop in cloud storage and forget about; putting key material in
/// it would undo the single most important thing this app does with secrets.
/// A restored host that used a key simply has no key until one is imported,
/// and says so.
///
/// **No trusted host keys either.** Those are decisions someone made by
/// checking a fingerprint, and carrying them to a new device would mean the
/// first connection there silently skips the check that mattered. The
/// `~/.ssh/known_hosts` import exists for bringing trust across deliberately.
class BackupFile {
  /// Creates a backup.
  const new({
    required this.hosts,
    required this.snippets,
    required this.forwards,
    this.settings,
    this.createdAt,
  });

  /// Reads a backup from [json], throwing [FormatException] on anything that
  /// is not one.
  factory decode(String json) {
    final Object? parsed;
    try {
      parsed = jsonDecode(json);
    } on FormatException {
      throw const FormatException('That file is not a Termino backup.');
    }

    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('That file is not a Termino backup.');
    }
    if (parsed['kind'] != _kind) {
      throw const FormatException('That file is not a Termino backup.');
    }

    final version = parsed['version'];
    if (version is! int || version > currentVersion) {
      throw FormatException(
        'This backup was written by a newer version of Termino '
        '(format $version). Update the app and try again.',
      );
    }

    List<T> read<T>(String key, T Function(Map<String, dynamic>) parse) {
      final value = parsed is Map<String, dynamic> ? parsed[key] : null;
      if (value == null) return const [];
      if (value is! List) {
        throw FormatException('The "$key" section of this backup is damaged.');
      }
      return [
        for (final entry in value)
          if (entry is Map<String, dynamic>) parse(entry),
      ];
    }

    final settings = parsed['settings'];

    return BackupFile(
      hosts: read('hosts', SshHost.fromJson),
      snippets: read('snippets', Snippet.fromJson),
      forwards: read('forwards', PortForward.fromJson),
      settings: settings is Map<String, dynamic>
          ? TerminalSettings.fromJson(settings)
          : null,
      createdAt: DateTime.tryParse(parsed['createdAt'] as String? ?? ''),
    );
  }

  /// Marks the file as ours, so a wrong file is rejected with a sentence
  /// rather than a stack trace.
  static const _kind = 'termino.backup';

  /// The format this app writes. A backup from an older version still reads;
  /// one from a newer version is refused, because guessing is worse.
  static const currentVersion = 1;

  /// Saved connections.
  final List<SshHost> hosts;

  /// Saved snippets.
  final List<Snippet> snippets;

  /// Saved port forwards.
  final List<PortForward> forwards;

  /// Preferences, or null when the backup carried none.
  final TerminalSettings? settings;

  /// When it was written.
  final DateTime? createdAt;

  /// The file's contents, pretty-printed so a human can read what they are
  /// about to hand around.
  String encode() => const JsonEncoder.withIndent('  ').convert({
    'kind': _kind,
    'version': currentVersion,
    'createdAt': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
    // Named in the file itself, so someone reading it knows what is absent.
    'excludes': const [
      'private keys',
      'passwords',
      'passphrases',
      'trusted host keys',
    ],
    'hosts': [for (final host in hosts) _withoutSecretHints(host.toJson())],
    'snippets': [for (final snippet in snippets) snippet.toJson()],
    'forwards': [for (final forward in forwards) forward.toJson()],
    if (settings case final saved?) 'settings': saved.toJson(),
  });

  /// Drops the flag that says a password is remembered.
  ///
  /// The password itself was never here — it is in the keystore — but carrying
  /// the flag would make a restored host claim a saved password it does not
  /// have, and then fail to connect without ever offering a prompt.
  static Map<String, dynamic> _withoutSecretHints(Map<String, dynamic> host) =>
      {...host, 'hasSavedPassword': false};
}
