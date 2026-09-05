import 'package:termino/domain/entities/known_host.dart';

/// The outcome of checking a host key against what we have on record.
enum HostKeyVerdict {
  /// The key matches the one recorded for this host, port and key type.
  trusted,

  /// Nothing is on record for this host. The user is asked to accept it —
  /// trust on first use.
  unknown,

  /// The host is known, but by a different key type. The user is asked, and
  /// told that other keys are already trusted for it.
  newKeyType,

  /// A key of this type is on record and it does **not** match.
  ///
  /// This is never a prompt the user can wave through casually. It means
  /// either the server was rebuilt or someone is impersonating it, and the two
  /// are indistinguishable from here.
  mismatch;

  /// Whether the connection may proceed without asking the user.
  bool get isAutomaticallyTrusted => this == HostKeyVerdict.trusted;

  /// Whether the connection must be refused outright.
  bool get blocksConnection => this == HostKeyVerdict.mismatch;
}

/// The result of a host key check, with everything the UI needs to explain it.
class HostKeyCheck {
  /// Creates a check result.
  const new({
    required this.verdict,
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    this.expected,
    this.otherKnownTypes = const [],
  });

  /// What was decided.
  final HostKeyVerdict verdict;

  /// The host as the user asked for it.
  final String host;

  /// The port connected to.
  final int port;

  /// The key type the server offered, e.g. `ssh-ed25519`.
  final String keyType;

  /// The fingerprint the server offered.
  final String fingerprint;

  /// The entry already on record, when there is one. Populated for
  /// [HostKeyVerdict.trusted] and, crucially, for [HostKeyVerdict.mismatch],
  /// where the dialog must show both fingerprints side by side.
  final KnownHost? expected;

  /// Key types already trusted for this host, for [HostKeyVerdict.newKeyType].
  final List<String> otherKnownTypes;

  /// `host` or `host:port`, for display.
  String get target => port == 22 ? host : '$host:$port';
}
