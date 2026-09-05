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
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

/// Asks the user whether to trust a host key they have not seen before.
///
/// Returning false refuses the connection. This is never called for a
/// mismatch: that is refused outright, without offering the user a button.
typedef HostKeyPrompt = Future<bool> Function(HostKeyCheck check);

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

  final List<SSHClient> _clients = [];
  SSHSession? _session;

  /// Set when host key verification refuses a connection, so the failure can
  /// say *why* rather than surfacing a generic handshake error.
  HostKeyCheck? _refusedCheck;

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
      final client = await _connectThroughJumps();
      _clients.add(client);

      final session = await client.shell(
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

  /// Connects each hop in turn, dialling the next through the previous.
  Future<SSHClient> _connectThroughJumps() async {
    SSHClient? previous;

    for (final hop in jumpChain) {
      final socket = previous == null
          ? await _openSocket(hop.hostname, hop.port)
          : await previous.forwardLocal(hop.hostname, hop.port);
      final client = await _authenticate(
        socket: socket,
        target: hop,
        prompts: jumpPrompts[hop.id] ?? const SshAuthPrompts(),
      );
      _clients.add(client);
      previous = client;
    }

    final socket = previous == null
        ? await _openSocket(host.hostname, host.port)
        : await previous.forwardLocal(host.hostname, host.port);

    return await _authenticate(socket: socket, target: host, prompts: prompts);
  }

  Future<SSHSocket> _openSocket(String hostname, int port) async {
    try {
      return await socketFactory(hostname, port, timeout: connectTimeout);
    } on Object catch (error) {
      throw TerminalBackendFailure(
        TerminalBackendFailureKind.network,
        '$hostname:$port could not be reached.',
        cause: error,
      );
    }
  }

  Future<SSHClient> _authenticate({
    required SSHSocket socket,
    required SshHost target,
    required SshAuthPrompts prompts,
  }) async {
    final client = SSHClient(
      socket,
      username: target.username,
      identities: prompts.identities,
      onPasswordRequest: prompts.onPasswordRequest,
      onUserInfoRequest: prompts.onUserInfoRequest,
      onUserauthBanner: prompts.onBanner,
      agentHandler: prompts.agent,
      keepAliveInterval: target.keepAliveInterval,
      onVerifyHostKey: (type, fingerprint) =>
          _verifyHostKey(target, type, fingerprint),
    );

    await client.authenticated;
    return client;
  }

  /// The gate every connection passes through.
  Future<bool> _verifyHostKey(
    SshHost target,
    String keyType,
    Uint8List fingerprintBytes,
  ) async {
    // dartssh2 hands us the OpenSSH-style `SHA256:...` text, UTF-8 encoded.
    final fingerprint = utf8.decode(fingerprintBytes);

    final check = await verifier.check(
      host: target.hostname,
      port: target.port,
      keyType: keyType,
      fingerprint: fingerprint,
    );

    if (check.verdict.isAutomaticallyTrusted) return true;

    // A changed key is refused here and now. The user is never shown a
    // "connect anyway" button in the connection path; replacing a known key is
    // a separate, deliberate action taken from the mismatch dialog, and it
    // requires starting a new connection afterwards.
    if (check.verdict.blocksConnection) {
      _refusedCheck = check;
      return false;
    }

    final accepted = await onHostKeyPrompt(check);
    if (!accepted) {
      _refusedCheck = check;
      return false;
    }

    await verifier.trust(check);
    return true;
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

  TerminalBackendFailure _mapError(Object error) {
    final refused = _refusedCheck;
    if (refused != null) {
      return TerminalBackendFailure(
        refused.verdict == HostKeyVerdict.mismatch
            ? TerminalBackendFailureKind.hostKeyMismatch
            : TerminalBackendFailureKind.authentication,
        refused.verdict == HostKeyVerdict.mismatch
            ? 'The host key for ${refused.target} has changed. '
                  'The connection was refused.'
            : 'The host key for ${refused.target} was not accepted.',
        cause: error,
      );
    }

    return switch (error) {
      SSHAuthFailError() || SSHAuthAbortError() => TerminalBackendFailure(
        TerminalBackendFailureKind.authentication,
        'Authentication to ${host.target} failed.',
        cause: error,
      ),
      SSHHostkeyError() => TerminalBackendFailure(
        TerminalBackendFailureKind.hostKeyMismatch,
        'The host key for ${host.hostname} could not be verified.',
        cause: error,
      ),
      SSHSocketError() => TerminalBackendFailure(
        TerminalBackendFailureKind.network,
        '${host.hostname}:${host.port} could not be reached.',
        cause: error,
      ),
      SSHDisconnectError() => TerminalBackendFailure(
        TerminalBackendFailureKind.disconnected,
        '${host.hostname} closed the connection.',
        cause: error,
      ),
      _ => TerminalBackendFailure(
        TerminalBackendFailureKind.unknown,
        'The connection to ${host.hostname} failed.',
        cause: error,
      ),
    };
  }

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
    // Innermost first, so each hop is torn down before the tunnel carrying it.
    for (final client in _clients.reversed) {
      await client.close();
    }
    _clients.clear();
  }
}
