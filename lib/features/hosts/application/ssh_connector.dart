import 'package:dartssh2/dartssh2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/auth/biometric_gate.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/repositories/known_hosts_repository.dart';
import 'package:termino/domain/repositories/secret_store.dart';
import 'package:termino/domain/repositories/ssh_host_repository.dart';
import 'package:termino/domain/repositories/ssh_identity_repository.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/hosts/application/ssh_prompt_service.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';
import 'package:termino/infrastructure/ssh/agent/ssh_agent.dart';
import 'package:termino/infrastructure/ssh/sockets/socket_factory_provider.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

part 'ssh_connector.g.dart';

/// Assembles an [SshBackend] for a saved host: resolves the jump chain, reads
/// the right key out of the keystore, and wires the prompts.
///
/// Secrets are read here and handed straight to the backend. They are never
/// stored on this object, never logged, and never put in provider state, so
/// they exist only for the duration of a connection attempt.
class SshConnector {
  /// Creates a connector.
  const new({
    required this.hosts,
    required this.identities,
    required this.secrets,
    required this.verifier,
    required this.prompts,
    required this.biometrics,
    required this.knownHosts,
    required this.socketFactory,
  });

  /// Saved connections, for resolving jump hosts.
  final SshHostRepository hosts;

  /// Key metadata.
  final SshIdentityRepository identities;

  /// The keystore.
  final SecretStore secrets;

  /// Host key policy.
  final HostKeyVerifier verifier;

  /// What to ask the user.
  final SshPromptService prompts;

  /// Confirms the device holder before a protected key is used.
  final BiometricGate biometrics;

  /// Trusted keys, for forgetting one after a mismatch.
  final KnownHostsRepository knownHosts;

  /// How to reach a server: a TCP socket, or a relay on the web.
  final SshSocketFactory socketFactory;

  /// Opens an authenticated connection to [host], for SFTP or forwarding.
  ///
  /// Separate from the shell's connection on purpose: a transfer that fails,
  /// or a file browser the user closes, must not disturb a terminal they have
  /// work in progress in. The cost is a second authentication.
  Future<SshConnection> open(SshHost host) async {
    final chain = await _resolveJumpChain(host);

    return await SshConnectionFactory(
      verifier: verifier,
      onHostKeyPrompt: prompts.confirmHostKey,
      socketFactory: socketFactory,
    ).connect(
      host: host,
      prompts: await _promptsFor(host),
      jumpChain: chain,
      jumpPrompts: {for (final hop in chain) hop.id: await _promptsFor(hop)},
    );
  }

  /// Builds a backend ready to [TerminalBackend.start].
  ///
  /// Pass [acquire] — the connection pool's — and the shell shares the host's
  /// one authenticated connection with the file browser and any forwards.
  /// Without it the backend opens a connection of its own, which is what the
  /// protocol-level tests want.
  Future<SshBackend> connect(
    SshHost host, {
    int columns = 80,
    int rows = 24,
    Future<SshConnectionHold> Function()? acquire,
  }) async {
    // Resolved even when the connection is pooled, because the prompts are
    // what the pool's own opener will use if it has to authenticate.
    final chain = acquire == null
        ? await _resolveJumpChain(host)
        : const <SshHost>[];

    return SshBackend(
      host: host,
      verifier: verifier,
      socketFactory: socketFactory,
      onHostKeyPrompt: prompts.confirmHostKey,
      acquire: acquire,
      prompts: acquire == null
          ? await _promptsFor(host)
          : const SshAuthPrompts(),
      jumpChain: chain,
      jumpPrompts: {for (final hop in chain) hop.id: await _promptsFor(hop)},
      columns: columns,
      rows: rows,
    );
  }

  /// Walks `jumpHostId` links, nearest hop first.
  ///
  /// Guards against a cycle: a host configured, directly or transitively, to
  /// jump through itself would otherwise recurse until the stack ran out.
  Future<List<SshHost>> _resolveJumpChain(SshHost host) async {
    final chain = <SshHost>[];
    final seen = <String>{host.id};

    var current = host;
    while (current.jumpHostId != null) {
      final next = await hosts.byId(current.jumpHostId!);
      if (next == null) {
        Loggers.ssh.warning(
          'Jump host ${current.jumpHostId} for ${current.label} is missing; '
          'connecting directly.',
        );
        break;
      }
      if (!seen.add(next.id)) {
        Loggers.ssh.warning('Jump host chain for ${host.label} loops; cut.');
        break;
      }
      chain.insert(0, next);
      current = next;
    }

    return chain;
  }

