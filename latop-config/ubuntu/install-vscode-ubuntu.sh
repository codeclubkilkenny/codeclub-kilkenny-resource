#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[vscode-install] $*"; }

# ---- Pre-flight ----
if [[ "${EUID}" -ne 0 ]]; then
  log "Please run as root (use: sudo bash $0)"
  exit 1
fi

# ---- Config (canonical) ----
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/microsoft.gpg"
MS_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"

VSCODE_LIST_FILE="/etc/apt/sources.list.d/vscode.list"
VSCODE_REPO_LINE="deb [arch=amd64 signed-by=${KEYRING_FILE}] https://packages.microsoft.com/repos/code stable main"

log "Starting VS Code install on Ubuntu…"

export DEBIAN_FRONTEND=noninteractive

# ---- Base deps ----
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates wget gpg apt-transport-https

# ---- Keyring (canonical location) ----
mkdir -p "${KEYRING_DIR}"
if [[ ! -f "${KEYRING_FILE}" ]]; then
  log "Adding Microsoft signing key to ${KEYRING_FILE}…"
  wget -qO- "${MS_KEY_URL}" | gpg --dearmor > "${KEYRING_FILE}"
  chmod 644 "${KEYRING_FILE}"
else
  log "Microsoft keyring already present: ${KEYRING_FILE}"
fi

# ---- Cleanup: remove conflicting Microsoft/VS Code repo entries ----
# Any file that references the VS Code repo AND uses /usr/share/keyrings/microsoft.gpg
log "Cleaning up any conflicting Signed-By entries…"
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*; do
  [[ -e "$f" ]] || continue

  # If it's a .sources file and mentions packages.microsoft.com/repos/code, remove it
  if [[ "$f" == *.sources ]] && grep -q "packages.microsoft.com/repos/code" "$f" 2>/dev/null; then
    log "Removing conflicting sources file: $f"
    rm -f "$f"
    continue
  fi

  # If it's a .list file and contains the repo with the wrong signed-by, remove the file
  if [[ "$f" == *.list ]] && grep -q "packages.microsoft.com/repos/code" "$f" 2>/dev/null; then
    if grep -q "/usr/share/keyrings/microsoft.gpg" "$f" 2>/dev/null; then
      log "Removing conflicting list file (wrong signed-by): $f"
      rm -f "$f"
    fi
  fi
done

# Also remove the alternate key file if it exists (not required, but reduces confusion)
if [[ -f /usr/share/keyrings/microsoft.gpg ]]; then
  log "Note: /usr/share/keyrings/microsoft.gpg exists; leaving it in place (harmless)."
fi

# ---- Repo: write single canonical entry ----
log "Writing VS Code repo to ${VSCODE_LIST_FILE}…"
echo "${VSCODE_REPO_LINE}" > "${VSCODE_LIST_FILE}"

# ---- Install ----
log "Updating package lists…"
apt-get update -y

log "Installing VS Code…"
apt-get install -y code

# ---- Verify ----
if command -v code >/dev/null 2>&1; then
  log "Installed OK: $(code --version | head -n 1)"
  log "Binary: $(command -v code)"
else
  log "ERROR: VS Code command not found after install."
  exit 2
fi

log "Done."
