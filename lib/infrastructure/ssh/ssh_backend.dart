import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/backends/terminal_backend_base.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_connection_factory.dart';
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

/// An interactive SSH shell.
///
/// Owns one `SSHClient`, plus one more for every hop in a `ProxyJump` chain,
/// and closes all of them together.
class SshBackend extends TerminalBackendBase {
  /// Creates a backend for [host].
  new({
    required this.host,
    required this.verifier,
    required this.onHostKeyPrompt,
    this.prompts = const SshAuthPrompts(),
    this.socketFactory = connectTcpSocket,
    this.jumpChain = const [],
    this.jumpPrompts = const {},
    this.columns = 80,
    this.rows = 24,
    this.connectTimeout = const Duration(seconds: 20),
  });

  /// The connection to open.
  final SshHost host;

  /// Decides whether the server's key is trusted.
  final HostKeyVerifier verifier;

  /// Asks the user about an unrecognised key.
  final HostKeyPrompt onHostKeyPrompt;

  /// Credentials and interactive callbacks for [host].
  final SshAuthPrompts prompts;

  /// Opens the transport. Swapped for a WebSocket on the web.
  final SshSocketFactory socketFactory;

  /// Hosts to tunnel through, nearest first — OpenSSH's `ProxyJump`.
  ///
  /// Each is connected in turn, and the next hop is dialled through a channel
  /// on the previous one, so the final server is reached without any hop
  /// seeing more than the ciphertext passing through it.
  final List<SshHost> jumpChain;

  /// Credentials for each jump host, by host id.
  final Map<String, SshAuthPrompts> jumpPrompts;

  /// Initial terminal width in cells.
  final int columns;

  /// Initial terminal height in cells.
  final int rows;

  /// How long to wait for the TCP connection.
  final Duration connectTimeout;

  SshConnection? _connection;
  SSHSession? _session;

  /// Set when host key verification refuses a connection, so the failure can
  /// say *why* rather than surfacing a generic handshake error.
  HostKeyCheck? _refusedCheck;

  /// How long a round trip to the server takes, or null when it has not been
  /// measured or the connection is not up.
  ///
  /// Measured with the protocol's own keepalive request, which the server must
  /// answer and which carries no payload — so this is the connection's latency
  /// rather than the latency of running something on the far end.
  Future<Duration?> measureLatency() async {
    final client = _connection?.client;
    if (client == null || state != BackendConnectionState.connected) {
      return null;
    }

    final clock = Stopwatch()..start();
    try {
      await client.ping().timeout(const Duration(seconds: 5));
    } on Object {
      // A ping that fails tells us nothing useful on its own — the state
      // machine already reports a dropped connection — so it reads as
      // "unknown" rather than as an error of its own.
      return null;
    }
    return clock.elapsed;
  }

  /// The host key check that refused this connection, if one did.
  ///
  /// The mismatch dialog needs both fingerprints to show side by side, and
  /// reconstructing them from storage would show the stored key twice. This
  /// carries the key the server actually offered.
  HostKeyCheck? get refusedHostKey => _refusedCheck;

  /// The exit status arrives separately from the output stream, exactly as it
  /// does for a local PTY.
  @override
  void handleOutputDone() {
    if (!state.isTerminal) setClosed(_session?.exitCode);
  }

  @override
  Future<void> connect() async {
    try {
      final factory = SshConnectionFactory(
        verifier: verifier,
        onHostKeyPrompt: onHostKeyPrompt,
        socketFactory: socketFactory,
        connectTimeout: connectTimeout,
      );

      final connection = await factory.connect(
        host: host,
        prompts: prompts,
        jumpChain: jumpChain,
        jumpPrompts: jumpPrompts,
        refused: (check) => _refusedCheck = check,
      );
      _connection = connection;

      final session = await connection.client.shell(
        pty: SSHPtyConfig(
          width: columns,
          height: rows,
          // dartssh2 already defaults to xterm-256color; naming it here would
          // be redundant. Announcing a capable terminal is what makes vim and
          // htop behave, so this is worth knowing rather than assuming.
        ),
      );
      _session = session;

      // stderr and stdout are one stream to a terminal: a pty does not
      // separate them, and interleaving them here matches what a real
      // terminal shows.
      pipeOutput(_mergeStreams(session.stdout, session.stderr));

      final startup = host.startupCommand;
      if (startup != null && startup.trim().isNotEmpty) {
        session.write(Uint8List.fromList(utf8.encode('$startup\n')));
      }

      unawaited(
        session.done.then(
          (_) => setClosed(session.exitCode),
          onError: (Object _) => setClosed(session.exitCode),
        ),
      );
    } on TerminalBackendFailure {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
  }

  static Stream<Uint8List> _mergeStreams(
    Stream<Uint8List> first,
    Stream<Uint8List> second,
  ) {
    final controller = StreamController<Uint8List>();
    var open = 2;

    void closeOne() {
      if (--open == 0) unawaited(controller.close());
    }

    // Subscriptions are bound to the controller's lifetime; cancelling the
    // output subscription cancels these through onCancel below.
    final subscriptions = [
      first.listen(
        controller.add,
        onError: controller.addError,
        onDone: closeOne,
      ),
      second.listen(
        controller.add,
        onError: controller.addError,
        onDone: closeOne,
      ),
    ];

    controller
      ..onPause = () {
        for (final subscription in subscriptions) {
          subscription.pause();
        }
      }
      ..onResume = () {
        for (final subscription in subscriptions) {
          subscription.resume();
        }
      }
      ..onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };

    return controller.stream;
  }

  /// Delegates to the shared mapper so that a failure reads the same here as
  /// it does in the file browser or a port forward.
  TerminalBackendFailure _mapError(Object error) =>
      mapSshFailure(error, host: host, refused: _refusedCheck);

  @override
  void send(Uint8List data) => _session?.write(data);

  @override
  void resize(
    int columns,
    int rows, {
    int pixelWidth = 0,
    int pixelHeight = 0,
  }) => _session?.resizeTerminal(columns, rows, pixelWidth, pixelHeight);

  @override
  Future<void> disconnect() async {
    _session?.close();
    _session = null;
    await _connection?.close();
    _connection = null;
  }
}
