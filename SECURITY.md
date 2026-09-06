# Security

Termino handles SSH private keys, passphrases and passwords, and shows you the
output of shells on machines you care about. This document states what it
protects, what it does not, and how to report a problem.

## What is verified, and where

The claims below are not aspirations. Each is held in place by a test:

| Claim | Test |
|---|---|
| A changed host key blocks the connection | `test/infrastructure/ssh/ssh_backend_test.dart` — against a real OpenSSH server that has genuinely swapped its key |
| A changed key is never offered as a prompt | same file: the prompt callback is asserted never to run |
| A log line containing a secret is redacted | `test/core/logging/redaction_test.dart` |
| No secret reaches the database file | `test/security/secrets_never_persisted_test.dart` — the file is read back off disk and searched |
| Deleting an identity or host removes its key material | same file |
| A failure message never leaks an exception string | `test/infrastructure/ssh/ssh_backend_test.dart` |

## Reporting a vulnerability

Please report privately rather than opening a public issue: open a
[GitHub security advisory](https://github.com/termino/termino/security/advisories/new)
on this repository. We aim to acknowledge within 72 hours.

Please include what you did, what happened, and what you expected. If a proof of
concept touches a real host, redact hostnames and keys.

---

## Threat model

### What Termino defends against

| Threat | Defence |
|---|---|
| A stolen device with the app installed | Secrets live in the platform keystore (Keychain, Android Keystore, libsecret, DPAPI), never in the app's own database or preferences. An optional per-identity biometric or PIN gate stands in front of using one. |
| A man-in-the-middle on the network | Host keys are verified against a persistent `known_hosts` store. A first sighting prompts with the fingerprint; **a changed key is a hard, blocking stop and is never auto-accepted.** `dartssh2` 4.x also terminates the connection if the host key changes during a rekey. |
| Secrets leaking into diagnostics | The logger redacts passwords, passphrases, private key material, authentication banners and the session byte stream. A unit test asserts that a log line containing a known secret comes out redacted. |
| Secrets leaking into the database | Connection profiles are stored in drift; secrets never are. A test asserts that no secret string appears in the database file. |
| A compromised web relay | The relay is a TCP tunnel, not an SSH endpoint. SSH runs in the browser, so the relay sees only ciphertext, never a private key, and cannot impersonate a host — key verification happens on your device. A test asserts it: a marker typed into a session does not appear in the bytes the relay carries. See [ARCHITECTURE.md](ARCHITECTURE.md#there-is-no-separate-web-backend). |
| An open proxy in the relay | The relay refuses to start without an explicit destination allowlist, and supports a shared-secret token. See [tools/relay/README.md](tools/relay/README.md). |
| Weak negotiated cryptography | `dartssh2` 4.0.0 removed SHA-1 key exchange, `ssh-rsa` host key signatures and CBC ciphers from the default proposals, matching OpenSSH. A server offering only those will fail to negotiate rather than connect weakly. |
| Telemetry exfiltration | There is none. No analytics, no crash reporting, no phone-home. If any is ever added it will be opt-in and documented here. |

### What Termino does not defend against

- **A compromised host operating system.** A device with a keylogger, a
  malicious root user, or a debugger attached to the process can read anything
  the app can read. Platform keystores raise the cost of extraction; they do not
  make it impossible.
- **A forged relay certificate, in the web build.** A browser does not expose
  the certificate of a WebSocket connection, so the app has no mechanism to pin
  it; the browser's certificate authorities are the only check. An attacker who
  fully controls the relay can deny service and learn which hosts you connect to
  and when. They cannot read a session or impersonate a server, because SSH runs
  on your device and the host key is checked there. Native builds do not use a
  relay at all.
- **A compromised remote server.** If you connect to a machine an attacker
  controls, they see everything you type in that session. That is what SSH is
  for, not something a client can prevent.
- **A user who accepts a changed host key.** The dialog is deliberately hard to
  dismiss by accident, but a determined user can still override it.
- **Shoulder surfing and screenshots.** Terminal contents are rendered on
  screen, and on desktop the OS may capture them.
- **The local database.** `termino.sqlite` holds connection profiles, key
  *metadata* and trusted host fingerprints. It is not encrypted, and it is not
  meant to be: nothing secret is in it, which is a property under test rather
  than a convention.
- **Memory forensics.** Dart does not offer reliable zeroing of immutable
  strings. Decrypted key material is held for the duration of an authentication
  attempt and dropped afterwards, and we zero byte buffers where the language
  allows it, but a heap dump taken at the wrong moment may still contain
  secrets.

---

## Handling rules

These are enforced in review and, where the wording says so, in tests:

1. Private keys, passphrases and passwords go **only** into
   `flutter_secure_storage`. Never into drift, preferences, logs, crash reports
   or analytics.
2. Passphrase-protected keys stay encrypted at rest and are decrypted in memory
   only for the duration of an authentication attempt.
3. A host key mismatch is a hard stop, never a warning that can be clicked past
   casually.
4. No raw exception string is shown to the user; errors are mapped through a
   taxonomy so that an error message cannot leak internal state.
5. Test keys live in `test/fixtures/keys/`, are clearly marked as generated for
   testing, and are never valid for any real host.

## Cryptography

Termino implements no cryptography of its own. Key exchange, ciphers, MACs,
signatures and private key parsing are all `dartssh2`, which is pure Dart and
actively maintained. Where we need primitives outside SSH we use `pointycastle`
rather than hand-rolling.
