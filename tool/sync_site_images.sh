#!/usr/bin/env bash
#
# Copies the site's screenshots out of the golden tests.
#
# The goldens *are* the screenshots: they are rendered from the real widgets by
# the real theme, so they cannot drift from the product the way a screenshot
# taken by hand does. Copying rather than keeping a second committed set means a
# UI change updates the site by updating the goldens, and only there — no
# duplicated binaries in git, and no unrelated pull request turning red because
# it regenerated one.
#
# site/img is gitignored. Run this before previewing the site locally; CI and
# the Pages deploy run it too, and a golden that has been renamed or removed
# fails the build here rather than showing up as a missing image on the
# deployed site a week later.

set -euo pipefail

cd "$(dirname "$0")/.."

# source:destination, relative to the repository root.
#
# Deliberately excluded:
#   test/shared/goldens/screen_keys.png    — renders a real-looking username
#   test/shared/goldens/screen_files.png   — one row against 700px of empty grid
#   test/shared/goldens/screen_tunnels.png — the same; they photograph as empty
IMAGES=(
  "test/features/hosts/goldens/hosts_expanded.png:site/img/hero-hosts.png"
  "test/features/command_palette/goldens/command_palette.png:site/img/palette.png"
  "test/features/settings/goldens/settings_screen.png:site/img/settings.png"
  "test/features/terminal/goldens/terminal_pane_dark.png:site/img/terminal.png"
  "test/features/hosts/goldens/hosts_compact.png:site/img/mobile-hosts.png"
  "web/icons/Icon-192.png:site/img/icon-192.png"
)

if [[ $# -gt 0 ]]; then
  echo "usage: $0" >&2
  exit 2
fi

missing=0
for entry in "${IMAGES[@]}"; do
  source="${entry%%:*}"
  destination="${entry#*:}"

  if [[ ! -f "$source" ]]; then
    echo "missing: $source" >&2
    missing=$((missing + 1))
    continue
  fi

  mkdir -p "$(dirname "$destination")"
  cp "$source" "$destination"
done

if [[ $missing -gt 0 ]]; then
  echo >&2
  echo "$missing image(s) the site needs are not where this script expects." >&2
  echo "A golden was renamed or removed; update the table in $0." >&2
  exit 1
fi

echo "Copied ${#IMAGES[@]} images into site/img."
