// The §13 acceptance criterion that a unit test cannot reach: full-screen
// programs — an editor and a process monitor — driven through the real
// pipeline, PTY to batcher to emulator, and judged on what ends up on screen.
//
//     flutter test integration_test/tui_acceptance_test.dart -d macos
//
// These programs are the honest test of an emulator. Between them they use the
// alternate screen buffer, absolute cursor addressing, a full redraw on resize
// and a clean restore on exit — and each one breaks visibly when any of that is
// wrong, which is why the brief named them.
@Timeout(Duration(seconds: 180))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:termino/domain/entities/shell_profile.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/infrastructure/backends/local_pty/local_pty_backend.dart';

const _columns = 80;
const _rows = 24;

/// The key that leaves vim's insert mode.
const _escape = '\u001b';

/// A shell with no profile files, no prompt and no colour, so that what the
/// screen shows is the program under test and nothing else.
ShellProfile _plainShell() => const ShellProfile(
  id: 'acceptance',
  name: 'sh',
  executable: '/bin/sh',
  environment: {'ENV': '', 'TERM': 'xterm-256color'},
);

/// The visible screen, trailing blanks trimmed.
String _screen(TerminalSession session) => session.terminal.buffer
    .getText()
    .split('\n')
    .map((line) => line.trimRight())
    .join('\n');

/// Waits until [test] holds, or gives up and reports what was on screen.
Future<void> _until(
  TerminalSession session,
  bool Function() test, {
  Duration limit = const Duration(seconds: 25),
  String? reason,
}) async {
  final deadline = DateTime.now().add(limit);
  while (DateTime.now().isBefore(deadline)) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail('${reason ?? 'condition'} never held. Screen was:\n${_screen(session)}');
}

Future<TerminalSession> _openShell() async {
  final session = TerminalSession(
    id: 'acceptance',
    backend: createLocalPtyBackend(profile: _plainShell()),
  );
  session.terminal.resize(_columns, _rows);
  await session.start();
  // Let the shell settle before anything is typed at it.
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return session;
}

