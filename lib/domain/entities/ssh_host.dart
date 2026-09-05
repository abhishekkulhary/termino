import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_host.freezed.dart';
part 'ssh_host.g.dart';

/// How to authenticate to a host, in the order the user prefers.
enum SshAuthMethod {
  /// A key from the app's identity store.
  publicKey,

  /// A password, optionally remembered in the platform keystore.
  password,

  /// The server drives the exchange with prompts (2FA, PAM).
  keyboardInteractive;

  /// A label for the UI.
  String get label => switch (this) {
    SshAuthMethod.publicKey => 'Public key',
    SshAuthMethod.password => 'Password',
    SshAuthMethod.keyboardInteractive => 'Keyboard interactive',
  };
}

/// A saved SSH connection.
///
/// Holds no secrets. A password, if the user chose to remember one, lives in
/// the platform keystore under [passwordRef]; the identity referenced by
/// [identityId] holds its private key the same way.
@freezed
abstract class SshHost with _$SshHost {
  /// Creates a saved connection.
  const factory({
    required String id,
    required String label,
    required String hostname,
    required String username,
    @Default(22) int port,

    /// The identity to authenticate with, when using public key auth.
    String? identityId,

    /// Which methods to offer, in order. An empty list means "try everything".
    @Default(<SshAuthMethod>[]) List<SshAuthMethod> authMethods,

    /// The id of another [SshHost] to tunnel through, as OpenSSH's ProxyJump.
    String? jumpHostId,

    /// How often to send a keepalive. Zero disables it.
    @Default(Duration(seconds: 30)) Duration keepAliveInterval,

    /// A command to run once the shell opens, e.g. `tmux attach`.
    String? startupCommand,

    /// A colour for the tab and the host list, as an ARGB value.
    int? colorValue,

    /// Free-text grouping, shown as a folder in the host list.
    String? folder,

    /// Whether a remembered password exists in the keystore.
    @Default(false) bool hasSavedPassword,

    /// Whether to forward this connection's key to the remote host, so that
    /// it can authenticate onward without the key ever leaving this device.
    ///
    /// Off by default. Forwarding lets anyone with root on the remote host use
    /// the key for as long as the session lasts, which is a real cost and one
    /// worth opting into deliberately.
    @Default(false) bool forwardAgent,
  }) = _SshHost;

  const new _();

  /// Restores a saved connection from stored JSON.
  factory fromJson(Map<String, dynamic> json) => _$SshHostFromJson(json);

  /// The keystore key holding this host's remembered password.
  String get passwordRef => 'host.$id.password';

  /// `user@host` or `user@host:port`, as a user would write it.
  String get target =>
      port == 22 ? '$username@$hostname' : '$username@$hostname:$port';

  /// The methods to attempt, defaulting to all of them in the usual order.
  List<SshAuthMethod> get effectiveAuthMethods => authMethods.isNotEmpty
      ? authMethods
      : const [
          SshAuthMethod.publicKey,
          SshAuthMethod.keyboardInteractive,
          SshAuthMethod.password,
        ];
}
