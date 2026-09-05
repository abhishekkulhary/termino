#!/usr/bin/env bash
# Coverage gate: 70% on lib/domain and lib/infrastructure, from `flutter test`.
# No gate on UI, which is covered by widget and golden tests instead of a line
# percentage.
set -euo pipefail

LCOV="coverage/lcov.info"
THRESHOLD=70

if [[ ! -f "$LCOV" ]]; then
  echo "error: $LCOV not found. Run: flutter test --coverage"
  exit 1
fi

python3 - "$LCOV" "$THRESHOLD" <<'PY'
import sys

lcov, threshold = sys.argv[1], int(sys.argv[2])
gated = ("lib/domain/", "lib/infrastructure/")

# Files that cannot be reached by `flutter test` because they need a platform
# plugin loaded into a real app. They are not untested — each is listed with the
# suite that does cover it, and CI runs those on a desktop device. Adding to
# this list means writing an integration test, not skipping one.
plugin_backed = {
    "lib/infrastructure/backends/local_pty/local_pty_backend_ffi.dart":
        "integration_test/local_pty_test.dart",
}

current = None
found = hit = 0
tracked_any = False
skipped = []

for line in open(lcov):
    line = line.strip()
    if line.startswith("SF:"):
        path = line[3:].replace("\\", "/")
        excluded = next((f for f in plugin_backed if path.endswith(f)), None)
        if excluded:
            current = None
            if excluded not in skipped:
                skipped.append(excluded)
            continue
        current = any(g in path for g in gated)
        tracked_any = tracked_any or current
    elif current and line.startswith("LF:"):
        found += int(line[3:])
    elif current and line.startswith("LH:"):
        hit += int(line[3:])

for path in skipped:
    print(f"  not unit-gated: {path}")
    print(f"                  covered by {plugin_backed[path]}")

if not tracked_any or found == 0:
    print("No gated source in coverage yet (lib/domain, lib/infrastructure).")
    sys.exit(0)

pct = 100.0 * hit / found
status = "ok" if pct >= threshold else "FAIL"
print(f"Coverage of domain+infrastructure: {pct:.1f}% ({hit}/{found}) [{status}]")
sys.exit(0 if pct >= threshold else 1)
PY
