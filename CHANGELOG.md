# Changelog

Notable changes, newest first. Dates are ISO. This project follows
[Semantic Versioning](https://semver.org): the version in `pubspec.yaml` is
`major.minor.patch+build`, and the build number is what the app stores use to
order releases.

## [Unreleased]

### Fixed

- Android: the local shell reported "permission denied" for almost everything.
  An app process starts with its working directory at `/`, which its own UID
  may not read, and with no `HOME`. The shell now starts in the app's private
  directory, with `HOME` and `TMPDIR` set.
- Android: a release build declared no `INTERNET` permission, so every
  connection failed instantly. Flutter's template declares it only for debug
  and profile builds.
- Android: hosts named `*.local` could not be reached at all, because Android
  has no multicast DNS in its resolver. Names are now resolved over mDNS when
  the system resolver has no answer.
- Android: the shell picker offered the same shell twice, under one id, because
  `/bin/sh` is a symlink to `/system/bin/sh`.
- The file browser reported every connection failure with the same sentence.
  Failure classification is now shared with the shell backend, so a wrong
  password, an unreachable host and a changed host key each say so.

### Added

- An acceptance suite that runs `vim` and a process monitor through the real
  pipeline and checks the emulator against what they draw.

## [1.0.0] — 2026-09-06

The first release. Termino is a terminal emulator and SSH client built as one
Flutter codebase for Android, iOS, macOS, Windows, Linux and the web.

### Terminal

- Full VT100/xterm emulation: 256-colour and truecolour, mouse reporting,
  bracketed paste, the alternate screen buffer, and OSC 0/2 window titles.
- Tabs everywhere; split panes on tablets and desktops.
- Regex search through scrollback, including matches that run across a wrapped
  line.
- Pinch to zoom, copy and paste, and selection with a context menu.
- Clickable URLs, recognised in visible output.
- A bundled JetBrains Mono Nerd Font, so box drawing and Powerline glyphs
  render the same everywhere rather than depending on what the system happens
  to have.

### Local shells

- PTY-backed shells on macOS, Linux, Windows and Android, with configurable
  shell profiles.
- Honest feature gating on iOS and the web, which cannot run one, with an
  explanation rather than a missing button.

### SSH

- Password, public key and keyboard-interactive authentication.
- Host key verification against a persistent store. A first sighting prompts
  with the fingerprint; **a changed key blocks the connection** and is never
  offered as a dialog with an accept button.
- Saved connections with jump hosts (`ProxyJump`), keepalives, startup
  commands and agent forwarding.
- Key generation (Ed25519 and RSA-4096) and import of OpenSSH and PEM keys.
- Import from `~/.ssh/config` and `~/.ssh/known_hosts` on desktop.
- Reconnection with exponential backoff when a session drops.

### Files and tunnels

- An SFTP browser: navigate, download, upload, rename, delete, mkdir and
  chmod, with a transfer queue that can be cancelled and retried.
- Local (`-L`), remote (`-R`) and dynamic SOCKS (`-D`) port forwarding with
  live status.

### On mobile

- A key accessory bar with sticky modifiers — tap Ctrl, then C — showing armed
  and locked distinctly, in colour and to a screen reader.
- Hardware keyboard support including modifier chords.
- Snippets: saved commands sent with one tap, optionally scoped to a host.

### Web

- SSH in a browser through a reference WebSocket relay, shipped in
  `tools/relay/`. The relay forwards bytes only: SSH runs in the browser, so it
  carries ciphertext and cannot read a session or impersonate a host.

### Appearance

- Eight terminal palettes: Termino Dark and Light, Dracula, Solarized Dark and
  Light, Nord, Gruvbox Dark and One Dark.
- Font size, line height, cursor shape and blink, bell behaviour and scrollback
  size, all persisted.

### Other

- Session recording, exported as plain text or asciicast v2. Output only —
  never keystrokes.
- No telemetry of any kind.

[Unreleased]: https://github.com/termino/termino/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/termino/termino/releases/tag/v1.0.0
