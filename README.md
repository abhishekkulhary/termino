# Termino

A cross-platform terminal emulator and SSH client, built as a single Flutter
codebase for Android, iOS, macOS, Windows, Linux and the web.

Termino does two things: it gives you a real PTY-backed local shell on every
platform that permits one, and it connects you to remote machines over SSH with
an interactive shell, SFTP file transfer and port forwarding.

> **Status: 1.0.0.** Every phase in the plan is complete. See
> [CHANGELOG.md](CHANGELOG.md) for what is in it and
> [docs/RELEASING.md](docs/RELEASING.md) for how to ship it.

---

## Platform support

| Platform | Local shell | SSH | Status |
|---|---|---|---|
| macOS | **working** | **working** | sandbox off; see below |
| Android | yes, sandboxed | yes | builds |
| iOS / iPadOS | **no** — not permitted by the platform | yes | builds, local shell gated off with an explanation |
| Linux | yes | yes | CI only |
| Windows | yes | yes | CI only |
| Web | **no** | **working**, via a relay | local shell gated off with an explanation |

On macOS the App Sandbox is disabled, because a sandboxed process cannot run the
user's own programs or read their files — which is the whole point of a
terminal. A sandboxed, SSH-only Mac App Store build is a separate configuration
planned for Phase 8. See [DECISIONS.md](DECISIONS.md).

