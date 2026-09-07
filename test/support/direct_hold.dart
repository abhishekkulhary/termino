import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

/// A hold on a connection with no pool behind it: releasing closes it.
///
/// Tests that open one connection for one purpose want exactly this. Going
/// through the real pool would test the pool, which has its own suite.
class DirectHold implements SshConnectionHold {
  /// Creates a hold that owns [connection].
  const new(this.connection);

  @override
  final SshConnection connection;

  @override
  Future<void> release() => connection.close();
}
