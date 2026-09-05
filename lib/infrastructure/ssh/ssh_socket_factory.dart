import 'package:dartssh2/dartssh2.dart';

/// Opens the transport an SSH session runs over.
///
/// This is the seam that makes the web build possible without a second
/// backend. `dartssh2` runs the SSH protocol itself over whatever socket it is
/// given, so a browser only needs a different socket — a WebSocket to a relay —
/// and everything above it, including host key verification, is unchanged.
///
/// The consequence is worth stating: because SSH still runs on the user's
/// device, the relay carries ciphertext only. It never sees a password, a
/// private key or a keystroke, and it cannot impersonate a host.
typedef SshSocketFactory = Future<SSHSocket> Function(
  String host,
  int port, {
  Duration? timeout,
});

/// The default factory: a real TCP socket.
///
/// Throws `UnsupportedError` on the web, where browsers cannot open raw TCP
/// sockets. `PlatformCapabilities` prevents that from being reached.
Future<SSHSocket> connectTcpSocket(
  String host,
  int port, {
  Duration? timeout,
}) => SSHSocket.connect(host, port, timeout: timeout);
