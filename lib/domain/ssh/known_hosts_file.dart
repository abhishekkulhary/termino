import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart' show KeyParameter;
import 'package:pointycastle/digests/sha1.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:termino/domain/entities/known_host.dart';

/// One line of an OpenSSH `known_hosts` file, parsed.
class KnownHostsEntry {
  /// Creates a parsed entry.
  const new({
    required this.patterns,
    required this.keyType,
    required this.publicKey,
    required this.fingerprint,
    this.isHashed = false,
    this.marker,
    this.comment,
  });

  /// The host patterns this line applies to, exactly as written.
  ///
  /// For a hashed line this holds the single `|1|salt|hash` token; use
  /// [matchesHost] rather than reading it.
  final List<String> patterns;

  /// The key type, e.g. `ssh-ed25519`.
  final String keyType;

  /// The base64 key blob.
  final String publicKey;

  /// OpenSSH-style `SHA256:...` fingerprint of the key.
  final String fingerprint;

  /// Whether the host names on this line are hashed (`HashKnownHosts yes`).
  final bool isHashed;

  /// `@cert-authority` or `@revoked`, when present.
  final String? marker;

  /// Trailing comment, if any.
  final String? comment;

  /// Whether this line applies to [host] on [port].
  ///
  /// Handles the three forms OpenSSH writes: a bare hostname, a `[host]:port`
  /// form for non-default ports, and a hashed `|1|salt|hash` token. Negated
  /// patterns (`!host`) exclude a match, as OpenSSH defines them.
  bool matchesHost(String host, int port) {
    final candidates = port == 22 ? [host, '[$host]:$port'] : ['[$host]:$port'];

    if (isHashed) {
      return patterns.any(
        (pattern) => candidates.any(
          (candidate) => _matchesHashedPattern(pattern, candidate),
        ),
      );
    }

    var matched = false;
    for (final pattern in patterns) {
      final negated = pattern.startsWith('!');
      final bare = negated ? pattern.substring(1) : pattern;
      final hit = candidates.any((candidate) => _matchesGlob(bare, candidate));
      if (hit) {
        if (negated) return false;
        matched = true;
      }
    }
    return matched;
  }

  /// Converts this line into a stored entry for [host] on [port].
  KnownHost toKnownHost({
    required String host,
    required int port,
    DateTime? addedAt,
  }) => KnownHost(
    host: host,
    port: port,
    keyType: keyType,
    fingerprint: fingerprint,
    publicKey: publicKey,
    addedAt: addedAt ?? DateTime.now(),
    source: KnownHostSource.imported,
  );

  /// The literal host names on this line, when they are not hashed.
  ///
  /// Hashed lines return nothing: the whole point of hashing is that the names
  /// cannot be recovered, which means such lines can only be imported for a
  /// host the user names explicitly.
  List<String> get literalHosts {
    if (isHashed) return const [];
    return patterns
        .where((pattern) => !pattern.startsWith('!') && !pattern.contains('*'))
        .where((pattern) => !pattern.contains('?'))
        .toList(growable: false);
  }
}

/// Reads OpenSSH `known_hosts` files.
abstract final class KnownHostsFile {
  /// Parses [contents], skipping blank lines, comments and unparseable lines.
  ///
  /// A malformed line is skipped rather than throwing: these files are edited
  /// by hand and by many tools, and one bad line must not cost the user the
  /// rest of their trusted hosts.
  static List<KnownHostsEntry> parse(String contents) {
    final entries = <KnownHostsEntry>[];

    for (final rawLine in const LineSplitter().convert(contents)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      var fields = line.split(RegExp(r'\s+'));
      String? marker;

      if (fields.first.startsWith('@')) {
        marker = fields.first;
        fields = fields.sublist(1);
      }

      // hosts, key-type, base64 key, then an optional comment.
      if (fields.length < 3) continue;

      final hosts = fields[0];
      final keyType = fields[1];
      final publicKey = fields[2];
      final comment = fields.length > 3 ? fields.sublist(3).join(' ') : null;

      final Uint8List keyBytes;
      try {
        keyBytes = base64.decode(publicKey);
      } on FormatException {
        continue;
      }
      if (keyBytes.isEmpty) continue;

      entries.add(
        KnownHostsEntry(
          patterns: hosts.split(','),
          keyType: keyType,
          publicKey: publicKey,
          fingerprint: fingerprintOf(keyBytes),
          isHashed: hosts.startsWith('|1|'),
          marker: marker,
          comment: comment,
        ),
      );
    }

    return entries;
  }

  /// The OpenSSH-style fingerprint of a raw public key blob.
  ///
  /// Matches what `ssh-keygen -lf` prints and what `dartssh2` hands the host
  /// key callback: SHA-256, base64, without padding, prefixed `SHA256:`.
  static String fingerprintOf(Uint8List keyBlob) {
    final digest = SHA256Digest().process(keyBlob);
    return 'SHA256:${base64.encode(digest).replaceAll('=', '')}';
  }
}

/// Matches an OpenSSH hashed host token, `|1|<base64 salt>|<base64 hash>`.
///
/// The hash is HMAC-SHA1 of the host name keyed by the salt, which is how
/// OpenSSH lets a file be checked for a host without revealing which hosts it
/// contains.
bool _matchesHashedPattern(String pattern, String host) {
  final parts = pattern.split('|');
  // ['', '1', salt, hash]
  if (parts.length != 4 || parts[1] != '1') return false;

  final Uint8List salt;
  final Uint8List expected;
  try {
    salt = base64.decode(parts[2]);
    expected = base64.decode(parts[3]);
  } on FormatException {
    return false;
  }

  final mac = HMac(SHA1Digest(), 64)..init(KeyParameter(salt));
  final actual = mac.process(Uint8List.fromList(utf8.encode(host)));

  if (actual.length != expected.length) return false;
  var difference = 0;
  for (var i = 0; i < actual.length; i++) {
    difference |= actual[i] ^ expected[i];
  }
  return difference == 0;
}

/// Matches OpenSSH's `*` and `?` host patterns.
bool _matchesGlob(String pattern, String host) {
  if (!pattern.contains('*') && !pattern.contains('?')) {
    return pattern.toLowerCase() == host.toLowerCase();
  }

  final expression = StringBuffer('^');
  for (final rune in pattern.runes) {
    final char = String.fromCharCode(rune);
    switch (char) {
      case '*':
        expression.write('.*');
      case '?':
        expression.write('.');
      default:
        expression.write(RegExp.escape(char));
    }
  }
  expression.write(r'$');

  return RegExp(expression.toString(), caseSensitive: false).hasMatch(host);
}
