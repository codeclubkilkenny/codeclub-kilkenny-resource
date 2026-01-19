#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
VSCODE_REPO_LINE='deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main'
VSCODE_LIST_FILE='/etc/apt/sources.list.d/vscode.list'
KEYRING_DIR='/etc/apt/keyrings'
KEYRING_FILE="${KEYRING_DIR}/microsoft.gpg"
MS_KEY_URL='https://packages.microsoft.com/keys/microsoft.asc'

# ---- Helpers ----
log() { echo "[vscode-install] $*"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing dependency: $1"
    return 1
  fi
  return 0
}

# ---- Pre-flight ----
if [[ "${EUID}" -ne 0 ]]; then
  log "Please run as root (use: sudo bash $0)"
  exit 1
fi

log "Starting VS Code install on Ubuntu…"

# ---- Base deps ----
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates wget gpg apt-transport-https

# ---- Keyring ----
mkdir -p "${KEYRING_DIR}"

if [[ ! -f "${KEYRING_FILE}" ]]; then
  log "Adding Microsoft signing key…"
  wget -qO- "${MS_KEY_URL}" | gpg --dearmor > "${KEYRING_FILE}"
  chmod 644 "${KEYRING_FILE}"
else
  log "Microsoft keyring already present: ${KEYRING_FILE}"
fi

# ---- Repo ----
if [[ ! -f "${VSCODE_LIST_FILE}" ]] || ! grep -q 'packages\.microsoft\.com/repos/code' "${VSCODE_LIST_FILE}"; then
  log "Adding VS Code APT repository…"
  echo "${VSCODE_REPO_LINE}" > "${VSCODE_LIST_FILE}"
else
  log "VS Code repo already configured: ${VSCODE_LIST_FILE}"
fi

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
