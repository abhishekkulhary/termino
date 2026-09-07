# Decision log

Newest first. Each entry records what was decided, what else was considered, and
why — so that a future reader can tell a deliberate choice from an accident.

---

## 2026-09-05 — Staying on `flutter_pty`, on the evidence

**Decision.** Keep `flutter_pty` 0.4.2. Do not move to the `flutter_pty2` fork
yet. Revisit when Flutter actually makes Swift Package Manager mandatory.

**Alternatives.** Switch to `flutter_pty2` 1.0.2, which is actively maintained,
has adopted SPM, and carries a commit titled "drain output after child exit".

**Why.** The case for the fork rested on two claims, and integration tests
against a real shell on macOS settled both:

* **"Output is lost when the child exits."** `flutter_pty` closes its output
  port the instant the exit status arrives, and its own documentation warns
  that buffered output may not have been delivered. A test that runs
  `sh -c 'echo FINAL-LINE-MARKER'` and asserts the marker arrives passed five
  times out of five. The failure the fork fixes does not reproduce through our
  pipeline, so switching would trade a known-good dependency for an unknown one
  to fix a problem we cannot observe.
* **"SPM adoption is required."** Flutter warns on every iOS and macOS build
  that `flutter_pty` does not support Swift Package Manager and that this "will
  become an error in a future version". It is not an error today, and CocoaPods
  still works.

Against that, `flutter_pty2` has one GitHub star and roughly a hundred downloads
a month. Adopting it means running someone's unreviewed native code in a process
that holds the user's SSH keys. That is a real security trade, not just a
maintenance one.

The mitigation stands either way: `LocalPtyBackend` isolates the plugin, so the
swap is one file whenever the evidence changes.

**What the integration tests proved works**: spawning, output, input, exit
codes, resize (`stty size` confirms 37 rows by 101 columns, which also catches
the reversed argument order), missing-executable handling, and termination on
close.

---

## 2026-09-05 — The macOS App Sandbox is off for direct distribution

**Decision.** `com.apple.security.app-sandbox` is `false` in both macOS
entitlement files, with `com.apple.security.network.client` enabled for SSH. A
sandboxed Mac App Store flavour, with the local shell feature-gated off, is a
separate build configuration for Phase 8.

**Alternatives.** Keep the sandbox and ship a local shell that can only run
programs inside the app bundle; ship SSH-only on macOS.

**Why.** A terminal emulator exists to run programs the user chooses, anywhere
on their disk, with their own permissions. The sandbox forbids exactly that. A
sandboxed build would offer a shell that cannot see the user's files or run
their tools, which is worse than offering none. Every macOS terminal emulator
makes this same trade, and it is why they are distributed outside the App Store.

The consequence is stated plainly rather than buried: the App Store build will
be SSH-only, and `PlatformCapabilities` is already the mechanism that will turn
the local shell off for it.

---

## 2026-09-05 — The PTY uses native flow control (`ackRead`)

**Decision.** `LocalPtyBackend` starts the PTY with `ackRead: true` and
acknowledges each chunk as it passes into the pipeline.

**Why.** Without it, the native read thread pushes into the isolate's port queue
as fast as the child can write, and nothing bounds that queue — a process
running `yes` grows memory without limit. With it, the read thread waits for an
acknowledgement, so a paused terminal stops acknowledging, the child blocks on
its own write, and memory stays flat. This is the last link in the backpressure
chain that starts at the terminal widget and now reaches the child process
itself.

---

## 2026-09-05 — Backend output is a single-subscription stream

**Decision.** `TerminalBackend.output` is single-subscription, not broadcast.
Anything else that wants to observe output — session recording in Phase 6 —
taps the session downstream rather than the backend.

**Why.** A broadcast stream cannot apply backpressure: pausing one listener does
not pause the source. With a broadcast stream a process writing faster than the
terminal can render grows an unbounded queue in memory, which is precisely the
failure the performance targets exist to prevent. One subscriber means a paused
terminal pauses the socket. This constraint propagates: the coalescing sink
forwards pause and resume to its source, and `TerminalBackendBase.pipeOutput`
wires the two together.

