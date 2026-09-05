# Decision log

Newest first. Each entry records what was decided, what else was considered, and
why — so that a future reader can tell a deliberate choice from an accident.

---

## 2026-09-05 — `custom_lint` dropped; `riverpod_lint` kept

**Decision.** Use `riverpod_lint` 3.1.9 without `custom_lint`.

**Alternatives.** Keep both (impossible); drop `riverpod_lint` too; pin
`riverpod` back to 3.1.0 to satisfy an older `riverpod_lint`.

**Why.** Version solving fails with both: `custom_lint` 0.8.x requires
`analyzer ^8`, while `riverpod_lint` 3.1.9 requires `analyzer >=13 <15` and
`analyzer_plugin ^0.14`. `riverpod_lint` has moved off `custom_lint` onto the
analyzer plugin API directly, and it pins `riverpod 3.4.3` — exactly the version
we run. So `custom_lint` is the stale one, and dropping it costs nothing today.
Revisit only if we want a third-party lint that still requires `custom_lint`.

---

## 2026-09-05 — Android `compileSdk` pinned to 37

**Decision.** Pin `compileSdk = 37` in `android/app/build.gradle.kts` rather
than tracking `flutter.compileSdkVersion`.

**Why.** `flutter_secure_storage` 11.x requires consumers to compile against API
37; Flutter 3.47's default is 36, so the build fails outright without this. AGP
9.1 warns that 36 is its maximum *recommended* compileSdk, but the build is
otherwise clean. `minSdk` (24) and `targetSdk` (36) still track Flutter's
defaults, because compiling against newer APIs is independent of opting into new
runtime behaviour. Revisit when Flutter's default reaches 37.

---

## 2026-09-05 — The PTY plugin sits behind a conditional export

**Decision.** No file may `import 'package:flutter_pty/flutter_pty.dart'`
directly. All access goes through
`lib/core/capabilities/local_shell_support.dart`, which conditionally exports an
FFI implementation or a stub.

**Alternatives.** Drop the web target; fork `flutter_pty` to make it
web-tolerant; guard with runtime `kIsWeb` checks.

**Why.** `flutter_pty` depends on `dart:ffi`, which does not exist on the web,
and this is a *compile-time* failure — the web build dies with "Dart library
'dart:ffi' is not available on this platform" no matter what runtime guard sits
in front of it. Runtime checks cannot fix a link error. Discovered during the
Phase 0 smoke test, before any code depended on the wrong shape.

The seam also documents the real distinction: whether the plugin can be
*compiled in* (no, on web) is a different question from whether a shell may be
*spawned* (no, on iOS and web), and the second belongs to
`PlatformCapabilities`.

---

## 2026-09-05 — SSH on the web runs in the browser, not in the relay

**Decision.** There is no `WebSocketRelayBackend`. `SshBackend` takes an
`SshSocketFactory`; the web injects a WebSocket `SSHSocket` and the relay is a
dumb TCP tunnel.

**Alternatives.** The originally specified design — a distinct backend that
frames a byte stream to a relay which terminates SSH itself.

**Why.** `dartssh2` 4.0.0 fixed AEAD ciphers and SFTP under dart2js
specifically so the protocol can run in a browser, and documents the custom
`SSHSocket` pattern. Running SSH client-side means the relay never sees
plaintext, never handles a private key, and cannot impersonate a host: host key
verification still happens on the user's device. A relay that terminates SSH
would become the single most attractive target in the system. Same amount of
code, strictly better security, and one fewer backend to test.

---

## 2026-09-05 — Drift, not Isar, for local persistence

**Decision.** `drift` 2.34.4 with `drift_flutter` and `sqlite3` 3.5.2.

**Why.** Not a real choice: `isar` 3.1.0+1 was last published in April 2023 with
a Dart 2 SDK constraint and will not resolve against Dart 3.13. Drift is
actively maintained and supports all six targets. Note that `drift_flutter`
0.3.1 still pulls `sqlite3_flutter_libs`, now marked end-of-life because
`sqlite3` 3.x bundles the native libraries itself; harmless today, worth
revisiting when `drift_flutter` updates.

---

## 2026-09-05 — Riverpod 3 with code generation, not Bloc

**Decision.** `flutter_riverpod` 3.4.3 + `riverpod_generator` 4.0.9.

