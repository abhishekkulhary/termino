import 'package:termino/domain/entities/ssh_host.dart';

/// Stores saved SSH connections. Never stores their secrets.
abstract class SshHostRepository {
  /// Every saved connection, ordered by label.
  Future<List<SshHost>> all();

  /// Emits the full list whenever it changes.
  Stream<List<SshHost>> watch();

  /// One connection by id, or null.
  Future<SshHost?> byId(String id);

  /// Creates or updates a connection.
  Future<void> save(SshHost host);

  /// Deletes a connection and any password remembered for it.
  Future<void> delete(String id);
}