---

## 2026-09-05 — `ConnectionState` renamed to `BackendConnectionState`

**Decision.** The backend lifecycle enum from the brief is called
`BackendConnectionState`.

**Why.** Flutter already exports a `ConnectionState`, from `AsyncSnapshot`, and
presentation code uses it constantly. Two identically named enums, one of them
imported implicitly through `package:flutter/material.dart`, is an import shadow
waiting to confuse someone. The extra word costs nothing.

---

## 2026-09-05 — Fonts are bundled, not borrowed from the system

**Decision.** Ship JetBrains Mono patched by Nerd Fonts — four faces, about
10 MB — in `assets/fonts/`, and load them in golden tests too.

**Alternatives.** Rely on the system monospace font; ship unpatched JetBrains
Mono (roughly 800 KB for four faces).

**Why.** Terminal output is full of box drawing, block elements and Powerline
separators. A system monospace font that lacks them renders tofu in the middle
of `htop`, and which glyphs are present varies by platform and by OS version —
so the app would look broken on some machines and fine on others, unpredictably.
10 MB is a real cost and worth it for a terminal.

Loading the real fonts in golden tests matters for the same reason: `flutter
test` substitutes a placeholder that draws every glyph as a box, and boxes are
exactly what a *missing* glyph looks like. A golden rendered with the
placeholder would prove nothing about the thing most worth proving.

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

> **Superseded on 2026-09-07.** OSC 8 is supported, and no fork was needed. The
> reasoning below was sound about xterm's cell model and wrong about the only
> way in: `Terminal.onPrivateOSC` fires while the sequence is parsed, which is
> enough to attribute the cells from outside. See the 2026-09-07 entry.

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

## 2026-09-07 — OSC 8 hyperlinks, without vendoring xterm

**Decision.** Track OSC 8 links outside the emulator, in `TerminalHyperlinks`,
and confirm every declared link before opening it. This **supersedes** the
Phase 0 decision that true OSC 8 needs an xterm fork.

**Why the fork turned out to be unnecessary.** The original finding stands —
xterm.dart has no per-cell URL attribution and its escape handler exposes only
`setTitle` and `unknownOSC`. What was missed is that `Terminal.onPrivateOSC`
fires **synchronously while the sequence is being parsed**. At that instant the
buffer's cursor is exactly where the link begins, and at the closing sequence
exactly where it ends. That is enough to attribute the cells in between without
touching the emulator, and it was verified before any of this was written: a
link opening at column 4 and closing at column 13 reports precisely that, and a
link that wraps reports line 0 column 2 through line 2 column 2.

Spans hang off the `BufferLine` objects in an `Expando`. A line object travels
with its content as the screen scrolls, so a link stays on its text with no
bookkeeping at all, and a line trimmed off the top of the scrollback takes its
spans with it into the garbage collector.

**Why a declared link asks first.** OSC 8 lets a program choose the words and
the destination separately: `docs` can point anywhere. A URL recognised in the
visible text does not have that gap — the text *is* the destination — so it
opens directly. A declared one shows where it actually goes and waits. The
scheme allow-list is applied twice, once when the span is recorded and again
when it is acted on.

**What it does not cover.** A line erased and rewritten in place — which a
full-screen program on the alternate buffer does constantly — keeps its
`BufferLine` object, so a span can outlive the text it described. The
consequence is a stray underline, never a wrong destination.

**What could not be tested.** The tap gesture itself. xterm's
`TerminalGestureHandler` uses a `RawGestureDetector` that defers to its child,
and under the widget-test binding a tap never reaches `onTapUp` — checked
against a bare `TerminalView` with nothing of ours in the tree. The decision was
therefore extracted into `TerminalHyperlinks.actionAt`, which is tested
thoroughly; the gesture that calls it is xterm's and is exercised only by
running the app.

