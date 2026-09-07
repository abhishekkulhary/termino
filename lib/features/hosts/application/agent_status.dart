import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';
import 'package:termino/infrastructure/ssh/agent/ssh_agent.dart';

part 'agent_status.g.dart';

/// What the system SSH agent is doing, as far as this app can tell.
///
/// Shown before a host is saved rather than discovered at connection time. The
/// two ways agent authentication fails are both invisible otherwise: the agent
/// is running but holds no keys, or `SSH_AUTH_SOCK` is not set because the app
/// was launched from Finder rather than a shell — and neither of those looks
/// like anything but "authentication failed" once a connection is under way.
class AgentStatus {
  /// Creates a status.
  const new({
    required this.supported,
    this.socketPath,
    this.keys = const [],
    this.problem,
  });

  /// Whether this platform can reach an agent at all.
  final bool supported;

  /// Where the agent was found, when one was.
  final String? socketPath;

  /// What it is holding.
  final List<AgentKey> keys;

  /// Why it could not be used, in words a person can act on.
  final String? problem;

  /// Whether an agent answered and had at least one key.
  bool get isUsable => problem == null && keys.isNotEmpty;

  /// A one-line summary for the editor.
  String get summary {
    if (!supported) {
      return 'Not available on this platform.';
    }
    if (problem != null) return problem!;
    if (keys.isEmpty) {
      return 'The agent is running but holds no keys. Add one with '
          '`ssh-add`.';
    }
    return keys.length == 1
        ? '1 key available: ${keys.single.comment}'
        : '${keys.length} keys available.';
  }
}

/// Asks the agent what it is holding.
@riverpod
Future<AgentStatus> agentStatus(Ref ref) async {
  if (!ref.watch(platformCapabilitiesProvider).canUseSshAgent) {
    return const AgentStatus(supported: false);
  }

  final agent = SshAgent.fromEnvironment();
  if (agent == null) {
    return const AgentStatus(
      supported: true,
      problem:
          'SSH_AUTH_SOCK is not set, so no agent can be found. Launching '
          'Termino from a terminal usually sets it.',
    );
  }

  try {
    return AgentStatus(
      supported: true,
      socketPath: agent.socketPath,
      keys: await agent.identities(),
    );
  } on AgentProtocolException catch (error) {
    return AgentStatus(
      supported: true,
      socketPath: agent.socketPath,
      problem: error.message,
    );
  }
}
