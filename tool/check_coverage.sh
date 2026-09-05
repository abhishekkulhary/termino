#!/usr/bin/env bash
# Coverage gate: 70% on lib/domain and lib/infrastructure. No gate on UI, which
# is covered by widget and golden tests instead of a line percentage.
set -euo pipefail

LCOV="coverage/lcov.info"
THRESHOLD=70

if [[ ! -f "$LCOV" ]]; then
  echo "error: $LCOV not found. Run: flutter test --coverage"
  exit 1
fi

python3 - "$LCOV" "$THRESHOLD" <<'PY'
import re, sys

lcov, threshold = sys.argv[1], int(sys.argv[2])
gated = ("lib/domain/", "lib/infrastructure/")

current = None
found = hit = 0
tracked_any = False

for line in open(lcov):
    line = line.strip()
    if line.startswith("SF:"):
        path = line[3:].replace("\\", "/")
        current = any(g in path for g in gated)
        tracked_any = tracked_any or current
    elif current and line.startswith("LF:"):
        found += int(line[3:])
    elif current and line.startswith("LH:"):
        hit += int(line[3:])

if not tracked_any or found == 0:
    print("No gated source in coverage yet (lib/domain, lib/infrastructure). Skipping.")
    sys.exit(0)

pct = 100.0 * hit / found
status = "ok" if pct >= threshold else "FAIL"
print(f"Coverage of domain+infrastructure: {pct:.1f}% ({hit}/{found}) [{status}]")
sys.exit(0 if pct >= threshold else 1)
PY