---

## 2026-09-05 — Apache-2.0, `com.termino.app`

**Decision.** Apache-2.0 licence; bundle identifier `com.termino.app` on every
platform.

**Why.** Apache-2.0 is permissive like the dependencies (`dartssh2` and `xterm`
are both MIT) but adds an explicit patent grant, which is the safer default for
a security-adjacent tool. GPL-3 was considered and rejected because it would
foreclose a Mac App Store release.

---

## 2026-09-07 — ZModem multiplexed here, not by `xterm`, and two `zmodem` defects worked around

**Decision.** Carry `rz` / `sz` transfers in `ZModemTransfers`
(`lib/features/terminal/application/zmodem_transfers.dart`), using the `zmodem`
package as a direct dependency rather than `xterm`'s `ZModemMux`. Correct the
hex-header terminator on every byte we transmit.

**Why.** Three things were checked against the published packages before this
was written, and each one is a defect the app has to route around.

1. **`xterm`'s `ZModemMux` cannot see a header at the end of a chunk.** Its scan
   is `i < length - other.length`, so a header is only found when at least one
   further byte arrives in the same chunk. `sz` announces itself and then waits
   for a reply, so its header is routinely the last thing in a chunk — and a
   chunk that *is* the header is never matched at all. Probed directly: a header
   at the end of a buffer returned `null`, the same header with one byte after
   it returned `6`. Our scanner is inclusive of the end of the buffer, and the
   two cases have tests.

2. **The `zmodem` package cannot parse its own hex headers.** Its encoder
   (`zmodem_frame.dart`) terminates them with `CR LF` — `0x0d 0x0a` — while its
   parser (`zmodem_parser.dart`) requires `0x8a`, the line feed with the high bit
   set. Feeding its own sender's output into its own receiver fails with
   `Bad state: Expected 0x8a, got 0xa`. The parser is the one that matches
   reality: lrzsz's `zshhdr` sends `015 0212`, i.e. `0x0d 0x8a`. So
   `ZModemTransfers.correctHexTerminators` puts the high bit back on every
   header we send. lrzsz masks the high bit off when reading and would very
   likely have accepted the uncorrected form, but "probably accepted by an
   implementation we cannot test against here" is not a thing to ship — emitting
   exactly what the reference implementation emits is.

3. **The package prints on every data subpacket.** `zmodem_parser.dart:58` has a
   leftover `print('expectDataSubpacket')`. It does not corrupt the stream — it
   goes to the platform log, not to the terminal — but a large transfer will
   write tens of thousands of lines to the device log. Not worked around, because
   the only fix is vendoring the package. Flagged as the reason to vendor if
   anything else in it needs changing.

**What this costs.** A direct dependency on `zmodem` 0.0.6, a package at version
zero-point-zero. The blast radius is one file: `TerminalSession` holds it behind
a nullable field, so a build without it has byte-for-byte the pipeline it had
before ZModem existed.

**Safety.** An incoming file is a **prompt**, never an automatic save. A host
that has been tampered with must not be able to write to someone's disk because
they happened to have a shell open. The filename comes from the far end, so it
is reduced to its last path segment with leading dots stripped
(`../../.bashrc` becomes `bashrc`), it never overwrites an existing file, and a
cancelled transfer deletes the partial file rather than leaving a truncated one
under the name of a real one.

---

## 2026-09-07 — SSH agent authentication, on macOS and Linux only

**Decision.** Add `SshAuthMethod.agent`, which offers the keys held by the
system SSH agent as `dartssh2` identities. Gate it to macOS and Linux.

**Why.** It is the only way to use a key this app *cannot hold*: a key in a
Secure Enclave (Secretive), in 1Password, or on a YubiKey never leaves the
device it lives on, and can only ever be used by asking its holder to sign.
It is also the better answer for keys the app *could* hold — the private key
never enters this process, so nothing here can leak it, log it, or fail to
delete it.

