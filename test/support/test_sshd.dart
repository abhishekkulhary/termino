import 'dart:io';

/// A throwaway OpenSSH server for integration tests.
///
/// The plan called for a Docker container, but `sshd` turns out to run
/// perfectly well unprivileged on a high port, authenticating the user who
/// started it. That is faster, needs no daemon installed, and — most
/// importantly — means these tests actually run on a developer's machine
/// rather than only in CI.
///
/// Everything it uses lives in a temporary directory and is deleted on
/// [stop]. The keys come from `test/fixtures/keys`, which are generated for
/// testing and valid for nothing else.
class TestSshd {
  new _(this._process, this.port, this._directory);

  /// The port the server is listening on.
  final int port;

  final Process _process;
  final Directory _directory;

  static final Map<int, StringBuffer> _logs = {};

  /// What the server has logged so far. For diagnosing a failing test.
  String get log => _logs[_process.pid]?.toString() ?? '';

  /// The account the server authenticates, which is whoever runs the tests.
  static String get username =>
      Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? '';

  /// Where the fixture keys live, relative to the package root.
  static const fixtures = 'test/fixtures/keys';

  /// Where OpenSSH keeps its SFTP server, which differs between systems.
  static String get sftpServer {
    for (final candidate in [
      '/usr/libexec/sftp-server',
      '/usr/lib/openssh/sftp-server',
      '/usr/lib/ssh/sftp-server',
    ]) {
      if (File(candidate).existsSync()) return candidate;
    }
    return 'internal-sftp';
  }

  /// Whether this platform can run the harness at all.
  static bool get isSupported =>
      !Platform.isWindows && File('/usr/sbin/sshd').existsSync();

  /// Finds a free port by binding one and letting go of it.
  ///
  /// Fixed ports left tests fighting over TIME_WAIT when suites run in
  /// parallel, which showed up as a connection that inexplicably produced no
  /// output.
  static Future<int> _freePort() async {
    final socket = await ServerSocket.bind('127.0.0.1', 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  /// Starts a server, on a free port unless one is given.
  ///
  /// [hostKey] selects which fixture key the server presents, so a test can
  /// restart it with a different one — on the same port — and prove that a
  /// changed key is refused.
  static Future<TestSshd> start({
    int? port,
    String hostKey = 'ed25519_host',
    String? authorizedKey,
  }) async {
    final chosenPort = port ?? await _freePort();
    final directory = await Directory.systemTemp.createTemp('termino-sshd-');

    // sshd refuses a group- or world-readable host key, and a git checkout
    // does not preserve 0600, so the key is copied and re-permissioned.
    final hostKeyPath = '${directory.path}/hostkey';
    await File('$fixtures/$hostKey').copy(hostKeyPath);
    await Process.run('chmod', ['600', hostKeyPath]);

    final authorizedKeys = '${directory.path}/authorized_keys';
    if (authorizedKey != null) {
      await File(authorizedKeys).writeAsString('$authorizedKey\n');
    } else {
      await File('$fixtures/client_ed25519.pub').copy(authorizedKeys);
    }
    await Process.run('chmod', ['600', authorizedKeys]);

    final dispatcherPath = '${directory.path}/dispatch.sh';
    // OpenSSH sets SSH_ORIGINAL_COMMAND to the subsystem's configured *path*,
    // not the name "sftp", which is why matching on the name silently fell
    // through to the shell and left every SFTP client waiting for a reply.
    await File(dispatcherPath).writeAsString('''
#!/bin/sh
case "\$SSH_ORIGINAL_COMMAND" in
  *sftp-server*|*internal-sftp*)
    exec $sftpServer
    ;;
esac
exec /bin/sh
''');
    await Process.run('chmod', ['755', dispatcherPath]);

    final configPath = '${directory.path}/sshd_config';
    await File(configPath).writeAsString('''
Port $chosenPort
ListenAddress 127.0.0.1
HostKey $hostKeyPath
PidFile ${directory.path}/sshd.pid
AuthorizedKeysFile $authorizedKeys
UsePAM no
StrictModes no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
LogLevel ERROR
# Run a plain shell rather than the developer's login shell. These tests
# exercise the SSH backend, not whatever lives in someone's .zshrc — and a
# login shell brings real problems with it: several starting at once contend
# on tool-manager lock files (pyenv's rehash lock, for one) and simply hang,
# which looks exactly like a broken client.
#
# ForceCommand applies to subsystem requests too, so it cannot simply be
# /bin/sh: that would make every SFTP session open a shell instead of
# sftp-server, and the client would wait forever for a protocol reply. The
# dispatcher looks at SSH_ORIGINAL_COMMAND, which OpenSSH sets to the
# subsystem name, and hands off accordingly.
ForceCommand $dispatcherPath
Subsystem sftp $sftpServer
''');

    final process = await Process.start('/usr/sbin/sshd', [
      '-f',
      configPath,
      '-D',
      '-e',
    ]);
    // Draining these is not optional, and getting it wrong is invisible until
    // it is baffling. sshd logs to stderr; if nothing reads that pipe, the OS
    // buffer fills and sshd *blocks on the write*, freezing the session. The
    // kernel keeps echoing typed input, because the pty line discipline is
    // unaffected, so the symptom is a shell that echoes every command and runs
    // none of them.
    final log = StringBuffer();
    void collect(String chunk) {
      log.write(chunk);
      // Bounded, so a long-running server cannot grow it without limit.
      if (log.length > 64 * 1024) {
        final tail = log.toString();
        log
          ..clear()
          ..write(tail.substring(tail.length - 32 * 1024));
      }
    }

    process.stdout.transform(const SystemEncoding().decoder).listen(collect);
    process.stderr.transform(const SystemEncoding().decoder).listen(collect);
    _logs[process.pid] = log;

    // Wait for the listener rather than sleeping a fixed amount.
    for (var attempt = 0; attempt < 50; attempt++) {
      try {
        final socket = await Socket.connect(
          '127.0.0.1',
          chosenPort,
          timeout: const Duration(milliseconds: 200),
        );
        socket.destroy();
        return TestSshd._(process, chosenPort, directory);
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    process.kill();
    await directory.delete(recursive: true);
    throw StateError('sshd did not start listening on port $chosenPort');
  }

  /// The private key a client should authenticate with.
  static String get clientPrivateKey =>
      File('$fixtures/client_ed25519').readAsStringSync();

  /// A private key the server does **not** trust.
  static String get untrustedPrivateKey =>
      File('$fixtures/client_rsa').readAsStringSync();

  /// Stops the server and removes everything it created.
  Future<void> stop() async {
    _process.kill();
    await _process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () => 0,
    );
    _logs.remove(_process.pid);
    if (_directory.existsSync()) {
      await _directory.delete(recursive: true);
    }
  }
}
