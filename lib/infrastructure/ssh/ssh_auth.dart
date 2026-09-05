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
  });

  /// Private keys to offer, already decrypted. Empty or null skips public key
  /// authentication.
  ///
  /// These are held only for the duration of the attempt: the caller reads
  /// them from the keystore immediately before connecting and drops them
  /// afterwards.
  final List<SSHKeyPair>? identities;

  /// Asks the user for a password.
  final Future<String?> Function()? onPasswordRequest;

  /// Answers a keyboard-interactive challenge — the mechanism behind
  /// one-time codes and PAM prompts. Returns one answer per prompt.
  final Future<List<String>?> Function(SSHUserInfoRequest request)?
  onUserInfoRequest;

  /// Shows the server's pre-authentication banner.
  ///
  /// Never logged: a banner is server-controlled text that has been known to
  /// carry session details.
  final void Function(String banner)? onBanner;
}
