import 'package:dartssh2/dartssh2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/application/connection_pool.dart';
import 'package:termino/features/sftp/application/sftp_session.dart';
import 'package:termino/infrastructure/sftp/sftp_service.dart';

part 'sftp_providers.g.dart';

/// The host the file browser is showing, or null when none is chosen.
@Riverpod(keepAlive: true)
class SelectedSftpHost extends _$SelectedSftpHost {
  @override
  SshHost? build() => null;

  /// Chooses a host to browse.
  ///
  /// A named method rather than a setter: at the call site `select(host)` is
  /// clearer than assigning to a notifier property.
  // ignore: use_setters_to_change_properties
  void select(SshHost? host) => state = host;
}

/// A live SFTP session for the selected host.
///
/// Kept alive across navigation so that browsing to the terminal and back does
/// not re-authenticate, and disposed when the host changes or the app shuts
/// down.
@Riverpod(keepAlive: true)
Future<SftpSession?> sftpSession(Ref ref) async {
  final host = ref.watch(selectedSftpHostProvider);
  if (host == null) return null;

  // A lease on the host's shared connection rather than a connection of its
  // own: this is what stops the file browser asking for a password that a
  // terminal on the same host has already been given.
  final lease = await ref.watch(sshConnectionPoolProvider).acquire(host);
  final SftpClient client;
  try {
    client = await lease.client.sftp();
  } on Object {
    await lease.release();
    rethrow;
  }

  final session = SftpSession(
    host: host,
    lease: lease,
    service: SftpService(client),
    client: client,
  );

  ref.onDispose(session.dispose);
  await session.start();
  return session;
}
