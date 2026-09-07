import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';

/// Talks to the system SSH agent over its socket.
///
/// The reason to prefer this over an imported key is simple: the private key
/// never enters this process. `ssh-agent`, 1Password, Secretive and a YubiKey
/// all speak this protocol, so a key held in the Secure Enclave — one that
/// *cannot* be exported — can still authenticate a session here.
///
/// Each operation opens a connection and closes it. An agent connection held
/// open across a long-running app is a handle to every key the user has
/// loaded, and there is no reason to hold one between authentication attempts.
class SshAgent {
  /// Creates a client for the agent listening at [socketPath].
  const new(this.socketPath);

  /// Creates a client for whatever `SSH_AUTH_SOCK` points at, or null when
  /// nothing does.
  ///
  /// On a desktop launched from Finder or a launcher rather than a shell, the
  /// variable is often absent even though an agent is running — that is a
  /// property of how the process was started, not of the agent, and the UI says
  /// so rather than claiming there is no agent.
  static SshAgent? fromEnvironment([Map<String, String>? environment]) {
    final variables = environment ?? Platform.environment;
    final path = variables['SSH_AUTH_SOCK'];
    if (path == null || path.isEmpty) return null;
    return SshAgent(path);
  }

  /// The socket the agent is listening on.
  final String socketPath;

  /// The keys the agent is holding.
  Future<List<AgentKey>> identities() async {
    final reply = await _exchange(AgentProtocol.requestIdentitiesMessage());
    return AgentProtocol.decodeIdentities(reply);
  }

  /// Asks the agent to sign [data] with the key [blob].
  Future<Uint8List> sign(Uint8List blob, Uint8List data, int flags) async {
    final reply = await _exchange(
      AgentProtocol.signRequestMessage(blob, data, flags),
    );
    return AgentProtocol.decodeSignature(reply);
  }

  /// The agent's keys, as identities `dartssh2` can authenticate with.
  ///
  /// `shouldProbe` is on, which the package recommends for external signers:
  /// it asks the server whether a key would be accepted before asking the
  /// agent to sign. Without it, a user with four keys loaded and a hardware
  /// token among them gets a touch prompt for every key the server was going
  /// to reject anyway.
  Future<List<SSHIdentity>> asIdentities() async {
    final keys = await identities();
    return [
      for (final key in keys)
        SSHIdentity.custom(
          type: key.algorithm,
          publicKey: SSHRawHostKey(key.blob),
          comment: key.comment,
          shouldProbe: true,
          signer: (data) async =>
              SSHRawSignature(await sign(key.blob, data, key.signFlags)),
        ),
    ];
  }

  Future<Uint8List> _exchange(Uint8List request) async {
    final Socket socket;
    try {
      socket = await Socket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );
    } on SocketException catch (error) {
      final reason = error.osError?.message;
      throw AgentProtocolException(
        reason == null
            ? 'No agent is listening at $socketPath.'
            : 'No agent is listening at $socketPath: $reason.',
      );
    } on Object {
      throw AgentProtocolException('No agent is listening at $socketPath.');
    }

    try {
      socket.add(request);
      await socket.flush();

      final buffer = BytesBuilder();
      await for (final chunk in socket) {
        buffer.add(chunk);
        // Stop as soon as one whole frame has arrived. Reading to the end of
        // the stream instead would wait for the agent to hang up, which it
        // does not do — it is waiting for the next request.
        final length = AgentProtocol.frameLength(buffer.toBytes());
        if (length != null) return buffer.toBytes();
      }
      throw const AgentProtocolException(
        'The agent closed the connection without answering.',
      );
    } finally {
      socket.destroy();
    }
  }
}