/// The path to [command], or null when it is not installed.
String? _which(String command) {
  final result = Process.runSync('/usr/bin/which', [command]);
  if (result.exitCode != 0) return null;
  final path = (result.stdout as String).trim();
  return path.isEmpty ? null : path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('vim', () {
    late TerminalSession session;

    setUp(() async => session = await _openShell());
    tearDown(() => session.dispose());

    test('draws, edits, survives a resize and restores the screen', () async {
      final vim = _which('vim') ?? _which('vi');
      if (vim == null) {
        markTestSkipped('vim is not installed');
        return;
      }

      final file = File('${Directory.systemTemp.path}/termino-vim-$pid.txt');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      // Something on the main screen to come back to afterwards.
      session.sendText('echo BEFORE_VIM\n');
      await _until(
        session,
        () => _screen(session).contains('BEFORE_VIM'),
        reason: 'the shell echo',
      );

      // -u NONE -N: no user config, so this tests the emulator rather than
      // whatever plugins happen to be installed on the machine running it.
      session.sendText('$vim -u NONE -N ${file.path}\n');
      await _until(
        session,
        () => session.terminal.isUsingAltBuffer,
        reason: 'vim switching to the alternate screen',
      );

      // A new file: vim marks every unused line with a tilde in column 1.
      // Consecutive rows of those is absolute cursor addressing working.
      await _until(
        session,
        () => _screen(session).split('\n').where((l) => l == '~').length > 5,
        reason: "vim's empty-line markers",
      );

      session.sendText('ione line of text');
      await _until(
        session,
        () => _screen(session).contains('one line of text'),
        reason: 'typed text appearing',
      );
      expect(
        _screen(session).split('\n').first,
        'one line of text',
        reason: 'the text belongs on the first row, not wherever it landed',
      );

      // Resize, then make vim prove what width it believes it has by giving
      // it a line too long to fit. Asserting on the emulator's own geometry
      // here would prove nothing: the emulator is 40 columns wide because it
      // was just told to be. Only the wrap point comes from vim.
      session.terminal.resize(40, 20);
      await Future<void>.delayed(const Duration(seconds: 1));

      final long = 'B' * 60;
      session.sendText(
        '$_escape'
        'o$long',
      );
      await _until(
        session,
        () => _screen(session).split('\n').any((l) => l == 'B' * 40),
        reason: 'vim wrapping a 60-character line at its new 40-column width',
      );
      expect(
        _screen(session).split('\n').first,
        'one line of text',
        reason: 'the first line survives the redraw',
      );

      session.sendText('$_escape:wq\n');
      await _until(
        session,
        () => !session.terminal.isUsingAltBuffer,
        reason: 'vim restoring the main screen',
      );

      // The point of the alternate buffer: what was on screen before vim ran
      // is still there after it exits, and none of vim's screen is left behind.
      expect(_screen(session), contains('BEFORE_VIM'));
      expect(
        _screen(session).split('\n').where((l) => l == '~'),
        isEmpty,
        reason: "vim's screen must not survive into the main buffer",
      );

      await _until(
        session,
        file.existsSync,
        reason: 'the file vim was asked to write',
      );
      expect(file.readAsStringSync().trim().split('\n'), [
        'one line of text',
        'B' * 60,
      ]);
    });
  });

  group('resize', () {
    late TerminalSession session;

    setUp(() async => session = await _openShell());
    tearDown(() => session.dispose());

    test('reaches the running program the right way round', () async {
      // `stty size` reports the kernel's idea of the pty size, as the child
      // sees it. This is the check that catches rows and columns being passed
      // in the wrong order — a mistake that leaves the emulator looking right
      // and every full-screen program drawing at the wrong size.
      session.terminal.resize(40, 20);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      session.sendText('stty size\n');
      await _until(
        session,
        () => _screen(session).contains('20 40'),
        reason: 'the shell seeing 20 rows by 40 columns',
        limit: const Duration(seconds: 10),
      );

      session.terminal.resize(100, 30);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      session.sendText('stty size\n');
      await _until(
        session,
        () => _screen(session).contains('30 100'),
        reason: 'the shell seeing 30 rows by 100 columns',
        limit: const Duration(seconds: 10),
      );
    });
  });

  group('a full-screen process monitor', () {
    late TerminalSession session;

    setUp(() async => session = await _openShell());
    tearDown(() => session.dispose());

    test('runs, repaints on its own timer and restores the screen', () async {
      // htop is the program the brief names. It is not installed everywhere,
      // and `top` exercises the same emulator features — alternate screen,
      // absolute addressing, repeated full redraws — so this runs against
      // whichever is present rather than being skipped.
      final program = _which('htop') ?? _which('top');
      if (program == null) {
        markTestSkipped('neither htop nor top is installed');
        return;
      }

      session.sendText('echo BEFORE_MONITOR\n');
      await _until(
        session,
        () => _screen(session).contains('BEFORE_MONITOR'),
        reason: 'the shell echo',
      );

      session.sendText('$program\n');
      await _until(
        session,
        () => session.terminal.isUsingAltBuffer,
        reason: '$program switching to the alternate screen',
      );
      await _until(
        session,
        () => _screen(session).trim().split('\n').length > 5,
        reason: 'a full screen of output',
      );

      // A monitor repaints on a timer. Two different screens, both still the
      // height of the terminal, proves the repaints overwrite in place rather
      // than scrolling the old one away.
      final first = _screen(session);
      await Future<void>.delayed(const Duration(seconds: 3));
      final second = _screen(session);
      expect(
        second.split('\n').length,
        lessThanOrEqualTo(_rows),
        reason: 'redraws must overwrite the screen, not scroll it',
      );
      expect(
        second,
        isNot(equals(first)),
        reason: 'a process monitor should be updating',
      );

      session.sendText('q');
      await _until(
        session,
        () => !session.terminal.isUsingAltBuffer,
        reason: '$program restoring the main screen',
        limit: const Duration(seconds: 15),
      );
      expect(_screen(session), contains('BEFORE_MONITOR'));
    });
  });
}
