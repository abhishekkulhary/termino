import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/infrastructure/ssh/import/ssh_config_import.dart';

part 'known_hosts_controller.g.dart';

/// Every host key this app has accepted, newest first.
///
/// A future rather than a stream because the repository has no watch and this
/// list changes only when the user does something to it — trusting a key,
/// forgetting one, running an import. Each of those invalidates it.
@riverpod
Future<List<KnownHost>> trustedHostKeys(Ref ref) async {
  final entries = await ref.watch(knownHostsRepositoryProvider).all();
  return entries.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));
}

/// Forgets and imports trusted host keys.
///
/// Named apart from [trustedHostKeys] on purpose: a notifier class and a
/// function of the same name generate the same provider symbol.
///
/// Kept alive, which is not decoration. Auto-disposed, it is created by the
/// `ref.read` that starts a deletion and thrown away before the `await`
/// returns — so the `ref.invalidate` that refreshes the list afterwards throws
/// `UnmountedRefException`, the row is gone from the database and still on
/// screen, and nothing says why.
@Riverpod(keepAlive: true)
class KnownHostsController extends _$KnownHostsController {
  @override
  void build() {}

  /// Forgets every key recorded for [entry]'s host and port.
  ///
  /// The next connection to it is a first sighting again, and asks. That is
  /// the point: forgetting is how a user recovers from having trusted
  /// something they should not have.
  Future<void> forget(KnownHost entry) async {
    await ref
        .read(knownHostsRepositoryProvider)
        .remove(host: entry.host, port: entry.port);
    ref.invalidate(trustedHostKeysProvider);
  }

  /// Imports entries from the user's own `~/.ssh/known_hosts`.
  ///
  /// Only for hosts already saved in this app. Importing the whole file would
  /// mean trusting keys for machines the user has not asked this app about,
  /// which is not a decision worth making on their behalf — and the file on a
  /// long-lived machine is full of hosts nobody uses any more.
  ///
  /// Returns how many were added.
  Future<int> importFromOpenSsh() async {
    final hosts = await ref.read(sshHostRepositoryProvider).all();
    if (hosts.isEmpty) return 0;

    const importer = SshConfigImporter();
    if (!importer.isAvailable) return 0;

    final entries = await importer.readKnownHosts(
      hosts: hosts.map((host) => (host: host.hostname, port: host.port)),
    );
    if (entries.isEmpty) return 0;

    final added = await ref.read(knownHostsRepositoryProvider).addAll(entries);
    ref.invalidate(trustedHostKeysProvider);
    return added;
  }
}
