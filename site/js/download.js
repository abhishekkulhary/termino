/*
 * Fills the download buttons in from the latest GitHub release.
 *
 * This script is an upgrade, never a dependency. Every button already points at
 * the repository's releases page — a page that exists even when no release
 * does — so the acceptance test for this file is simple: delete it, and the
 * page must remain completely usable. Nothing here ever removes a working link.
 *
 * It is deliberately quiet. The one failure a visitor can actually hit is the
 * GitHub API's 60-requests-per-hour-per-IP limit, which they did not cause and
 * cannot fix; a red banner about it would be worse than the static page they
 * already have.
 */
(function () {
  'use strict';

  /*
   * Substituted by .github/workflows/pages.yaml. The comparison is written
   * against a concatenation on purpose: `sed` replaces the literal token, and
   * it cannot match a string that is only assembled at runtime — so this guard
   * survives its own substitution.
   */
  var PLACEHOLDER = '__' + 'REPO' + '__';
  var CONFIGURED = '__REPO__';

  var CACHE_KEY = 'termino.release';
  var CACHE_MS = 30 * 60 * 1000;

  /** The repository to ask about, or null when there is nothing to ask. */
  function repository() {
    // `?repo=owner/name` makes this file testable before Termino has ever
    // released — point it at any public repository and watch the cards fill in.
    var override = new URLSearchParams(window.location.search).get('repo');
    if (override && /^[\w.-]{1,100}\/[\w.-]{1,100}$/.test(override)) {
      return override;
    }
    return CONFIGURED === PLACEHOLDER ? null : CONFIGURED;
  }

  function bytes(size) {
    if (!size) return '';
    if (size >= 1048576) return (size / 1048576).toFixed(1) + ' MB';
    return Math.round(size / 1024) + ' KB';
  }

  function readCache(repo) {
    try {
      var raw = window.sessionStorage.getItem(CACHE_KEY);
      if (!raw) return null;
      var entry = JSON.parse(raw);
      if (entry.repo !== repo) return null;
      if (Date.now() - entry.at > CACHE_MS) return null;
      return entry.release;
    } catch (error) {
      return null;
    }
  }

  function writeCache(repo, release) {
    try {
      // sessionStorage rather than localStorage, and only what is displayed:
      // it dies with the tab and keeps nothing about the visitor, so a page
      // that advertises collecting nothing needs no banner to explain itself.
      window.sessionStorage.setItem(
        CACHE_KEY,
        JSON.stringify({ repo: repo, at: Date.now(), release: release })
      );
    } catch (error) {
      /* Private browsing, or storage disabled. Not worth mentioning. */
    }
  }

  /** The parts of a release this page shows, and nothing else. */
  function summarise(json) {
    var assets = {};
    (json.assets || []).forEach(function (asset) {
      assets[asset.name] = { url: asset.browser_download_url, size: asset.size };
    });
    return {
      tag: json.tag_name || '',
      published: json.published_at || '',
      assets: assets
    };
  }

  function findAsset(release, wanted, pattern) {
    if (release.assets[wanted]) return release.assets[wanted];

    // A release built before the names settled, or a fork that renames things:
    // fall back to the shape of the filename rather than showing nothing.
    if (!pattern) return null;
    var match = null;
    Object.keys(release.assets).forEach(function (name) {
      if (!match && new RegExp(pattern, 'i').test(name)) {
        match = release.assets[name];
      }
    });
    return match;
  }

  function render(release) {
    document.querySelectorAll('[data-asset]').forEach(function (link) {
      var card = link.closest('.dl');
      var meta = card && card.querySelector('[data-meta]');
      var asset = findAsset(
        release,
        link.getAttribute('data-asset'),
        link.getAttribute('data-match')
      );

      if (asset) {
        link.href = asset.url;
        if (meta) meta.textContent = release.tag + ' · ' + bytes(asset.size);
        return;
      }

      // One missing file must never blank the others, and must never leave a
      // button pointing nowhere: this one keeps the releases page it had.
      if (meta) meta.textContent = 'See all downloads';
    });

    document.querySelectorAll('[data-version]').forEach(function (node) {
      node.textContent = release.tag;
      node.hidden = false;
    });
  }

  function announceNoRelease() {
    var status = document.querySelector('[data-release-status]');
    if (status) {
      status.textContent =
        'No release has been published yet. The source builds on every ' +
        'supported platform — see the repository for how.';
      status.hidden = false;
    }
    document.querySelectorAll('[data-meta]').forEach(function (meta) {
      meta.textContent = 'Not released yet';
    });
  }

  function start() {
    var repo = repository();
    if (!repo) {
      // Previewing locally, or a deploy that skipped the substitution step.
      window.console &&
        console.info('Termino: no repository configured; try ?repo=owner/name');
      return;
    }

    var cached = readCache(repo);
    if (cached) {
      render(cached);
      return;
    }

    fetch('https://api.github.com/repos/' + repo + '/releases/latest', {
      headers: { Accept: 'application/vnd.github+json' }
    })
      .then(function (response) {
        if (response.status === 404) {
          announceNoRelease();
          return null;
        }
        // Rate limited, offline, or GitHub having a bad day. The page is
        // already correct; leave it alone.
        if (!response.ok) return null;
        return response.json();
      })
      .then(function (json) {
        if (!json) return;
        var release = summarise(json);
        writeCache(repo, release);
        render(release);
      })
      .catch(function () {
        /* Deliberately silent — see the note at the top of this file. */
      });
  }

  try {
    start();
  } catch (error) {
    /* Nothing here is load-bearing. */
  }
})();
