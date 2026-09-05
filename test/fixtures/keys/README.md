# Test keys

**Generated for testing only. Never valid for any real host.**

These key pairs exist so that the `known_hosts` and `~/.ssh/config` parsers, the
key importer and the SSH integration tests can be checked against data OpenSSH
actually produces rather than data hand-written to match the parser.

They are committed deliberately, and are the one exception to "never commit
secrets" in `docs`/`SECURITY.md`. Regenerate with `tool/generate_test_keys.sh`.
