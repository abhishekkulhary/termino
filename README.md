# Termino

A cross-platform terminal emulator and SSH client, built as a single Flutter
codebase for Android, iOS, macOS, Windows, Linux and the web.

Termino does two things: it gives you a real PTY-backed local shell on every
platform that permits one, and it connects you to remote machines over SSH with
an interactive shell, SFTP file transfer and port forwarding.

> **Status: Phase 1 — terminal core.** The emulator renders, sessions are wired
> end to end, and the app shell adapts across breakpoints — but sessions replay
> a fixture. Real local shells arrive in Phase 2 and SSH in Phase 3. See
> [Roadmap](#roadmap).

---

## Platform support

| Platform | Local shell | SSH | Status |
|---|---|---|---|
| macOS | yes | yes | building |
| Android | yes, sandboxed | yes | building |
| iOS / iPadOS | **no** — not permitted by the platform | yes | building |
| Linux | yes | yes | CI only |
| Windows | yes | yes | CI only |
| Web | **no** | via a relay | building |

iOS cannot spawn arbitrary binaries, and browsers cannot open raw TCP sockets.
Termino does not pretend otherwise: those features are feature-gated off at
runtime with an in-app explanation rather than failing mysteriously. See
[ARCHITECTURE.md](ARCHITECTURE.md#3-platform-capabilities).

Linux and Windows are marked "CI only" because they build and are tested in
continuous integration, but the current development machine cannot run them —
so nobody has yet judged them by eye. They are promoted to first-class in
Phase 8.

---

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
| 2 | Local PTY, shell profiles, `PlatformCapabilities` | next |
| 3 | SSH: auth, host key verification, profiles, jump hosts | |
| 4 | Input: key accessory bar, gestures, selection, search, tabs, splits | |
| 5 | SFTP browser and port forwarding | |
| 6 | Themes, settings, onboarding, error taxonomy, session recording | |
| 7 | Web: reference relay and WebSocket transport | |
| 8 | Release: signing, icons, store pipelines | |

Notable decisions and their reasoning are logged in
[DECISIONS.md](DECISIONS.md).

## Licence

[Apache-2.0](LICENSE).

Termino builds on [`xterm.dart`](https://github.com/TerminalStudio/xterm.dart),
[`dartssh2`](https://github.com/vicajilau/dartssh2) and
[`flutter_pty`](https://github.com/TerminalStudio/flutter_pty), all MIT licensed.
