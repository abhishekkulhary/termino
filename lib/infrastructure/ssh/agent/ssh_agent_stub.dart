import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';

/// The web's answer to "is there an SSH agent?": no.
///
/// A browser tab has no Unix sockets and no access to the machine's key agent,
/// and no amount of relaying changes that — the agent is on the user's own
/// computer, not on the far side of the tunnel.
class SshAgent {
  /// Creates a client that cannot connect to anything.
  const new(this.socketPath);

  /// Always null on the web.
  static SshAgent? fromEnvironment([Map<String, String>? environment]) => null;

  /// Always false on the web.
  static bool get isSupported => false;

  /// Meaningless here, kept so the two sides share a shape.
  final String socketPath;

  /// Always throws.
  Future<List<AgentKey>> identities() async => throw _unavailable;

  /// Always throws.
  Future<Uint8List> sign(Uint8List blob, Uint8List data, int flags) async =>
      throw _unavailable;

  /// Always throws.
  Future<List<SSHIdentity>> asIdentities() async => throw _unavailable;

  static const _unavailable = AgentProtocolException(
    'A browser cannot reach the SSH agent on your computer.',
  );
}
