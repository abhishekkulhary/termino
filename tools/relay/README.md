# Termino relay

A WebSocket-to-TCP relay, so Termino's **web** build can reach an SSH server.
Browsers cannot open a raw TCP socket; this bridges that gap and nothing else.

## What it is not

It is not an SSH server, and it does not terminate SSH. The browser runs the
SSH protocol itself over this tunnel, so what passes through here is
**ciphertext**. The relay:

- cannot read your session, your keystrokes or the output;
- never sees a password or a private key;
- cannot impersonate a server, because the host key the client checks is the
  real server's and the `known_hosts` store it is checked against is on the
  user's device.

That is why the relay is allowed to be this small. It is a pipe, not a trusted
component. A test in the app asserts it — a marker typed into a session appears
on screen and does not appear in the bytes the relay carries.

## Running it

```bash
cd tools/relay
dart pub get
dart run bin/relay.dart --allow build-01.example.com
```

It listens on `127.0.0.1:8022` by default and refuses to start without at least
one `--allow`.

| Flag | Meaning |
|---|---|
| `--allow`, `-a` | A permitted destination, `host` or `host:port`. A bare host allows port 22 only. Repeatable. **Required.** |
| `--address` | Address to bind. Defaults to `127.0.0.1`. |
| `--port`, `-p` | Port to listen on. Defaults to `8022`. |
| `--token` | A shared secret clients must present as `?token=`. |
| `--max-connections` | Simultaneous tunnels. Defaults to 64. |

`*.example.com` matches one subdomain level — `build.example.com` but not
`a.b.example.com`, and not the apex.

## The allowlist is the whole security model

**A relay that accepts any destination is an open proxy.** Anyone who learns
the URL can reach anything the relay's network can reach, from the relay's own
address — including hosts behind a firewall that trusts it. That is a far
bigger exposure than the SSH traffic it was deployed to carry, and it is why
the relay refuses to start without `--allow`.

Deploying it anywhere but loopback, add `--token` as well, and put it behind
TLS.

## TLS, and why the app does not pin the certificate

Put the relay behind a reverse proxy terminating TLS, and give the app a
`wss://` address.

The brief asked for the relay's certificate to be pinned in the web build, or
for a clear explanation of why not. **It cannot be pinned, because a browser
does not expose the certificate.** The WebSocket and fetch APIs give a page no
access to the chain and no hook to reject one, so a web build has no mechanism
to pin with — the browser's own certificate authority set is the only check
available.

What makes that acceptable here is the architecture rather than an argument
about likelihood. A forged relay certificate buys an attacker the position of
the relay, and the relay's position is worthless: it sees ciphertext, and the
SSH host key check happens on the user's device against a store the relay
cannot touch. An attacker who fully controls the relay can deny service and
learn who connects to which host and when — real, and worth saying out loud —
but cannot read a session or impersonate a server.

Pinning is available on the native builds, which do not need a relay at all.

## Health

`GET /health` returns `200 ok`, for a load balancer.

## Tests

```bash
cd tools/relay && dart test
```

The app additionally runs a real SSH session through a real relay to a real
`sshd`; see `test/infrastructure/ssh/sockets/relay_ssh_test.dart`.
