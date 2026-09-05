import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:termino/core/capabilities/local_shell_support.dart';
import 'package:xterm/xterm.dart';

/// A red/green/blue swatch written with SGR 38;2 truecolour sequences.
const _trueColourSwatch =
    '\x1b[38;2;255;110;80mR'
    '\x1b[38;2;110;255;140mG'
    '\x1b[38;2;110;170;255mB'
    '\x1b[0m';

void main() {
  runApp(const TerminoSmokeTestApp());
}

/// Phase 0 smoke test: proves that `xterm`, `flutter_pty` and `dartssh2`
/// compile and link together on this Flutter SDK. Replaced in Phase 1 by the
/// real application shell.
class TerminoSmokeTestApp extends StatelessWidget {
  /// Creates the smoke test app.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Termino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _SmokeTestPage(),
    );
  }
}

class _SmokeTestPage extends StatefulWidget {
  const new();

  @override
  State<_SmokeTestPage> createState() => _SmokeTestPageState();
}

class _SmokeTestPageState extends State<_SmokeTestPage> {
  final Terminal _terminal = Terminal(maxLines: 10000);
  final TerminalController _controller = TerminalController();

  @override
  void initState() {
    super.initState();
    _writeReport();
  }

  /// Writes a report proving each dependency is reachable at runtime, using
  /// only type-level references so nothing is actually spawned or connected.
  void _writeReport() {
    // Statically reference dartssh2 so the linker must resolve it. The PTY
    // plugin is reached through the conditional export instead, because a
    // direct import would break the web compile.
    const sshType = SSHClient;
    final pty = localShellCompiledIn ? localShellBackendName : 'n/a (web)';

    _terminal
      ..write('\x1b[1;36mTermino\x1b[0m — Phase 0 smoke test\r\n')
      ..write('\r\n')
      ..write('  xterm       \x1b[32mok\x1b[0m  Terminal + TerminalView\r\n')
      ..write('  flutter_pty \x1b[32mok\x1b[0m  $pty\r\n')
      ..write('  dartssh2    \x1b[32mok\x1b[0m  $sshType\r\n')
      ..write('\r\n')
      ..write('  truecolour  $_trueColourSwatch\r\n')
      ..write('  box drawing ┌─┬─┐ │ └─┴─┘\r\n')
      ..write('\r\n')
      ..write('  platform    ${defaultTargetPlatform.name}\r\n');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termino')),
      body: TerminalView(
        _terminal,
        controller: _controller,
        autofocus: true,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
