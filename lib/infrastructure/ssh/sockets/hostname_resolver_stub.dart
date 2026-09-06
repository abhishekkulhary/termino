/// Hands [host] back unchanged.
///
/// On the web the connection goes to a relay, which resolves the name on its
/// own side of the tunnel.
Future<String> resolveHostname(
  String host, {
  Duration timeout = const Duration(seconds: 4),
}) async => host;
