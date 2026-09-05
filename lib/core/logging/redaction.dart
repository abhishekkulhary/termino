/// Removes secrets from text before it can reach a log, a crash report or the
/// screen.
///
/// The rule this enforces is from SECURITY.md: passwords, passphrases, private
/// key material, authentication banners and the session byte stream must never
/// be written anywhere durable. Redaction is the last line of defence — the
/// first is not passing secrets to the logger at all — but it is the one that
/// can be tested, and it is tested.
///
/// The approach is deliberately conservative. It is far better to redact
/// something harmless than to leak a key, so patterns err towards matching too
/// much, and anything registered with [registerSecret] is removed verbatim
/// wherever it appears.
class Redactor {
  /// Creates a redactor.
  new();

  /// The placeholder written in place of anything removed.
  static const placeholder = '<redacted>';

  final Set<String> _secrets = {};

  /// Registers a literal secret to strip from every message.
  ///
  /// Call this whenever a password or passphrase enters memory, so that if it
  /// is later interpolated into a message by mistake — an exception's
  /// `toString`, say — it is still removed. Values shorter than four
  /// characters are ignored: they would match constantly and turn logs into
  /// noise without protecting anything meaningful.
  void registerSecret(String? secret) {
    if (secret == null || secret.length < 4) return;
    _secrets.add(secret);
  }

  /// Forgets a registered secret, once it is no longer in use.
  void forgetSecret(String? secret) {
    if (secret == null) return;
    _secrets.remove(secret);
  }

  /// Forgets every registered secret.
  void clear() => _secrets.clear();

  /// Returns [message] with every recognised secret replaced.
  String redact(String message) {
    var result = message;

    // Literal secrets first: they are the ones we know for certain.
    for (final secret in _secrets) {
      result = result.replaceAll(secret, placeholder);
    }

    for (final pattern in _patterns) {
      result = result.replaceAllMapped(
        pattern.expression,
        (match) => pattern.replace(match as RegExpMatch),
      );
    }

    return result;
  }

  static final List<_RedactionPattern> _patterns = [
    // A PEM block, however it is labelled. Matched first and greedily so that
    // no fragment of key material survives.
    _RedactionPattern(
      RegExp(
        '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----'
        r'[\s\S]*?'
        '-----END [A-Z0-9 ]*PRIVATE KEY-----',
        multiLine: true,
      ),
      (match) =>
          '-----BEGIN PRIVATE KEY----- $placeholder '
          '-----END PRIVATE KEY-----',
    ),
    // An unterminated PEM block — a truncated log is still a leak.
    _RedactionPattern(
      RegExp(r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*'),
      (match) => '-----BEGIN PRIVATE KEY----- $placeholder',
    ),
    // `password=hunter2`, `passphrase: hunter2`, `"secret" : "hunter2"`, and
    // the same with token/apikey/authorization.
    _RedactionPattern(
      RegExp(
        r'''(?<key>"?\b(?:password|passphrase|passwd|secret|token|api[_-]?key|authorization|auth)"?\s*[:=]\s*)(?<value>"[^"]*"|'[^']*'|\S+)''',
        caseSensitive: false,
      ),
      (match) => '${match.namedGroup('key')}$placeholder',
    ),
    // A URL with credentials in it: ssh://user:secret@host.
    _RedactionPattern(
      RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://[^\s:/@]+):([^\s@]+)@'),
      (match) => '${match.group(1)}:$placeholder@',
    ),
    // An OpenSSH public-key blob. Not secret itself, but it identifies a user
    // across logs, and nothing needs it at debug level.
    _RedactionPattern(
      RegExp(
        r'\b(ssh-(?:rsa|ed25519|dss)|ecdsa-sha2-nistp\d+)\s+[A-Za-z0-9+/=]{20,}',
      ),
      (match) => '${match.group(1)} $placeholder',
    ),
  ];
}

class _RedactionPattern {
  const new(this.expression, this.replace);

  final RegExp expression;
  final String Function(RegExpMatch match) replace;
}
