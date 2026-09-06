import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:path_provider/path_provider.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/backends/terminal_backend_base.dart';
import 'package:termino/domain/entities/shell_profile.dart';

/// Creates a backend that runs [profile] in a local pseudo-terminal.
TerminalBackend createLocalPtyBackend({
  required ShellProfile profile,
  int columns = 80,
  int rows = 24,
}) => LocalPtyBackend(profile: profile, columns: columns, rows: rows);

/// Runs a shell in a pseudo-terminal on this machine.
class LocalPtyBackend extends TerminalBackendBase {
  /// Creates a backend for [profile] at an initial size.
  ///
  /// The size is a starting guess; the terminal corrects it with a real
  /// [resize] as soon as it has been laid out.
  new({required this.profile, this.columns = 80, this.rows = 24});

  /// The shell to run.
  final ShellProfile profile;

  /// Initial width in character cells.
  final int columns;

  /// Initial height in character cells.
  final int rows;

  Pty? _pty;
  int? _exitStatus;
  Timer? _exitGrace;

  /// The PTY reports its exit status on a channel separate from its output, so
  /// the session must not end merely because the output stream finished — that
  /// would report a null exit code a moment before the real one arrives.
  @override
  void handleOutputDone() {
    if (state.isTerminal) return;
    if (_exitStatus != null) {
      setClosed(_exitStatus);
      return;
    }
    _startExitGrace();
  }

  @override
  Future<void> connect() async {
    // forkpty succeeds even when the executable does not exist: the failure
    // happens in the child, after the fork, and surfaces as a shell that exits
    // immediately rather than as an error here. Checking first turns that into
    // a clear message instead of a terminal that blinks open and shuts.
    _ensureExecutable();

    final defaults = await _platformDefaults();
    final environment = {...defaults.environment, ...profile.environment};

    final Pty pty;
    try {
      pty = Pty.start(
        profile.executable,
        arguments: profile.arguments,
        workingDirectory: profile.workingDirectory ?? defaults.workingDirectory,
        environment: environment.isEmpty ? null : environment,
        columns: columns,
        rows: rows,
        // Native flow control: the read thread waits for an acknowledgement
        // before sending the next chunk. Without it, a process spewing output
        // faster than the terminal can render — `yes`, or `cat` of a large
        // file — fills the isolate's port queue without bound. This is the
        // mechanism that makes backpressure reach all the way to the child.
        ackRead: true,
      );
    } on Object catch (error) {
      throw TerminalBackendFailure(
        TerminalBackendFailureKind.spawn,
        _spawnMessage(error),
        cause: error,
      );
    }

    _pty = pty;

    // Acknowledging inside the pipeline means the next chunk is only requested
    // once this one has been accepted downstream. When the terminal pauses, the
    // callback stops running, no acknowledgement is sent, and the child blocks
    // on its own write — which is exactly what a real terminal does.
    pipeOutput(
      pty.output.map((chunk) {
        pty.ackRead();
        return chunk;
      }),
    );

    unawaited(
      pty.exitCode.then(_handleExit, onError: (Object _) => _handleExit(null)),
    );
  }

  void _handleExit(int? code) {
    _exitStatus = code;
    _exitGrace?.cancel();
    _exitGrace = null;
    setClosed(code);
  }

  /// `flutter_pty` closes its output port the instant the child exits, and its
  /// own documentation warns that buffered output may not have been delivered.
  /// Nothing here can stop that, but if the exit status somehow never arrives
  /// the session must not hang in `connected` forever.
  void _startExitGrace() {
    _exitGrace ??= Timer(const Duration(seconds: 2), () {
      if (!state.isTerminal) setClosed(_exitStatus);
    });
  }

  @override
  void send(Uint8List data) => _pty?.write(data);

  @override
  void resize(
    int columns,
    int rows, {
    int pixelWidth = 0,
    int pixelHeight = 0,
  }) {
    // Note the argument order: flutter_pty takes (rows, columns), the reverse
    // of every other resize signature in this codebase and of the terminal's
    // own callback. Getting it backwards makes `vim` draw at the wrong size in
    // a way that looks like an emulator bug.
    _pty?.resize(rows, columns);
  }

  @override
  Future<void> disconnect() async {
    _exitGrace?.cancel();
    _exitGrace = null;

    final pty = _pty;
    _pty = null;
    if (pty == null) return;

    try {
      pty.kill();
    } on Object {
      // The child may already be gone; there is nothing useful to do.
    }
  }

  @override
  void setClosed([int? code]) => super.setClosed(code ?? _exitStatus);

