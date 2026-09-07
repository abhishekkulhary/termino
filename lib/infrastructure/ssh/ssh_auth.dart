import 'package:dartssh2/dartssh2.dart';

/// What the UI must supply for an SSH session to authenticate.
///
/// Every callback may return null to decline, which aborts the attempt rather
/// than retrying forever — a user who cancels a password prompt means it.
class SshAuthPrompts {
  /// Creates a set of prompts.
  const new({
    this.identities,
    this.onPasswordRequest,
    this.onUserInfoRequest,
    this.onBanner,
    this.agent,
  });

  /// Keys to offer for public-key authentication. Empty or null skips it.
  ///
  /// `SSHIdentity` rather than `SSHKeyPair` so that a key held by the system
  /// agent can be offered alongside — or instead of — one this app has
  /// decrypted. An agent identity carries no key material at all: it is a
  /// public blob and a callback that asks the agent to sign.
  ///
  /// A key this app did decrypt is held only for the duration of the attempt:
  /// the caller reads it from the keystore immediately before connecting and
  /// drops it afterwards.
  final List<SSHIdentity>? identities;

  /// Asks the user for a password.
  final Future<String?> Function()? onPasswordRequest;

  /// Answers a keyboard-interactive challenge — the mechanism behind
  /// one-time codes and PAM prompts. Returns one answer per prompt.
  final Future<List<String>?> Function(SSHUserInfoRequest request)?
  onUserInfoRequest;

  /// An agent to forward to the remote host, when the user asked for it.
  ///
  /// Null means no forwarding, which is the default: forwarding lets anyone
  /// with root on the far end use the key for the life of the session.
  final SSHAgentHandler? agent;

  /// Shows the server's pre-authentication banner.
  ///
  /// Never logged: a banner is server-controlled text that has been known to
  /// carry session details.
  final void Function(String banner)? onBanner;
}