`dartssh2` 4.1.0 makes this clean: `SSHIdentity.custom` takes a public key and
a signing callback, and its own documentation names OS agents as the case it
exists for. `SshAuthPrompts.identities` widened from `List<SSHKeyPair>` to
`List<SSHIdentity>` accordingly, so agent keys and imported keys are offered
side by side.

**The platform limitation, stated plainly.** Windows is **not** supported.
Its OpenSSH agent listens on a named pipe (`\\.\pipe\openssh-ssh-agent`), and
Dart has no way to open one — there is no `dart:io` API for named pipes, and no
package that adds one without an FFI shim to `CreateFileW`. Rather than ship a
control that fails there, `PlatformCapabilities.canUseSshAgent` is false on
Windows and the option is not offered. **Options if this matters:** write a
small FFI binding for the four Win32 calls involved, or shell out to
`ssh-add -L` and `ssh-keygen -Y sign` and parse the output. Neither is worth
doing before someone actually runs the Windows build.

**RSA signs with SHA-2.** A key whose blob says `ssh-rsa` is asked to sign with
`rsa-sha2-512` and the `SSH_AGENT_RSA_SHA2_512` flag. `ssh-rsa` names an SHA-1
signature, which OpenSSH 8.8 and later refuse by default, so asking for the
key's own type would fail against any current server. Verified against a real
`ssh-agent`: the signature blob comes back labelled `rsa-sha2-512`.

**How it is verified.** `test/infrastructure/ssh/agent/ssh_agent_test.dart`
starts a real `ssh-agent`, loads the fixture keys into it, starts a real `sshd`
that trusts one of them, and authenticates. The claim being tested — that the
private key never enters this process — cannot be checked against a fake, since
a fake would be holding the key in the same process.

---

## 2026-09-07 — Folder transfers are planned before they run, and skip links

**Decision.** Downloading or uploading a folder walks the whole tree first,
producing a `TransferPlan`, then creates every directory, then queues one
transfer per file. Symbolic links are skipped and counted. The walk stops at
2000 files or 32 levels.

**Why plan first.** Queuing as the walk proceeds would be simpler and answers
none of the three questions the UI has to answer the moment someone taps
"download": how many files, how many bytes, and was anything left out. It also
means the directories exist before a single byte moves — a transfer that fails
half way leaves the shape it was going to fill rather than a half-built tree
with files in the wrong places.

**Why links are skipped rather than followed.** Two failure modes, neither
hypothetical, both reproduced in tests against a real server: a link pointing at
an ancestor makes the walk recurse until it exhausts something, and a link to a
device or a fifo makes a "file" with no end. Following them is not what anyone
means by "copy this folder". They are counted and the count is shown, because a
transfer that silently omitted things would look like one that had finished.

**Why there are limits.** A mistaken tap on `/` should not spend twenty minutes
listing a server's whole filesystem before anything visible happens. Hitting a
limit is reported in the same sentence as the file count.

**Two things that had to change underneath.** SFTP has no `mkdir -p`, so
`ensureDirectory` treats "already exists" as success — but verifies by `stat`
that what exists is a directory, because some servers report "exists" and
"permission denied" with the same status code. And `rmdir` refuses a non-empty
directory, so deleting an entry now removes a directory's contents first; before
folders could be transferred there was nothing to delete recursively.

**Where the remote path comes from.** The server's resolved path, not the one
typed: macOS reports `/var/...` as `/private/var/...`, and an upload built from
the unresolved path would write somewhere other than where the user is looking.
That is asserted in `folder_session_test.dart`.

---

## 2026-09-07 — Downloads ask once, on desktop only

**Decision.** On a platform with a folder chooser, the first download asks where
to save and the answer is remembered in settings. Elsewhere downloads go to the
app's documents folder without asking. `Download to…` on a file's menu asks
again for a one-off.

**Why once and not every time.** A chooser on every download is worse than no
chooser: the common case is a run of files going to the same place, and a dialog
between each of them is the thing people disable software over. Remembering also
gives the Settings row something to show, so the destination is discoverable
without performing a download to find out.

