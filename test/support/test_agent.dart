import 'dart:io';

/// A throwaway `ssh-agent` holding the fixture keys.
///
/// The point of agent authentication is that the private key never enters this
/// process, so it cannot be tested by handing a key to a fake — the test has to
/// talk to a real agent over a real socket. `ssh-agent` runs unprivileged and
/// on a socket of our choosing, so that costs nothing.
class TestAgent {
  new _(this.socketPath, this._pid, this._directory);

  /// Where the agent is listening.
  final String socketPath;

  final int _pid;
  final Directory _directory;

  /// Whether this machine can run the harness.
  static bool get isSupported => !Platform.isWindows;

  /// Starts an agent and loads [keyPaths] into it.
  ///
  /// The socket goes under the system temp directory rather than beside the
  /// keys: a Unix socket path is limited to about a hundred characters, and a
  /// nested test directory overruns it — which fails as "path too long", not
  /// as anything about SSH.
  static Future<TestAgent> start(List<String> keyPaths) async {
    final directory = await Directory.systemTemp.createTemp('tagent-');
    final socketPath = '${directory.path}/s';

    final started = await Process.run('ssh-agent', ['-a', socketPath]);
    if (started.exitCode != 0) {
      throw StateError('ssh-agent would not start: ${started.stderr}');
    }

    final pid = RegExp(r'SSH_AGENT_PID=(\d+)').firstMatch('${started.stdout}');
    final agent = TestAgent._(socketPath, int.parse(pid!.group(1)!), directory);

    for (final path in keyPaths) {
      // ssh-add refuses a key anyone else could read, and a git checkout does
      // not preserve 0600.
      final copy = '${directory.path}/${path.split('/').last}';
      await File(path).copy(copy);
      await Process.run('chmod', ['600', copy]);

      final added = await Process.run(
        'ssh-add',
        [copy],
        environment: {'SSH_AUTH_SOCK': socketPath},
      );
      if (added.exitCode != 0) {
        throw StateError('ssh-add refused $path: ${added.stderr}');
      }
    }

    return agent;
  }

  /// Stops the agent and deletes everything it used.
  Future<void> stop() async {
    Process.killPid(_pid);
    if (_directory.existsSync()) {
      await _directory.delete(recursive: true);
    }
  }
}
