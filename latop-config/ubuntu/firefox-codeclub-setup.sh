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

# deb