**Why not on mobile.** The app's own documents folder is the only place a
download can go on iOS or Android, so a chooser there is a decision with one
option. The capability is `canChooseFolders` rather than reusing
`hasWindowManagement`, which today has the same value: one is about windows and
the other about files, and a flag that means two things will eventually be wrong
about one of them.

**Why a cancelled chooser cancels the download.** Falling back to the app folder
would answer a question the user just declined to answer, and put the file
somewhere they would then have to go looking for.

**Why the remembered folder is re-checked.** It can be on a disk that is no
longer mounted, or a directory since deleted, or — because settings travel
through a backup — a path from another machine entirely. Without the check every
download after that fails one at a time with a filesystem error and nothing
pointing at the cause. A folder that is not there means "ask again".

---

## 2026-09-07 — The test harness detects losing a race for its port

**Decision.** `TestSshd` holds its reserved port until the moment `sshd` starts,
watches for `sshd` exiting, and retries on a different port when it lost the
race. A caller that named an explicit port gets an error instead of a retry.

**Why.** The harness reserved a port by binding and releasing it, then spent
tens of milliseconds writing config files before `sshd` bound it for real.
If another suite took the port in that window, `sshd` failed to bind and died —
and the readiness check, which only asked whether *something* was listening,
connected to the other suite's server and reported success. The test then ran
against a server with a different host key, a different `authorized_keys` and a
different working directory.

Reproduced directly: two `TestSshd.start()` calls on the same port both
"succeeded", and the banner came from the first server. A losing `sshd` was
measured exiting after about 10 ms with "Address already in use", which is what
makes the detection reliable.

**How likely was it?** Measured, rather than assumed: 240 runs of the old
reserve-release-wait-rebind pattern across six concurrent workers produced
**zero** collisions, because macOS hands out ephemeral ports sequentially rather
than immediately reusing a freed one. So this was a real defect that would have
been very hard to hit — worth fixing because when it did hit, it would have
presented as an unrelated test failing for no visible reason.

---

## 2026-09-07 — One authenticated connection per host, leased

**Decision.** A host is authenticated once. The shell, the file browser and any
port forwards take reference-counted leases on that one connection through
`SshConnectionPool`; the connection closes when the last lease is released.
This **supersedes** the earlier decision that each feature opens its own.

**Why the old decision was wrong.** It bought isolation — a transfer that
killed its connection could not disturb a shell — and charged a second and
third authentication for it. For a host with a password, or a hardware key that
wants a touch, that is three prompts to work on one machine. The isolation was
worth less than it cost.

**Why this is safe protocol-wise.** SSH multiplexes: a shell channel and an
SFTP subsystem live on one transport simultaneously. That is what OpenSSH's
`ControlMaster` does. Verified against a real server rather than assumed —
`shared_connection_test.dart` runs a shell and lists a directory over SFTP on
one connection at the same time, and counts one authentication.

**What is kept from the old isolation.** Reference counting. Closing the file
browser releases a hold and closes nothing while a shell is still open; closing
the last thing on a host disconnects it. Both directions are tested through the
real providers in `one_login_test.dart`, because a pool that everything is
supposed to go through is exactly the sort of thing that gets bypassed later.

**What is genuinely given up.** One dropped TCP connection now takes the shell,
the browser and the forwards together, where before it would have taken one.
That is the same trade `ControlMaster` makes.

**Layering.** `SshBackend` is infrastructure and must not reach up into a
feature, so the contract it depends on — `SshConnectionHold`, which is only
"here is the connection" and "I am finished with it" — is declared beside
`SshConnection`. The pool implements it from the application layer.

**Reconnection.** A shell that drops reconnects through the pool. If the file
browser is still holding the connection up, the new shell attaches to it and
authenticates nothing; if the transport itself died, the pool has already
forgotten it and a fresh connection is made.
