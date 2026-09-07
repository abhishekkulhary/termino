import 'package:freezed_annotation/freezed_annotation.dart';

part 'known_host.freezed.dart';
part 'known_host.g.dart';

/// How a host key came to be trusted.
enum KnownHostSource {
  /// The user accepted it the first time they connected.
  trustOnFirstUse,

  /// It was imported from the user's `~/.ssh/known_hosts`.
  imported;

  /// How the source reads on the trusted-keys screen.
  String get label => switch (this) {
    KnownHostSource.trustOnFirstUse => 'accepted here',
    KnownHostSource.imported => 'imported',
  };
}

/// A host key this app has accepted, keyed by host, port and key type.
///
/// Fingerprints rather than raw keys, because `dartssh2` hands the verification
/// callback an OpenSSH-style `SHA256:...` fingerprint rather than the key
/// bytes. Imported entries carry [publicKey] as well, since the file has it,
/// but verification only ever compares fingerprints.
@freezed
abstract class KnownHost with _$KnownHost {
  /// Creates a known host entry.
  const factory({
    required String host,
    required int port,
    required String keyType,

    /// OpenSSH-style fingerprint, e.g. `SHA256:SoUNE+BPf...`.
    required String fingerprint,
    required DateTime addedAt,
    required KnownHostSource source,

    /// The base64 key blob, when known. Present for imported entries only.
    String? publicKey,
  }) = _KnownHost;

  const new _();

  /// Restores an entry from stored JSON.
  factory fromJson(Map<String, dynamic> json) => _$KnownHostFromJson(json);

  /// How the host is written in a `known_hosts` file: bare for port 22,
  /// bracketed otherwise.
  String get hostPort => port == 22 ? host : '[$host]:$port';

  /// Whether this entry describes the same host, port and key type as [other].
  bool describesSameKeyAs(KnownHost other) =>
      host == other.host && port == other.port && keyType == other.keyType;
}