iOS cannot spawn arbitrary binaries, and browsers cannot open raw TCP sockets.
Termino does not pretend otherwise: those features are feature-gated off at
runtime with an in-app explanation rather than failing mysteriously. See
[ARCHITECTURE.md](ARCHITECTURE.md#3-platform-capabilities).

Linux and Windows are marked "CI only" because they build and are tested in
continuous integration, but the current development machine cannot run them —
so nobody has yet judged them by eye. They are promoted to first-class in
Phase 8.

---

### Connecting to a `.local` host

A name ending in `.local` is answered by the machine itself over multicast DNS,
not by a DNS server. macOS and iOS have that built into the resolver; Android
does not, and Windows and Linux depend on what is installed. Termino therefore
asks the network directly when the system resolver has no answer, so
`pi@my-server.local` works the same everywhere — provided the phone and the
server are on the same network. If it is not found, use the IP address.

### Where downloads go

On desktop the first download asks where to save, and remembers the answer.
**Settings → Files** shows the folder and changes it; **Download to…** on a
file's menu asks again for a one-off. If the remembered folder has gone — an
external disk unmounted, a directory deleted — Termino asks again rather than
failing one download at a time with a filesystem error.

On a phone downloads go to the app's own documents folder, which is the only
place they can go, so nothing asks.

### Transferring folders

The file browser moves whole folders, in both directions. A folder download
walks the remote tree, creates every directory locally — including the empty
ones — and queues one transfer per file; an upload does the same in reverse.
Either way you are told how many files are coming and how big they are before
anything moves.

Symbolic links are skipped and counted rather than followed. A link pointing at
an ancestor makes a copy walk in circles, and a link to something like
`/dev/zero` makes a file that never ends — neither is what anyone means by
"download this folder", so the count is reported instead.

A walk stops at 2000 files or 32 levels deep and says that it stopped, so a
mistaken tap on `/` cannot quietly start reading an entire server.

### Links in terminal output

Text that reads as a URL is recognised and opens on a tap. A program can also
declare a link explicitly with OSC 8 — `ls --hyperlink`, `gcc`'s diagnostics,
`gh` — and those are underlined and open on a tap too.

A declared link asks first, showing where it actually goes. That is not
ceremony: OSC 8 lets a program choose the words and the destination separately,
so the word `docs` can point anywhere at all.

### Using a key Termino never sees

On macOS and Linux, a host can authenticate through the **system SSH agent**
instead of a key imported here — `ssh-agent`, 1Password, Secretive, or a
hardware token. The private key never enters Termino; the agent signs on its
behalf. That also covers keys that *cannot* be exported at all, such as one held
in the Secure Enclave.

Turn it on per host in the host editor, which shows what the agent is holding
before you save. If it says `SSH_AUTH_SOCK` is not set, launch Termino from a
terminal — an app started from Finder or a launcher does not inherit it.

Not offered on Windows: its agent speaks over a named pipe, which Dart cannot
open. See [DECISIONS.md](DECISIONS.md) for what fixing that would take.

### Sending and receiving files inside a session

`rz` and `sz` — ZModem — move a file through the terminal connection itself,
with no second connection and no SFTP subsystem. It is the thing that still
works when SFTP is disabled, when you are three `ssh` hops deep, or when you are
on a serial console.

Both directions start on the remote machine, because that is how the protocol
works:

- **Receiving.** Run `sz report.pdf` on the host. Termino asks before saving
  anything — an offer is never accepted automatically — and then writes it to
  `Downloads/Termino` on desktop, or the app's documents folder on a phone,
  telling you the exact path.
- **Sending.** Run `rz` on the host, or use **Send a file to this session** in
  the command palette, which runs it for you. Termino opens a file picker.

The remote host needs `lrzsz` installed (`rz` and `sz`). Transfers can be
cancelled from the progress strip, which tells the far end to stop rather than
just hiding the bar. Not available on web, which has no local filesystem.

## Getting started

Requires **Flutter 3.47.1** or later (Dart 3.13.1+).

```bash
git clone <repository-url> Termino
cd Termino
flutter pub get
```

Then run on any connected target:

```bash
flutter run -d macos
```

### Building

| Target | Command |
|---|---|
| macOS | `flutter build macos` |
| Android | `flutter build apk` |
| iOS | `flutter build ios` |
| Web | `flutter build web` |
| Linux | `flutter build linux` |
| Windows | `flutter build windows` |

### Checks

The tree is kept warning-free. Before committing:

```bash
dart format . && flutter analyze && flutter test
```

Generated sources (`*.g.dart`, `*.freezed.dart`) are committed so a fresh clone
analyses without a build step. After changing a `@freezed` or `@riverpod`
declaration, regenerate them:

```bash
dart run build_runner build
```

Golden tests render real fonts and are tagged, so they can be skipped:

```bash
flutter test -x golden
```

**Run one Flutter command at a time.** Two concurrent `flutter test` invocations
in this checkout will break each other: both rebuild the native assets under
`build/native_assets/`, and whichever finishes second replaces `libsqlite3.dylib`
while the first is still using it. Every test that opens the database then fails
with `Couldn't resolve native function 'sqlite3_initialize'`. It looks exactly
like a flaky test and is not one — reproduced here at 2 failures in 3 concurrent
pairs, and never once in a single process, including with the native assets
deleted first. If an IDE runs tests on save, do not also run them in a terminal.

SSH is covered by ordinary `flutter test` runs: they start a throwaway `sshd`
unprivileged on a free port and connect to it for real, so no Docker or daemon
is needed.

The relay is its own package and has its own tests:

```bash
cd tools/relay && dart test
```

The local PTY is the one thing `flutter test` cannot exercise — it needs the
native plugin loaded into a real app — so it has its own suite that runs against
a real shell:

```bash
for suite in integration_test/*_test.dart; do flutter test "$suite" -d macos; done
```

One file at a time is deliberate: on desktop, Flutter relaunches the app for
each test file, and a second launch inside a single `flutter test` invocation
fails with "Unable to start the app on the device".

`tui_acceptance_test.dart` is the acceptance criterion the brief named: it runs
`vim` and a process monitor for real, through the whole pipeline, and judges
them on what ends up in the emulator's buffer — the alternate screen, absolute
cursor addressing, a wrap point that only the program can decide, and a clean
restore on exit. It runs `htop` where it is installed and `top` otherwise; both
exercise the same emulator behaviour.

CI additionally runs the architecture and coverage gates:

```bash
./tool/check_domain_purity.sh
./tool/check_coverage.sh
```

---

## Architecture in one paragraph

Everything hangs off a single `TerminalBackend` interface: a bidirectional byte
stream with resize control. A local PTY, a remote SSH session and a replayed
test fixture are all implementations of it, so the terminal UI never knows what
it is attached to. Layers point inward — `lib/domain/` is pure Dart with no
Flutter imports, enforced in CI. The full picture, including why there is no
separate web backend and why the web relay never sees your plaintext, is in
[ARCHITECTURE.md](ARCHITECTURE.md).

## Security

Private keys and passwords live only in the platform keystore, host key changes
are a hard stop, and there is no telemetry. The threat model — including what
Termino explicitly does *not* protect against — is in
[SECURITY.md](SECURITY.md).

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| 0 | Plan, scaffold, CI, verified dependency stack | **done** |
| 1 | Terminal core: design system, `TerminalBackend`, session model | **done** |
| 2 | Local PTY, shell profiles, `PlatformCapabilities` | **done** |
| 3 | SSH: auth, host key verification, profiles, jump hosts | **done** |
| 4 | Input: key accessory bar, gestures, selection, search, tabs, splits | **done** |
| 5 | SFTP browser and port forwarding | **done** |
| 6 | Themes, settings, onboarding, error taxonomy, session recording | |
| 7 | Web: reference relay and WebSocket transport | **done** |
| 8 | Release: signing, icons, store pipelines | **done** |

Notable decisions and their reasoning are logged in
[DECISIONS.md](DECISIONS.md).

## Releasing

Icons and the splash screen are generated rather than hand-drawn, and a `v*`
tag builds every platform:

```bash
flutter test test/tools/generate_icon_test.dart --update-goldens
dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

Signing material and store credentials cannot live in the repository; what you
need to supply is listed in [docs/RELEASING.md](docs/RELEASING.md). The release
workflow builds unsigned artifacts without any of it, so a fork still works.

## Licence

[Apache-2.0](LICENSE).

Termino builds on [`xterm.dart`](https://github.com/TerminalStudio/xterm.dart),
[`dartssh2`](https://github.com/vicajilau/dartssh2) and
[`flutter_pty`](https://github.com/TerminalStudio/flutter_pty), all MIT licensed.
