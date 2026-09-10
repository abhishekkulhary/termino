# Store listing

Copy for the app stores. Kept in the repository so it is reviewed like anything
else, and so the claims in it stay true as the app changes.

## Name

Termino

## Subtitle / short description (80 characters)

A terminal and SSH client for every device you own.

## Full description

Termino is a terminal emulator and SSH client. It runs a real shell on your
computer, and connects over SSH to the machines you look after.

**A real terminal.** Full xterm emulation, so vim, htop and tmux behave the way
they do anywhere else — 256 colours and truecolour, mouse reporting, the
alternate screen, and a bundled font with the box-drawing and Powerline glyphs
those programs assume.

**SSH that takes host keys seriously.** Password, public key and
keyboard-interactive authentication. The first time you connect, Termino shows
you the server's fingerprint and asks. If that key ever changes, the connection
is refused — not warned about, refused — because a changed key is
indistinguishable from someone intercepting you.

**Your keys stay on your device.** Private keys live in the system keystore,
never in the app's database and never in a log, optionally behind a biometric
check. Generate an Ed25519 or RSA key in the app, or import one you already
use. Nothing is uploaded anywhere: Termino has no account, no sync service and
no telemetry.

**Built for a phone as well as a desk.** A key bar with the Esc, Tab, Ctrl and
arrow keys a touch keyboard does not have, with modifiers you tap once to arm
and twice to lock. Snippets for the commands nobody remembers. Pinch to zoom.
Tabs everywhere, split panes where there is room.

**Files and tunnels.** An SFTP browser with a transfer queue you can cancel and
retry. Local, remote and dynamic SOCKS port forwarding with live status.

**Everywhere.** Android, iPhone, iPad, Mac, Windows, Linux and the web, from
one codebase, with the same settings and the same nine colour schemes.

### A note on what this app cannot do

iOS does not allow an app to launch other programs, so there is no local shell
on iPhone or iPad — SSH works normally. A browser cannot open a network
connection directly, so the web version reaches SSH servers through a relay you
run yourself. Termino says so in the app rather than hiding the buttons.

## Keywords

terminal, ssh, sftp, shell, console, tunnel, port forwarding, developer, sysadmin

## Category

Developer Tools (primary) · Utilities (secondary)

## Privacy

Termino collects nothing. There is no analytics, no crash reporting and no
account. Data — connection profiles, keys, settings — stays on the device, and
keys specifically stay in the platform keystore.

Both stores ask for a data-safety declaration. The honest answers:

| Question | Answer |
|---|---|
| Does the app collect or share user data? | No |
| Does the app use encryption? | Yes — SSH, and the platform keystore |
| Is data transmitted off the device? | Only to the servers the user chooses to connect to |
| Is there a way to request data deletion? | Not applicable; nothing leaves the device |

### Export compliance

The app uses standard, publicly available cryptography (SSH) for
authentication and transport. For App Store Connect,
`ITSAppUsesNonExemptEncryption` is set to `false` in `Info.plist`, which is the
correct answer for an app whose only cryptography is a standard secure
protocol.

## Screenshots to capture

Framed at each store's required sizes. What actually demonstrates the app:

1. A terminal running `htop`, showing colour and box drawing.
2. The host list, with a few saved connections.
3. The host key prompt, showing a fingerprint.
4. The key bar on a phone, with Ctrl armed.
5. The SFTP browser mid-transfer.
6. The palette picker in Settings.

## Support

- Issues: the GitHub repository's issue tracker
- Security: see SECURITY.md

Both need the real repository URL filling in before either store listing is
submitted.
