/// Which hosts and ports the relay is willing to connect to.
///
/// This is the most important part of the relay, and the reason it refuses to
/// start without one. A WebSocket-to-TCP bridge that accepts any destination is
/// an **open proxy**: anyone who learns the URL can reach anything the relay's
/// network can reach, from the relay's IP address, including hosts behind a
/// firewall that trusts it. That is a far more serious exposure than the SSH
/// traffic it was deployed to carry.
class Allowlist {
  /// Creates an allowlist from parsed [entries].
  const new(this.entries);

  /// Parses entries of the form `host` or `host:port`.
  ///
  /// A bare host allows only port 22, because a rule written without a port is
  /// almost always meant to say "the SSH server on that machine" — and if it
  /// silently meant every port, a typo would open one.
  factory parse(Iterable<String> specs) {
    final entries = <AllowedDestination>[];

    for (final raw in specs) {
      final spec = raw.trim();
      if (spec.isEmpty) continue;

      final separator = spec.lastIndexOf(':');
      if (separator < 0) {
        entries.add(AllowedDestination(host: spec, port: 22));
        continue;
      }

      final port = int.tryParse(spec.substring(separator + 1));
      if (port == null || port < 1 || port > 65535) {
        throw FormatException('Not a valid host:port entry', spec);
      }
      entries.add(
        AllowedDestination(host: spec.substring(0, separator), port: port),
      );
    }

    return Allowlist(entries);
  }

  /// The destinations that may be reached.
  final List<AllowedDestination> entries;

  /// Whether anything is allowed at all.
  bool get isEmpty => entries.isEmpty;

  /// Whether [host] on [port] may be connected to.
  bool allows(String host, int port) =>
      entries.any((entry) => entry.matches(host, port));

  @override
  String toString() => entries.map((e) => '${e.host}:${e.port}').join(', ');
}

/// One permitted destination.
class AllowedDestination {
  /// Creates a destination rule.
  const new({required this.host, required this.port});

  /// The host, which may begin with `*.` to allow a single subdomain level.
  final String host;

  /// The port.
  final int port;

  /// Whether this rule permits [candidate] on [candidatePort].
  bool matches(String candidate, int candidatePort) {
    if (candidatePort != port) return false;

    final wanted = candidate.toLowerCase();
    final rule = host.toLowerCase();

    if (!rule.startsWith('*.')) return rule == wanted;

    // `*.example.com` matches `a.example.com` but deliberately not
    // `example.com` itself, nor `a.b.example.com`: a wildcard that spans dots
    // is how an allowlist stops meaning anything.
    final suffix = rule.substring(1);
    if (!wanted.endsWith(suffix)) return false;
    final prefix = wanted.substring(0, wanted.length - suffix.length);
    return prefix.isNotEmpty && !prefix.contains('.');
  }
}
