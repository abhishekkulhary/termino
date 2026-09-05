import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/repositories/known_hosts_repository.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';

/// Decides whether a host key may be trusted.
///
/// This is the single most security-critical piece of logic in the app, so it
/// is pure, has no dependency on Flutter or on the SSH library, and is tested
/// exhaustively. The rules, in order:
///
/// 1. A key of this type is on record and matches → **trusted**.
/// 2. A key of this type is on record and does not match → **mismatch**. The
///    connection is refused. This is never softened into a prompt the user can
///    click through: a changed key means either the server was rebuilt or
///    someone is intercepting the connection, and nothing available here can
///    tell those apart.
/// 3. Nothing at all is on record → **unknown**, and the user is asked
///    (trust on first use).
/// 4. The host is known but only by other key types → **new key type**, and
///    the user is asked, having been told the host is otherwise familiar.
class HostKeyVerifier {
  /// Creates a verifier backed by a known-hosts store.
  const new(this._repository);

  final KnownHostsRepository _repository;

  /// Checks the key the server offered for [host] on [port].
  Future<HostKeyCheck> check({
    required String host,
    required int port,
    required String keyType,
    required String fingerprint,
  }) async {
    final entries = await _repository.forHost(host: host, port: port);

    final sameType = entries
        .where((entry) => entry.keyType == keyType)
        .toList(growable: false);

    if (sameType.isNotEmpty) {
      final match = sameType.where(
        (entry) => _constantTimeEquals(entry.fingerprint, fingerprint),
      );

      if (match.isNotEmpty) {
        return HostKeyCheck(
          verdict: HostKeyVerdict.trusted,
          host: host,
          port: port,
          keyType: keyType,
          fingerprint: fingerprint,
          expected: match.first,
        );
      }

      return HostKeyCheck(
        verdict: HostKeyVerdict.mismatch,
        host: host,
        port: port,
        keyType: keyType,
        fingerprint: fingerprint,
        expected: sameType.first,
      );
    }

    if (entries.isNotEmpty) {
      return HostKeyCheck(
        verdict: HostKeyVerdict.newKeyType,
        host: host,
        port: port,
        keyType: keyType,
        fingerprint: fingerprint,
        otherKnownTypes: entries
            .map((entry) => entry.keyType)
            .toSet()
            .toList(growable: false),
      );
    }

    return HostKeyCheck(
      verdict: HostKeyVerdict.unknown,
      host: host,
      port: port,
      keyType: keyType,
      fingerprint: fingerprint,
    );
  }

  /// Records [check]'s key as trusted, after the user accepted it.
  ///
  /// Refuses to record a mismatch. Overwriting a known key is how a user gets
  /// silently downgraded into trusting an impostor, so replacing an existing
  /// key is a separate, deliberate act — [KnownHostsRepository.replace] —
  /// reached only from the mismatch dialog.
  Future<KnownHost> trust(HostKeyCheck check) async {
    if (check.verdict.blocksConnection) {
      throw StateError(
        'Refusing to trust a mismatched host key for ${check.target}. '
        'Use KnownHostsRepository.replace after an explicit user decision.',
      );
    }

    final entry = KnownHost(
      host: check.host,
      port: check.port,
      keyType: check.keyType,
      fingerprint: check.fingerprint,
      addedAt: DateTime.now(),
      source: KnownHostSource.trustOnFirstUse,
    );
    await _repository.add(entry);
    return entry;
  }

  /// Compares two fingerprints without leaking their contents through timing.
  ///
  /// A fingerprint is public information, so this is belt and braces rather
  /// than strictly necessary — but comparison of security tokens is exactly
  /// the place where a habit of using `==` eventually costs something.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