  void _ensureExecutable() {
    final path = profile.executable;
    final looksLikePath = path.contains('/') || path.contains(r'\');
    if (!looksLikePath) return; // Resolved via PATH by the OS; leave it be.

    final file = File(path);
    if (!file.existsSync()) {
      throw TerminalBackendFailure(
        TerminalBackendFailureKind.spawn,
        '$path could not be found.',
      );
    }
    if (!Platform.isWindows) {
      // Bit 0o111 is any execute permission. A shell we cannot execute fails
      // in the child, where the error is invisible.
      final mode = file.statSync().mode;
      if (mode & 0x49 == 0) {
        throw TerminalBackendFailure(
          TerminalBackendFailureKind.spawn,
          '$path is not executable.',
        );
      }
    }
  }

  String _spawnMessage(Object error) {
    final text = error.toString();
    if (text.contains('No such file') || text.contains('not found')) {
      return '${profile.executable} could not be found.';
    }
    if (text.contains('Permission denied')) {
      return '${profile.executable} is not executable.';
    }
    return 'The shell ${profile.executable} could not be started.';
  }
}

/// Where a shell should start, and what it needs in its environment, on this
/// platform.
typedef _ShellDefaults = ({
  String? workingDirectory,
  Map<String, String> environment,
});

/// Fills in what the operating system does not.
///
/// On desktop this is nothing: the process already starts in the user's home
/// directory with `HOME` set, and `flutter_pty` copies `HOME` and `PATH`
/// through while setting `TERM` and `LANG` itself.
///
/// Android is the exception, and it is why a local shell there looked
/// completely broken. An Android app process starts with its working
/// directory at `/`, which the app's own UID may not read — so the first `ls`
/// a user types comes back `Permission denied`, and any redirect fails on a
/// read-only filesystem. The process environment has no `HOME` either, so
/// `cd` reports "no home directory", `~` does not expand, and anything that
/// writes a dotfile fails. Neither is a sandbox limit we have to accept: the
/// app's private directory is readable, writable and persistent, and pointing
/// the shell at it makes an ordinary session behave ordinarily.
Future<_ShellDefaults> _platformDefaults() async {
  if (!Platform.isAndroid) {
    return (workingDirectory: null, environment: const <String, String>{});
  }

  final home = await getApplicationDocumentsDirectory();
  final temporary = await getTemporaryDirectory();
  return (
    workingDirectory: home.path,
    environment: {
      'HOME': home.path,
      // Android has no /tmp, and /data/local/tmp belongs to the shell user,
      // not to us. Without this, mktemp and everything built on it fail.
      'TMPDIR': temporary.path,
    },
  );
}

/// The shells available on this machine, best first.
///
/// Discovery is deliberately conservative: a profile is only offered if its
/// executable actually exists, so the list never contains something that will
/// fail the moment it is chosen.
List<ShellProfile> discoverShellProfiles() {
  if (Platform.isWindows) return _windowsProfiles();
  return _unixProfiles();
}

/// The shell to use when the user has not chosen one.
ShellProfile? defaultShellProfile() {
  final profiles = discoverShellProfiles();
  return profiles.isEmpty ? null : profiles.first;
}

List<ShellProfile> _unixProfiles() {
  final profiles = <ShellProfile>[];

  // $SHELL is the user's own choice and outranks anything we might guess.
  final userShell = Platform.environment['SHELL'];
  final hasUserShell =
      userShell != null && userShell.isNotEmpty && _exists(userShell);
  if (hasUserShell) {
    profiles.add(
      ShellProfile(
        id: 'login',
        name: '${_basename(userShell)} (login)',
        executable: userShell,
        // A login shell reads the user's profile, so PATH and aliases are the
        // ones they actually have in their own terminal.
        arguments: const ['-l'],
      ),
    );
  }

  const candidates = <String, String>{
    '/bin/zsh': 'zsh',
    '/bin/bash': 'bash',
    '/system/bin/sh': 'sh',
    '/bin/sh': 'sh',
  };

  // Android has both /system/bin/sh and /bin/sh, and the second is a symlink
  // to the first. Offering the same shell twice under the same name is
  // confusing on its own; giving two profiles the same id is worse, because
  // the id is what a saved preference refers to. Compare resolved paths.
  final seen = <String>{if (hasUserShell) _resolve(userShell)};

  for (final entry in candidates.entries) {
    if (!_exists(entry.key)) continue;
    if (!seen.add(_resolve(entry.key))) continue;
    profiles.add(
      ShellProfile(id: entry.value, name: entry.value, executable: entry.key),
    );
  }

  return profiles;
}

/// The real path behind [path], or [path] itself when it cannot be resolved.
String _resolve(String path) {
  try {
    return File(path).resolveSymbolicLinksSync();
  } on Object {
    return path;
  }
}

List<ShellProfile> _windowsProfiles() {
  final profiles = <ShellProfile>[];
  final systemRoot = Platform.environment['SystemRoot'] ?? r'C:\Windows';
  final programFiles =
      Platform.environment['ProgramFiles'] ?? r'C:\Program Files';

  final candidates = <ShellProfile>[
    ShellProfile(
      id: 'pwsh',
      name: 'PowerShell 7',
      executable: '$programFiles\\PowerShell\\7\\pwsh.exe',
    ),
    ShellProfile(
      id: 'powershell',
      name: 'Windows PowerShell',
      executable:
          '$systemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
    ),
    ShellProfile(
      id: 'cmd',
      name: 'Command Prompt',
      executable: '$systemRoot\\System32\\cmd.exe',
    ),
    ShellProfile(
      id: 'wsl',
      name: 'WSL',
      executable: '$systemRoot\\System32\\wsl.exe',
    ),
    ShellProfile(
      id: 'git-bash',
      name: 'Git Bash',
      executable: '$programFiles\\Git\\bin\\bash.exe',
      arguments: const ['--login', '-i'],
    ),
  ];

  for (final profile in candidates) {
    if (_exists(profile.executable)) profiles.add(profile);
  }
  return profiles;
}

bool _exists(String path) {
  try {
    return File(path).existsSync();
  } on Object {
    return false;
  }
}

String _basename(String path) =>
    path.split(Platform.isWindows ? r'\' : '/').last;