**Alternatives.** Bloc; Riverpod 2.

**Why.** Riverpod provides state *and* dependency injection in one system, which
this app needs a great deal of: `PlatformCapabilities`, `SessionManager`, one
backend per session, and the host/identity repositories all want overridable
injection for tests. `autoDispose`/`keepAlive` map directly onto session
lifetime. Bloc's event-and-state ceremony fits discrete user actions, not a
continuous byte stream that is mostly forwarded rather than reduced. Riverpod 3
rather than the 2.x named in the brief simply because 3.x is current and 2.x is
legacy.

---

## 2026-09-05 — `xterm` adopted despite being under-maintained

**Decision.** Depend on `xterm` 4.0.0 from pub, but **wrap it behind our own
terminal widget** so that swapping or vendoring it touches one file.

**Alternatives.** Fork immediately; write an emulator from scratch; use one of
the small alternative packages.

**Why.** `xterm` was last released in February 2024 and last committed in June
2025, with 107 open issues — a real risk for the most important dependency in
the project. But it is also the only credible option: ~287k downloads a month,
150/160 pub points, and verified to already use the modern
`KeyEvent`/`HardwareKeyboard`/`TextScaler` APIs, so it compiles cleanly on
Flutter 3.47. Writing a correct VT100/xterm emulator from scratch is a project
in itself and would sink the schedule.

The mitigation is containment, not optimism: nothing outside our terminal widget
imports `xterm` types, and master already carries unreleased fixes we can vendor
if we must.

**Known gaps to plan around.** No search API (we build search on `Buffer` +
`TerminalHighlight`) and no OSC 8 hyperlink support (see below).

---

## 2026-09-05 — OSC 8 hyperlinks deferred; regex linkification in v1

**Decision.** v1 makes bare URLs in the buffer tappable by scanning visible
text. True OSC 8 is a tracked post-v1 item.

**Alternatives.** Fork `xterm` now to add per-cell URL attribution; drop
linkification entirely.

**Why.** `xterm`'s escape handler exposes only `setTitle` and `unknownOSC`;
there is no per-cell URL attribution in its cell model, so honouring OSC 8
properly means forking the buffer, the parser and the painter. Doing that in
Phase 1 would fork the project's most important dependency before we have shipped
anything. Regex linkification covers the common case — a URL printed by `curl`,
`npm` or `git` — at a fraction of the cost. The honest limitation, recorded so
nobody is surprised: text hyperlinked behind a label will not render as a link.

---

## 2026-09-05 — `flutter_pty` adopted, with `flutter_pty2` as a live fallback

**Decision.** Use `flutter_pty` 0.4.2, isolated behind `LocalPtyBackend`.
Re-evaluate `flutter_pty2` during Phase 2.

**Why.** `flutter_pty` was last released in January 2025 and has 18 open issues.
The Phase 0 build surfaced a concrete symptom: Flutter warns that it *does not
support Swift Package Manager* on iOS and macOS, and that this "will become an
error in a future version of Flutter". The `flutter_pty2` fork has already added
SPM support and a fix for draining output after the child exits — but it has
almost no adoption, so it trades a maintenance risk for a trust risk. Deciding
now would be premature; deciding behind an interface costs one file either way.

---

## 2026-09-05 — v1 targets macOS, Android and iOS

**Decision.** Ship v1 on macOS, Android and iOS. Keep Linux and Windows building
in CI throughout; promote them to first-class in Phase 8.

**Why.** The development machine can build macOS, iOS, Android and web, but
**not Linux or Windows** — those can only ever be verified by CI here. Rather
than claim a quality bar we cannot observe, they stay green in CI and get their
polish pass when someone can actually run them. iOS is included from Phase 3
because it costs little: SSH is pure Dart and the UI is shared, so the only
iOS-specific work is gating the local shell honestly.

---

## 2026-09-05 — Apache-2.0, `com.termino.app`

**Decision.** Apache-2.0 licence; bundle identifier `com.termino.app` on every
platform.

**Why.** Apache-2.0 is permissive like the dependencies (`dartssh2` and `xterm`
are both MIT) but adds an explicit patent grant, which is the safer default for
a security-adjacent tool. GPL-3 was considered and rejected because it would
foreclose a Mac App Store release.
