#!/usr/bin/env bash
# Enforces the architecture's one hard rule: lib/domain/ is pure Dart.
#
# The domain layer describes what Termino is (hosts, identities, known hosts,
# shell profiles, the TerminalBackend contract) and must stay testable without
# a Flutter binding and reusable from a CLI or the relay. Importing Flutter,
# or reaching sideways into infrastructure or features, breaks that.
set -euo pipefail

fail=0

check() {
  local pattern="$1" message="$2"
  local hits
  hits=$(grep -rn --include='*.dart' -E "$pattern" lib/domain 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    echo "error: $message"
    echo "$hits" | sed 's/^/  /'
    fail=1
  fi
}

if [[ ! -d lib/domain ]]; then
  echo "lib/domain does not exist yet; nothing to check."
  exit 0
fi

check "^import 'package:flutter/"        "lib/domain must not import Flutter."
check "^import 'package:flutter_"        "lib/domain must not import Flutter plugins."
check "^import 'package:termino/infrastructure/" \
      "lib/domain must not depend on infrastructure (dependency points inward)."
check "^import 'package:termino/features/" \
      "lib/domain must not depend on features (dependency points inward)."

if [[ $fail -eq 0 ]]; then
  echo "lib/domain is pure."
fi
exit $fail
