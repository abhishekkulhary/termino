import 'dart:io';

import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/ssh/known_hosts_file.dart';
import 'package:termino/domain/ssh/ssh_config.dart';

/// Reads `~/.ssh/config` and `~/.ssh/known_hosts`.
///
/// Read-only, deliberately: Termino never edits the user's OpenSSH files. They
/// are shared with `ssh` itself and with every other tool on the machine, and
/// silently rewriting them would be a surprising thing for a GUI to do.
class SshConfigImporter {
  /// Creates an importer, optionally rooted somewhere other than `$HOME`.
  const new({String? homeDirectory}) : _home = homeDirectory;

  final String? _home;

  /// The `.ssh` directory, or null when there is no home directory.
  String? get sshDirectory {
    final home =
        _home ??
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];
    return home == null ? null : '$home/.ssh';
  }

  /// Whether there is an `~/.ssh` directory to read.
  bool get isAvailable {
    final directory = sshDirectory;
    return directory != null && Directory(directory).existsSync();
  }

  /// Parses `~/.ssh/config`, following one level of `Include`.
  ///
  /// `Include` is followed here rather than in the parser because resolving it
  /// needs a filesystem, which the domain layer does not have. One level is
  /// enough for the common `Include conf.d/*` arrangement without risking a
  /// cycle.
  Future<List<SshConfigHost>> readConfig() async {
    final directory = sshDirectory;
    if (directory == null) return const [];

    final file = File('$directory/config');
    if (!file.existsSync()) return const [];

    final contents = await file.readAsString();
    final included = await _readIncludes(contents, directory);

    return SshConfig.parse([...included, contents].join('\n'));
  }

  Future<List<String>> _readIncludes(String contents, String directory) async {
    final includes = <String>[];

    for (final line in contents.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.toLowerCase().startsWith('include ')) continue;

      final pattern = trimmed.substring(8).trim();
      final resolved = pattern.startsWith('/') || pattern.startsWith('~')
          ? pattern.replaceFirst('~', Platform.environment['HOME'] ?? '~')
          : '$directory/$pattern';

      // Only literal paths are followed; expanding a glob would mean walking
      // the directory, and a malformed pattern should not cost the user their
      // config.
      if (resolved.contains('*') || resolved.contains('?')) continue;

      final file = File(resolved);
      if (file.existsSync()) includes.add(await file.readAsString());
    }

    return includes;
  }

  /// Parses `~/.ssh/known_hosts` into entries for the hosts named in [hosts].
  ///
  /// A `known_hosts` file cannot simply be copied in: entries may be wildcards
  /// or hashed, and neither yields a host name. Only keys that match a host the
  /// user actually has are imported, which is also the safer behaviour — it
  /// never silently trusts something the user did not ask about.
  Future<List<KnownHost>> readKnownHosts({
    required Iterable<({String host, int port})> hosts,
  }) async {
    final directory = sshDirectory;
    if (directory == null) return const [];

    final file = File('$directory/known_hosts');
    if (!file.existsSync()) return const [];

    final entries = KnownHostsFile.parse(await file.readAsString());
    final imported = <KnownHost>[];

    for (final target in hosts) {
      for (final entry in entries) {
        if (!entry.matchesHost(target.host, target.port)) continue;
        imported.add(entry.toKnownHost(host: target.host, port: target.port));
      }
    }

    return imported;
  }
}
