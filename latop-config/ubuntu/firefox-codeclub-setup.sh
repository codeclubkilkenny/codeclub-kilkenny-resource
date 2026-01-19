#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Firefox Code Club setup (Ubuntu)
# - Sets Google as default search engine (locked)
# - Adds Code Club bookmarks
# - Removes news / Pocket / sponsored content
# - Works with Firefox Snap and deb installs
# ------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo bash $0"
  exit 1
fi

# Detect Firefox policy directory (Snap vs deb)
if [[ -d /var/snap/firefox/common ]]; then
  POLICY_DIR="/var/snap/firefox/common/policies"
else
  POLICY_DIR="/etc/firefox/policies"
fi

mkdir -p "${POLICY_DIR}"

cat > "${POLICY_DIR}/policies.json" <<'JSON'
{
  "policies": {

    /* -------- Privacy & Noise Reduction -------- */
    "DisablePocket": true,
    "DisableFirefoxStudies": true,
    "DisableTelemetry": true,

    /* -------- Default Search Engine -------- */
    "SearchEngines": {
      "Default": "Google",
      "PreventInstalls": true
    },

    /* -------- Homepage & New Tab -------- */
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

      /* ---- Remove news / sponsored clutter ---- */
      "browser.newtabpage.activity-stream.feeds.section.topstories": {
        "Value": false
      },
      "browser.newtabpage.activity-stream.feeds.snippets": {
        "Value": false
      },
      "browser.newtabpage.activity-stream.feeds.topsites": {
        "Value": false
      },
      "browser.newtabpage.activity-stream.feeds.highlights": {
        "Value": false
      },
      "browser.newtabpage.activity-stream.showSponsored": {
        "Value": false
      },
      "browser.newtabpage.activity-stream.showSponsoredTopSites": {
        "Value": false
      }
    },

    /* -------- Code Club Toolbar -------- */
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
}
JSON

echo "✅ Firefox Code Club policies written to:"
echo "   ${POLICY_DIR}/policies.json"
echo
echo "IMPORTANT:"
echo "• Fully close Firefox (all windows)"
echo "• Reopen Firefox to apply changes"
echo
echo "Done."
