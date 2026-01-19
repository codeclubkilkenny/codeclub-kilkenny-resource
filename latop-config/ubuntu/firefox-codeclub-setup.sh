#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Firefox Code Club setup – ALL Ubuntu variants
# - Works with Snap Firefox AND deb Firefox
# - Adds bookmarks
# - Removes news / Pocket / sponsored content
# - Sets Google as default search engine
# - Idempotent (safe to re-run)
# ------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

echo "[INFO] Detecting Firefox install type…"

POLICY_PATHS=()

# Snap Firefox
if [[ -d /var/snap/firefox/common ]]; then
  POLICY_PATHS+=("/var/snap/firefox/common/policies")
  echo "[INFO] Snap Firefox detected"
fi

# deb/apt Firefox
POLICY_PATHS+=("/etc/firefox/policies")

POLICIES_JSON='{
  "policies": {
    "DisablePocket": true,
    "DisableFirefoxStudies": true,
    "DisableTelemetry": true,

    "SearchEngines": {
      "Default": "Google",
      "PreventInstalls": true
    },

    "Preferences": {
      "browser.startup.homepage": {
        "Value": "https://codeclubkilkenny.github.io/codeclub-kilkenny-resources/",
        "Status": "locked"
      },
      "browser.search.defaultenginename": {
        "Value": "Google",
        "Status": "locked"
      },
      "browser.newtabpage.enabled": {
        "Value": true
      },
      "browser.newtabpage.activity-stream.feeds.section.topstories": { "Value": false },
      "browser.newtabpage.activity-stream.feeds.snippets": { "Value": false },
      "browser.newtabpage.activity-stream.feeds.topsites": { "Value": false },
      "browser.newtabpage.activity-stream.feeds.highlights": { "Value": false },
      "browser.newtabpage.activity-stream.showSponsored": { "Value": false },
      "browser.newtabpage.activity-stream.showSponsoredTopSites": { "Value": false }
    },

    "Bookmarks": [
      {
        "Title": "Code Club Kilkenny",
        "URL": "https://codeclubkilkenny.github.io/codeclub-kilkenny-resources/",
        "Placement": "toolbar"
      },
      {
        "Title": "Arduino Web Editor",
        "URL": "https://create.arduino.cc/editor",
        "Placement": "toolbar"
      },
      {
        "Title": "Microsoft MakeCode",
        "URL": "https://makecode.microbit.org/",
        "Placement": "toolbar"
      },
      {
        "Title": "Scratch",
        "URL": "https://scratch.mit.edu/",
        "Placement": "toolbar"
      },
      {
        "Title": "Python",
        "URL": "https://www.python.org/",
        "Placement": "toolbar"
      },
      {
        "Title": "Google Drive",
        "URL": "https://drive.google.com/",
        "Placement": "toolbar"
      }
    ]
  }
}'

echo "[INFO] Writing Firefox enterprise policies…"

for DIR in "${POLICY_PATHS[@]}"; do
  mkdir -p "${DIR}"
  echo "${POLICIES_JSON}" > "${DIR}/policies.json"
  chmod 644 "${DIR}/policies.json"
  chown root:root "${DIR}/policies.json"
  echo "[OK] Policies written to ${DIR}/policies.json"
done

echo
echo "[IMPORTANT]"
echo "• Close ALL Firefox windows"
echo "• Reopen Firefox"
echo "• Check: about:policies → Active"
echo
echo "[DONE]"
