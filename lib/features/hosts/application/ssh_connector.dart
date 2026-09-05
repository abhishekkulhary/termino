import 'package:dartssh2/dartssh2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/repositories/known_hosts_repository.dart';
import 'package:termino/domain/repositories/secret_store.dart';
import 'package:termino/domain/repositories/ssh_host_repository.dart';
import 'package:termino/domain/repositories/ssh_identity_repository.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/hosts/application/ssh_prompt_service.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';

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
    required this.knownHosts,
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

  /// Trusted keys, for forgetting one after a mismatch.
  final KnownHostsRepository knownHosts;

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
    ).connect(
      host: host,
      prompts: await _promptsFor(host),
      jumpChain: chain,
      jumpPrompts: {for (final hop in chain) hop.id: await _promptsFor(hop)},
    );
  }

  /// Builds a backend ready to [TerminalBackend.start].
  Future<SshBackend> connect(
    SshHost host, {
    int columns = 80,
    int rows = 24,
  }) async {
    final chain = await _resolveJumpChain(host);

    return SshBackend(
      host: host,
      verifier: verifier,
      onHostKeyPrompt: prompts.confirmHostKey,
      prompts: await _promptsFor(host),
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

    return SshAuthPrompts(
      identities: identities,
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

  Future<List<SSHKeyPair>?> _loadIdentity(SshHost host) async {
    final id = host.identityId;
    if (id == null) return null;

    final identity = await identities.byId(id);
    if (identity == null) {
      Loggers.ssh.warning('Identity $id for ${host.label} is missing.');
      return null;
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
  knownHosts: ref.watch(knownHostsRepositoryProvider),
);
