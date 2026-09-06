import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/infrastructure/ssh/sockets/websocket_ssh_socket.dart';
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

part 'socket_factory_provider.g.dart';

/// How SSH reaches a server on this platform.
///
/// A direct TCP socket everywhere except the web, where browsers cannot open
/// one and the connection goes through a relay instead. Choosing here rather
/// than inside the backend is what keeps the web from needing a backend of its
/// own: the SSH protocol, and every security decision in it, is identical
/// either way.
@Riverpod(keepAlive: true)
SshSocketFactory sshSocketFactory(Ref ref) {
  final capabilities = ref.watch(platformCapabilitiesProvider);
  if (!capabilities.needsRelay) return connectTcpSocket;

  final configured = ref.watch(currentSettingsProvider).relayUrl;

  return (host, port, {timeout}) async {
    if (configured == null || configured.isEmpty) {
      throw const TerminalBackendFailure(
        TerminalBackendFailureKind.unsupported,
        'A browser cannot open a network connection directly. Set a relay '
        'address in Settings to connect over SSH.',
      );
    }

    final url = Uri.tryParse(configured);
    if (url == null || !url.isScheme('ws') && !url.isScheme('wss')) {
      throw const TerminalBackendFailure(
        TerminalBackendFailureKind.unsupported,
        'The relay address must be a ws:// or wss:// URL.',
      );
    }

    try {
      return await WebSocketSshSocket.connect(
        url,
        host: host,
        port: port,
        timeout: timeout,
      );
    } on TerminalBackendFailure {
      rethrow;
    } on Object catch (error) {
      throw TerminalBackendFailure(
        TerminalBackendFailureKind.network,
        'The relay at ${url.host} could not be reached, or it refused to '
        'connect to $host:$port.',
        cause: error,
      );
    }
  };
}
