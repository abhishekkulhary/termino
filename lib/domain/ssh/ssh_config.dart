import 'dart:convert';

/// One `Host` block from an OpenSSH client configuration.
class SshConfigHost {
  /// Creates a resolved host block.
  const new({
    required this.patterns,
    this.hostName,
    this.user,
    this.port,
    this.identityFiles = const [],
    this.proxyJump,
    this.serverAliveInterval,
    this.forwardAgent,
    this.remoteCommand,
  });

  /// The patterns after the `Host` keyword, e.g. `['build-*', 'ci']`.
  final List<String> patterns;

  /// `HostName` — the address to actually connect to.
  final String? hostName;

  /// `User`.
  final String? user;

  /// `Port`.
  final int? port;

  /// `IdentityFile`, in the order given. OpenSSH allows several.
  final List<String> identityFiles;

  /// `ProxyJump`.
  final String? proxyJump;

  /// `ServerAliveInterval`, in seconds.
  final int? serverAliveInterval;

  /// `ForwardAgent`.
  final bool? forwardAgent;

  /// `RemoteCommand`.
  final String? remoteCommand;

  /// Whether this block is a literal name rather than a pattern, and so worth
  /// offering as an importable host.
  bool get isImportable =>
      patterns.length == 1 &&
      !patterns.first.contains('*') &&
      !patterns.first.contains('?') &&
      !patterns.first.startsWith('!');

  /// The name to show, which is the alias the user types.
  String get alias => patterns.first;

  /// Merges [other] beneath this block: values already set here win, matching
  /// OpenSSH, where the first occurrence of a keyword takes effect.
  SshConfigHost mergeUnder(SshConfigHost other) => SshConfigHost(
    patterns: patterns,
    hostName: hostName ?? other.hostName,
    user: user ?? other.user,
    port: port ?? other.port,
    identityFiles: identityFiles.isNotEmpty
        ? identityFiles
        : other.identityFiles,
    proxyJump: proxyJump ?? other.proxyJump,
    serverAliveInterval: serverAliveInterval ?? other.serverAliveInterval,
    forwardAgent: forwardAgent ?? other.forwardAgent,
    remoteCommand: remoteCommand ?? other.remoteCommand,
  );
}

/// Reads an OpenSSH client configuration file.
///
/// Deliberately partial. It understands the keywords Termino can act on and
/// ignores the rest, because a config full of `SendEnv` and `ControlMaster`
/// should still yield its hosts rather than failing to parse. `Include` is not
/// followed — resolving it needs a filesystem, which the domain layer does not
/// have; the importer in the infrastructure layer handles that.
abstract final class SshConfig {
  /// Parses [contents] into its `Host` blocks, in file order.
  static List<SshConfigHost> parse(String contents) {
    final hosts = <SshConfigHost>[];

    List<String>? patterns;
    String? hostName;
    String? user;
    int? port;
    var identityFiles = <String>[];
    String? proxyJump;
    int? serverAliveInterval;
    bool? forwardAgent;
    String? remoteCommand;

    void flush() {
      // Even with no open Host block the accumulators must be cleared:
      // a Match block's settings would otherwise leak into whatever Host
      // block comes after it.
      if (patterns != null) {
        hosts.add(
          SshConfigHost(
            patterns: patterns!,
            hostName: hostName,
            user: user,
            port: port,
            identityFiles: identityFiles,
            proxyJump: proxyJump,
            serverAliveInterval: serverAliveInterval,
            forwardAgent: forwardAgent,
            remoteCommand: remoteCommand,
          ),
        );
      }
      patterns = null;
      hostName = null;
      user = null;
      port = null;
      identityFiles = <String>[];
      proxyJump = null;
      serverAliveInterval = null;
      forwardAgent = null;
      remoteCommand = null;
    }

    for (final rawLine in const LineSplitter().convert(contents)) {
      final line = _stripComment(rawLine).trim();
      if (line.isEmpty) continue;

      final (keyword, value) = _splitKeyword(line);
      if (value == null || value.isEmpty) continue;

      switch (keyword.toLowerCase()) {
        case 'host':
          flush();
          patterns = value.split(RegExp(r'\s+'));
        case 'match':
          // Match blocks are conditional in ways we cannot evaluate without a
          // live connection. End the current block so its settings do not leak
          // into whatever follows.
          flush();
        case 'hostname':
          hostName = value;
        case 'user':
          user = value;
        case 'port':
          port = int.tryParse(value);
        case 'identityfile':
          identityFiles = [...identityFiles, _stripQuotes(value)];
        case 'proxyjump':
          proxyJump = value;
        case 'serveraliveinterval':
          serverAliveInterval = int.tryParse(value);
        case 'forwardagent':
          forwardAgent = _parseBool(value);
        case 'remotecommand':
          remoteCommand = value;
      }
    }

    flush();
    return hosts;
  }

  /// Resolves the effective settings for [alias], applying every matching
  /// block in file order the way OpenSSH does.
  static SshConfigHost? resolve(List<SshConfigHost> hosts, String alias) {
    SshConfigHost? result;

    for (final host in hosts) {
      if (!_matchesAny(host.patterns, alias)) continue;
      result = result == null
          ? SshConfigHost(
              patterns: [alias],
              hostName: host.hostName,
              user: host.user,
              port: host.port,
              identityFiles: host.identityFiles,
              proxyJump: host.proxyJump,
              serverAliveInterval: host.serverAliveInterval,
              forwardAgent: host.forwardAgent,
              remoteCommand: host.remoteCommand,
            )
          : result.mergeUnder(host);
    }

    return result;
  }

  static bool _matchesAny(List<String> patterns, String alias) {
    var matched = false;
    for (final pattern in patterns) {
      final negated = pattern.startsWith('!');
      final bare = negated ? pattern.substring(1) : pattern;
      if (!_matchesGlob(bare, alias)) continue;
      if (negated) return false;
      matched = true;
    }
    return matched;
  }

  static bool _matchesGlob(String pattern, String value) {
    if (!pattern.contains('*') && !pattern.contains('?')) {
      return pattern.toLowerCase() == value.toLowerCase();
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
    return RegExp(expression.toString(), caseSensitive: false).hasMatch(value);
  }

  /// Splits `Keyword value` or `Keyword=value`, which OpenSSH both accept.
  static (String, String?) _splitKeyword(String line) {
    final equals = line.indexOf('=');
    final space = line.indexOf(RegExp(r'\s'));

    if (equals >= 0 && (space < 0 || equals < space)) {
      return (
        line.substring(0, equals).trim(),
        line.substring(equals + 1).trim(),
      );
    }
    if (space < 0) return (line, null);
    return (line.substring(0, space), line.substring(space + 1).trim());
  }

  static String _stripComment(String line) {
    final index = line.indexOf('#');
    return index < 0 ? line : line.substring(0, index);
  }

  static String _stripQuotes(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static bool? _parseBool(String value) => switch (value.toLowerCase()) {
    'yes' || 'true' => true,
    'no' || 'false' => false,
    _ => null,
  };
}
