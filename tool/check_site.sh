#!/usr/bin/env bash
#
# Sanity checks for the marketing site in site/.
#
# Four things, each of which has a specific way of going wrong silently:
#
#  1. Every local link and asset resolves to a file that exists. GitHub Pages
#     serves a project site from /<repo>/, so an absolute path like
#     "/css/site.css" works perfectly on a local server and 404s on the
#     deployed site. This is the one mistake worth a build failure.
#  2. The __REPO__ placeholder survives. If someone hard-codes a repository the
#     site stops working in every fork, and the failure is invisible in review.
#  3. No links to github.com/termino/termino, which does not exist and is
#     copied from older docs.
#  4. No test/ paths in the HTML. Screenshots reach the site through
#     tool/sync_site_images.sh, not by pointing at the golden tests.
#  5. Every file the download buttons ask for is one the release workflow
#     actually produces. These two lists are a contract between two files
#     nobody edits together, and a rename on either side removes a download
#     button without breaking anything visible.
#
# Run tool/sync_site_images.sh first: check (1) needs site/img populated.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -d site/img ]]; then
  echo "site/img is missing — run ./tool/sync_site_images.sh first." >&2
  exit 1
fi

python3 - <<'PYTHON'
import pathlib
import re
import sys

site = pathlib.Path('site')
problems = []

# --- 1. every local href/src resolves ------------------------------------
REFERENCE = re.compile(r'(?:href|src)\s*=\s*"([^"]+)"')
EXTERNAL = ('http://', 'https://', 'mailto:', 'data:', '#')

for page in sorted(site.rglob('*.html')):
    for reference in REFERENCE.findall(page.read_text(encoding='utf-8')):
        if reference.startswith(EXTERNAL):
            continue
        # A placeholder becomes an absolute URL when the Pages workflow
        # substitutes it, so there is no local file to look for. That the
        # substitution actually happened is checked by the workflow itself.
        if '__BASE_URL__' in reference or '__REPO__' in reference:
            continue
        if reference.startswith('/'):
            problems.append(
                f'{page}: "{reference}" starts with "/". Pages serves this site '
                f'from a subpath, so absolute paths 404 once deployed.'
            )
            continue

        target = (page.parent / reference.split('#')[0].split('?')[0]).resolve()
        # "./" is the page itself.
        if reference in ('./', '.'):
            continue
        if not target.exists():
            problems.append(f'{page}: "{reference}" does not exist')

# --- 2. the placeholder survives -----------------------------------------
for required in ('site/index.html', 'site/js/download.js'):
    if '__REPO__' not in pathlib.Path(required).read_text(encoding='utf-8'):
        problems.append(
            f'{required}: no __REPO__ placeholder. A hard-coded repository '
            f'breaks every fork, and the Pages workflow substitutes this token.'
        )

# --- 3 and 4. stale links, and screenshots pointing at the tests ----------
for path in sorted(site.rglob('*')):
    if not path.is_file() or path.suffix not in {'.html', '.css', '.js'}:
        continue
    text = path.read_text(encoding='utf-8')
    if 'github.com/termino/termino' in text:
        problems.append(f'{path}: links to github.com/termino/termino, which '
                        f'does not exist')
    if re.search(r'(?:href|src)\s*=\s*"test/', text):
        problems.append(f'{path}: references test/ directly. Screenshots come '
                        f'through tool/sync_site_images.sh into site/img.')

# --- 5. the download buttons ask for files the release actually builds ---
index = pathlib.Path('site/index.html').read_text(encoding='utf-8')
release = pathlib.Path('.github/workflows/release.yaml').read_text(
    encoding='utf-8'
)
for asset in re.findall(r'data-asset="([^"]+)"', index):
    if asset not in release:
        problems.append(
            f'site/index.html: the download button asks for "{asset}", which '
            f'.github/workflows/release.yaml does not produce.'
        )

if problems:
    print('The site has problems:\n', file=sys.stderr)
    for problem in problems:
        print(f'  - {problem}', file=sys.stderr)
    sys.exit(1)

pages = len(list(site.rglob('*.html')))
print(f'Site looks sound: {pages} page(s), every local asset resolves.')
PYTHON
