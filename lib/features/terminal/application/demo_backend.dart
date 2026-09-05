import 'package:termino/infrastructure/backends/mock_backend.dart';

/// A scripted transcript used until real backends arrive in Phases 2 and 3.
///
/// It doubles as a rendering exercise: 256-colour and truecolour output, box
/// drawing, block elements and Powerline separators all appear here, so a
/// glance at a running session shows whether the bundled font and the palette
/// are doing their job.
MockBackend createDemoBackend() => MockBackend(
  echoInput: true,
  closeWhenDrained: false,
  frames: [
    MockOutputFrame.text(_banner),
    MockOutputFrame.text(
      _capabilities,
      delay: const Duration(milliseconds: 120),
    ),
    MockOutputFrame.text(_prompt, delay: const Duration(milliseconds: 120)),
  ],
);

const _reset = '\x1b[0m';
const _bold = '\x1b[1m';
const _dim = '\x1b[2m';
const _cyan = '\x1b[36m';
const _green = '\x1b[32m';
const _yellow = '\x1b[33m';
const _blue = '\x1b[34m';

const _banner =
    '$_bold${_cyan}Termino$_reset $_dim— demo session$_reset\r\n'
    '\r\n'
    '  ${_dim}No local shell is attached yet. This is a replayed fixture;\r\n'
    '  real PTY sessions arrive in Phase 2 and SSH in Phase 3.$_reset\r\n'
    '\r\n';

const _capabilities =
    '  ${_bold}Rendering check$_reset\r\n'
    '  ┌────────────────┬──────────────────────────────────┐\r\n'
    '  │ 16 colours     │ '
    '\x1b[31m██\x1b[32m██\x1b[33m██\x1b[34m██\x1b[35m██\x1b[36m██\x1b[37m██'
    '\x1b[91m██\x1b[92m██\x1b[93m██\x1b[94m██\x1b[95m██\x1b[96m██$_reset'
    '        │\r\n'
    '  │ truecolour     │ '
    '\x1b[38;2;255;110;80m███\x1b[38;2;255;190;90m███'
    '\x1b[38;2;110;255;140m███\x1b[38;2;110;170;255m███'
    '\x1b[38;2;208;139;255m███$_reset       │\r\n'
    '  │ block elements │ ░▒▓█▉▊▋▌▍▎▏  ▁▂▃▄▅▆▇█            │\r\n'
    '  │ powerline      │                   │\r\n'
    '  └────────────────┴──────────────────────────────────┘\r\n'
    '\r\n';

const _prompt =
    '$_green➜$_reset  $_blue~/projects/Termino$_reset '
    '$_yellow(main)$_reset ';
