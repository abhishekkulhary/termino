import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/features/backup/application/backup_file.dart';
import 'package:termino/features/settings/application/settings_controller.dart';

part 'backup_service.g.dart';

/// What a restore actually did.
class RestoreSummary {
  /// Creates a summary.
  const new({
    required this.hosts,
    required this.snippets,
    required this.forwards,
    required this.settingsRestored,
  });

  /// How many connections were written.
  final int hosts;

  /// How many snippets were written.
  final int snippets;

  /// How many tunnels were written.
  final int forwards;

  /// Whether preferences came across.
  final bool settingsRestored;

  /// Whether the file turned out to hold nothing.
  bool get isEmpty => hosts == 0 && snippets == 0 && forwards == 0;

  /// A sentence for the snackbar.
  String get description {
    if (isEmpty) {
      return settingsRestored
          ? 'Restored settings. The backup held nothing else.'
          : 'That backup was empty.';
    }
    final parts = [
      if (hosts > 0) '$hosts host${hosts == 1 ? '' : 's'}',
      if (snippets > 0) '$snippets snippet${snippets == 1 ? '' : 's'}',
      if (forwards > 0) '$forwards tunnel${forwards == 1 ? '' : 's'}',
    ];
    return 'Restored ${parts.join(', ')}.';
  }
}

/// Writes and reads backups.
///
/// Kept alive: a restore is a sequence of awaited writes, and an auto-disposed
/// controller is thrown away part-way through one.
@Riverpod(keepAlive: true)
class BackupService extends _$BackupService {
  @override
  void build() {}

  /// Everything worth carrying to another device, as a file's contents.
  Future<String> export() async {
    final backup = BackupFile(
      hosts: await ref.read(sshHostRepositoryProvider).all(),
      snippets: await ref.read(snippetRepositoryProvider).all(),
      forwards: await ref.read(portForwardRepositoryProvider).all(),
      settings: ref.read(currentSettingsProvider),
    );
    return backup.encode();
  }

  /// Reads [contents] and writes what it holds.
  ///
  /// Merges rather than replaces. An id that already exists is overwritten and
  /// anything else is left alone, so restoring onto a device that is already
  /// set up adds to it instead of wiping it — which is what someone moving
  /// between two machines actually wants, and is the recoverable direction if
  /// they picked the wrong file.
  ///
  /// Throws [FormatException] with a readable message for anything that is not
  /// a backup.
  Future<RestoreSummary> restore(String contents) async {
    final backup = BackupFile.decode(contents);

    for (final host in backup.hosts) {
      await ref.read(sshHostRepositoryProvider).save(host);
    }
    for (final snippet in backup.snippets) {
      await ref.read(snippetRepositoryProvider).save(snippet);
    }
    for (final forward in backup.forwards) {
      await ref.read(portForwardRepositoryProvider).save(forward);
    }

    final settings = backup.settings;
    if (settings != null) {
      // The first-run flag is not a preference and must not travel: restoring
      // onto a device that has been used should not send it back through
      // onboarding, and restoring onto a fresh one should not skip it.
      await ref
          .read(settingsProvider.notifier)
          .replaceAll(
            settings.copyWith(
              onboardingComplete: ref
                  .read(currentSettingsProvider)
                  .onboardingComplete,
            ),
          );
    }

    return RestoreSummary(
      hosts: backup.hosts.length,
      snippets: backup.snippets.length,
      forwards: backup.forwards.length,
      settingsRestored: settings != null,
    );
  }
}
