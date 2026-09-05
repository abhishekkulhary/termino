# Termino — Architecture

Termino is a terminal emulator and SSH client built as a single Flutter
codebase targeting Android, iOS, macOS, Windows, Linux and the web.

Three properties dominate every decision here, in order: **correctness of the
terminal emulation**, **security of credential handling**, and **input
ergonomics on touch devices**. Where a design choice trades one of those for
convenience, the trade is written down in [DECISIONS.md](DECISIONS.md).

---

## 1. Layers

```
presentation  →  application  →  domain  ←  infrastructure
   features/        features/      domain/     infrastructure/
   shared/          core/
```

The dependency arrows point **inward**. `lib/domain/` describes what Termino
is — hosts, identities, known hosts, shell profiles, and the `TerminalBackend`
contract — in pure Dart with **zero Flutter imports**. That keeps the rules of
the system testable without a Flutter binding and reusable from a CLI or the
relay.

This is the one architectural rule enforced mechanically, by
[`tool/check_domain_purity.sh`](tool/check_domain_purity.sh) in CI.

Directories marked *planned* arrive in the phase noted.

```
lib/
  app/                  app root, router, navigation destinations
  core/
    capabilities/       the conditional PTY seam; PlatformCapabilities (Phase 2)
    logging/            redacting logger (planned, Phase 3)
  domain/
    backends/           TerminalBackend, its state machine and failure taxonomy
    entities/           Host, Identity, KnownHost, ShellProfile (planned, Phase 3)
    repositories/       abstract interfaces only (planned, Phase 3)
  infrastructure/
    backends/
      local_pty/        conditional seam: _ffi (real) or _stub (web)
      mock_backend.dart
    terminal/           output_batcher.dart — the coalescing sink
    ssh/                client factory, auth, host key verifier (planned, Phase 3)
    storage/            drift database, secure storage (planned, Phase 3)
  features/
    terminal/
      application/      TerminalSession, SessionManager, demo fixture
      presentation/     TerminalPane (the only importer of xterm), TerminalScreen
    placeholder/        honest stand-ins for features not yet built
    hosts/ identities/ sftp/ forwarding/ settings/   (planned)
  shared/
    design/             tokens, breakpoints, app theme, terminal palettes
    widgets/            AdaptiveScaffold
tools/relay/            reference WebSocket→TCP relay (planned, Phase 7)
```

### Containment of `xterm`

`features/terminal/presentation/terminal_pane.dart` is the **only** file in the
app that imports `xterm`. Everything else talks to `TerminalSession`. Given that
xterm.dart has not had a release since February 2024, this is deliberate
insurance: swapping or vendoring the emulator changes one file rather than the
whole UI.

---

## 2. The central abstraction

Everything hangs off one interface. A local shell, a remote SSH session and a
replayed fixture are all the same thing to the UI: a bidirectional byte stream
with resize control and a lifecycle.

```dart
abstract class TerminalBackend {
  Stream<Uint8List> get output;
  Future<int?> get exitCode;
  ConnectionState get state;
  Stream<ConnectionState> get states;

  Future<void> start();
  void write(Uint8List data);
  void resize(int columns, int rows, {int pixelWidth = 0, int pixelHeight = 0});
  Future<void> close();
}
```

| Implementation | Wraps | Available on |
|---|---|---|
| `LocalPtyBackend` | `flutter_pty` | Linux, macOS, Windows, Android |
| `SshBackend` | `dartssh2` | everywhere, including the web |
| `MockBackend` | fixtures | everywhere; used by tests and the widget catalogue |

A `TerminalSession` is a `TerminalBackend` plus an `xterm` `Terminal` plus
metadata:

```text
backend.output ─▶ batcher ─▶ UTF-8 decoder ─▶ terminal.write
terminal.onOutput ─▶ UTF-8 encoder ─▶ backend.write
terminal.onResize ─▶ backend.resize
terminal.onTitleChange ─▶ session title
```

Decoding sits **downstream of batching and is stateful**, because a UTF-8
sequence is routinely split across two reads; decoding each chunk independently
would render replacement characters in place of ordinary letters. There is a
test for exactly that.

`SessionManager` owns the list of sessions, tabs and splits, restores layout on
relaunch, and disposes backends deterministically.

### There is no separate web backend

The obvious design — a `WebSocketRelayBackend` that pipes a byte stream to a
relay which speaks SSH on the browser's behalf — is the wrong one, because it
puts the user's plaintext session and their credentials inside the relay.

`dartssh2` 4.x runs the SSH protocol **in the browser** over a caller-supplied
`SSHSocket`. So the web is `SshBackend` with a different socket:

```dart
typedef SshSocketFactory = Future<SSHSocket> Function(String host, int port);
```

Native builds inject a `dart:io` socket; the web injects a WebSocket one. The
relay in `tools/relay/` is therefore a **dumb TCP tunnel that never sees
plaintext** — end-to-end encryption and host key verification survive it
intact, and a compromised relay cannot read a session or steal a key.

---

## 3. Platform capabilities

A local shell is not universally possible, and the architecture does not
pretend otherwise.

| Platform | Local PTY shell | SSH | Notes |
|---|---|---|---|
| Linux | yes (`forkpty`) | yes | shell from `$SHELL` |
| macOS | yes (`forkpty`) | yes | App Sandbox must be relaxed for the local shell; the Mac App Store flavour keeps the sandbox and ships with local shell disabled |
| Windows | yes (ConPTY) | yes | PowerShell by default; cmd, WSL and Git Bash as profiles |
| Android | yes, sandboxed | yes | runs as the app UID inside the app sandbox; no root, limited binaries |
| iOS / iPadOS | **no** | yes | spawning arbitrary binaries is not permitted. Not attempted. Feature-gated off with an in-app explanation |
| Web | **no** | via relay | browsers cannot open raw TCP sockets |

Two distinct questions are answered in two distinct places, and conflating them
is a bug:

- **Can this build even reference the PTY plugin?** A compile-time question.
  `flutter_pty` depends on `dart:ffi`, which does not exist on the web, so a
  plain import breaks the web compile outright. Every reference sits behind the
  conditional export in
  [`lib/core/capabilities/local_shell_support.dart`](lib/core/capabilities/local_shell_support.dart).
- **May a local shell actually be spawned?** A runtime question. iOS compiles
  `dart:ffi` perfectly well and still forbids spawning binaries. This belongs to
  `PlatformCapabilities`.

**Every feature-gated widget consults `PlatformCapabilities`.** There are no
`Platform.isX` checks scattered through widgets. It is a provider, so tests and
the widget catalogue can render a platform they are not running on — which is
how the iOS and web explanation screens are golden-tested from a Mac.

A gated feature is never silently hidden. `LocalShellNotice` says which platform
rule applies and what still works instead, because a missing button is
indistinguishable from a broken app.

### Backpressure reaches the child process

The chain is complete from the terminal widget to the program at the far end:
the terminal pauses its subscription, the coalescing sink pauses its source,
`pipeOutput` pauses the PTY stream, the acknowledgement stops being sent, and
the child blocks on its own `write`. `flutter_pty`'s `ackRead` option is the
last link; without it the native read thread fills the isolate's port queue
without bound.

---

## 4. Throughput

The path from bytes to glyphs is the one place performance is a feature rather
than a nicety. Between `backend.output` and `terminal.write` sits a coalescing
sink: incoming bytes are buffered and flushed on a ~8 ms window or when a size
threshold is hit, whichever comes first, and the subscription applies
backpressure so that `cat`-ing a large file pauses the socket rather than
growing an unbounded queue.

This single component decides whether the targets in the brief are met, so it
owns its own unit tests and its own harness in `benchmark/`.

---

## 5. Security posture

The full threat model is in [SECURITY.md](SECURITY.md). In short:

- Private keys, passphrases and passwords live **only** in
  `flutter_secure_storage` — Keychain, Keystore, libsecret, DPAPI. Never in the
  drift database, never in preferences, never in logs.
- Host keys are verified against a persistent `known_hosts` store. A first
  sighting prompts with the fingerprint; **a changed key is a hard stop**, never
  auto-accepted.
- The logger redacts passwords, passphrases, key material, auth banners and the
  session byte stream, and a unit test asserts it.
- No telemetry.

---

## 6. Testing

| Layer | Approach |
|---|---|
| Escape sequences | fixture-driven unit tests |
| Host key verification, `~/.ssh/config` parsing, key import, redaction, backend state machines | unit tests; 70% coverage gate on `domain/` and `infrastructure/` |
| Terminal view, key accessory bar, host editor | widget tests |
| Themes and key bar across breakpoints | golden tests |
| A full SSH session | `integration_test/` against a pinned OpenSSH container (`test/fixtures/docker-compose.yml`), in CI |
| A full local PTY session | `integration_test/` on desktop CI |

The real acceptance test is behavioural, not a percentage: connect over SSH with
a key, run **`vim` and `htop`** correctly, transfer a file over SFTP, establish a
local port forward, and confirm that a changed host key blocks the connection.
