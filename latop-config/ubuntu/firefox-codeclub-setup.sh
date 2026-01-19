#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Firefox Code Club setup – ALL Ubuntu variants
# ------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

echo "[INFO] Setting up Firefox Code Club policies…"

POLICY_PATHS=()

# Snap Firefox
if [[ -d /var/snap/firefox/common ]]; then
  POLICY_PATHS+=("/var/snap/firefox/common/policies")
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
        "Value": "https://sites.google.com/coderdojo.com/codeclubkilkenny/home",
        "Status": "locked"
      },

      "browser.search.defaultenginename": {
        "Value": "Google",
        "Status": "locked"
      },

      "browser.toolbars.bookmarks.visibility": {
        "Value": "always",
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
        "Title": "Code Club Kilkenny (Home)",
        "URL": "https://sites.google.com/coderdojo.com/codeclubkilkenny/home",
        "Placement": "toolbar"
      },
      {
        "Title": "Code Club Resources",
        "URL": "https://codeclubkilkenny.github.io/codeclub-kilkenny-resources/",
        "Placement": "toolbar"
      },
      {
        "Title": "Arduino",
        "URL": "https://create.arduino.cc/editor",
        "Placement": "toolbar"
      },
      {
        "Title": "MakeCode",
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
      }
    ]
  }
}'

for DIR in "${POLICY_PATHS[@]}"; do
  mkdir -p "${DIR}"
  echo "${POLICIES_JSON}" > "${DIR}/policies.json"
  chmod 644 "${DIR}/policies.json"
  chown root:root "${DIR}/policies.json"
  echo "[OK] Policies written to ${DIR}/policies.json"
done

echo
echo "[DONE]"
echo "• Fully close Firefox"
echo "• Reopen Firefox"
echo "• Bookmarks toolbar will be visible and locked"
echo "• Verify via: about:policies → Active"