  Future<SshAuthPrompts> _promptsFor(SshHost host) async {
    final methods = host.effectiveAuthMethods;
    final identities = methods.contains(SshAuthMethod.publicKey)
        ? await _loadIdentity(host)
        : null;
    final fromAgent = methods.contains(SshAuthMethod.agent)
        ? await _agentIdentities(host)
        : null;

    return SshAuthPrompts(
      // This app's own keys first, then the agent's. A key the user imported
      // here was chosen for this host; the agent's are whatever happens to be
      // loaded, and one of them may be on a hardware token that asks for a
      // touch.
      identities: [...?identities, ...?fromAgent],
      // Only this host's own identity is forwarded, not every key the user
      // owns. OpenSSH forwards the whole agent; narrowing it means a
      // compromised host can misuse one key rather than all of them, and the
      // wider behaviour has no use case here that this does not cover.
      agent: host.forwardAgent && identities != null && identities.isNotEmpty
          ? SSHKeyPairAgent(identities, comment: 'termino')
          : null,
      onPasswordRequest: methods.contains(SshAuthMethod.password)
          ? () => _password(host)
          : null,
      onUserInfoRequest: methods.contains(SshAuthMethod.keyboardInteractive)
          ? (request) => prompts.requestUserInfo(host, request)
          : null,
      // Banners are server-controlled text and are deliberately not logged.
      onBanner: (_) {},
    );
  }

  /// The system agent's keys, as identities that sign without exposing a key.
  ///
  /// A failure here is logged and skipped rather than thrown: the host may
  /// have other methods enabled, and an agent that is not running should
  /// degrade to "that method contributed nothing", not "the connection is
  /// impossible". The host editor shows the agent's state before it is ever
  /// saved, so this is a fallback, not the only warning a user gets.
  Future<List<SSHIdentity>?> _agentIdentities(SshHost host) async {
    final agent = SshAgent.fromEnvironment();
    if (agent == null) {
      Loggers.ssh.warning(
        'SSH_AUTH_SOCK is not set, so ${host.label} cannot use the system '
        'agent. Launching the app from a shell usually sets it.',
      );
      return null;
    }

    try {
      final identities = await agent.asIdentities();
      if (identities.isEmpty) {
        Loggers.ssh.warning('The system agent is holding no keys.');
      }
      return identities;
    } on AgentProtocolException catch (error) {
      // The message is the agent's own account of itself and carries no key
      // material.
      Loggers.ssh.warning('The system agent could not be used: $error');
      return null;
    }
  }

  Future<List<SSHKeyPair>?> _loadIdentity(SshHost host) async {
    final id = host.identityId;
    if (id == null) return null;

    final identity = await identities.byId(id);
    if (identity == null) {
      Loggers.ssh.warning('Identity $id for ${host.label} is missing.');
      return null;
    }

    // Before the key is read, not after. A check that runs once the private
    // key is already in memory protects nothing worth protecting.
    if (identity.requiresBiometrics) {
      final allowed = await biometrics.confirm(
        reason: 'Unlock ${identity.name} to connect to ${host.label}',
      );
      if (!allowed) {
        // Declining is not an error and not a fallback: this identity is
        // simply not offered, and the connection carries on with whatever
        // other methods the host allows.
        Loggers.ssh.info('Biometric check declined for ${identity.name}.');
        return null;
      }
    }

    final pem = await secrets.read(identity.secretRef);
    if (pem == null) {
      Loggers.ssh.warning('No key material stored for ${identity.name}.');
      return null;
    }

    if (!identity.hasPassphrase) return SSHKeyPair.fromPem(pem);

    // A remembered passphrase is preferred; otherwise the user is asked, and
    // may decline, which simply means this identity is not offered.
    final passphrase =
        await secrets.read(identity.passphraseRef) ??
        await prompts.requestPassphrase(identity);
    if (passphrase == null) return null;

    try {
      return SSHKeyPair.fromPem(pem, passphrase);
    } on SSHKeyDecryptError {
      Loggers.ssh.warning('Wrong passphrase for ${identity.name}.');
      return null;
    }
  }

  Future<String?> _password(SshHost host) async {
    final saved = host.hasSavedPassword
        ? await secrets.read(host.passwordRef)
        : null;
    return saved ?? await prompts.requestPassword(host);
  }
}

/// The connector for the current provider scope.
@Riverpod(keepAlive: true)
SshConnector sshConnector(Ref ref) => SshConnector(
  hosts: ref.watch(sshHostRepositoryProvider),
  identities: ref.watch(sshIdentityRepositoryProvider),
  secrets: ref.watch(secretStoreProvider),
  verifier: ref.watch(hostKeyVerifierProvider),
  prompts: ref.watch(sshPromptServiceProvider),
  biometrics: ref.watch(biometricGateProvider),
  knownHosts: ref.watch(knownHostsRepositoryProvider),
  socketFactory: ref.watch(sshSocketFactoryProvider),
);
