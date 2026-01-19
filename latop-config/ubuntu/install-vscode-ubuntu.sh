#!/usr/bin/env bash
set -euo pipefail

log() { echo "[vscode-install] $*"; }

if [[ "${EUID}" -ne 0 ]]; then
  log "Please run as root (use: sudo bash $0)"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# --- Canonical locations we will enforce ---
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/microsoft.gpg"
VSCODE_LIST_FILE="/etc/apt/sources.list.d/vscode.list"
VSCODE_SOURCES_FILE="/etc/apt/sources.list.d/vscode.sources"
MS_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_REPO_LINE="deb [arch=amd64 signed-by=${KEYRING_FILE}] https://packages.microsoft.com/repos/code stable main"

log "Installing dependencies..."
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates wget gpg apt-transport-https

# --- HARDENING: prevent Signed-By conflicts ---
# If a deb822 file exists (vscode.sources), it may point to /usr/share/keyrings/microsoft.gpg.
# That conflicts with our /etc/apt/keyrings/microsoft.gpg approach and breaks apt.
if [[ -f "${VSCODE_SOURCES_FILE}" ]]; then
  log "Found ${VSCODE_SOURCES_FILE}; disabling to prevent Signed-By conflicts..."
  mv -f "${VSCODE_SOURCES_FILE}" "${VSCODE_SOURCES_FILE}.disabled"
fi

# Also disable any leftover duplicates that might exist from other setups
for f in /etc/apt/sources.list.d/*vscode*.sources; do
  [[ -e "$f" ]] || continue
  if [[ "$f" != "${VSCODE_SOURCES_FILE}.disabled" ]]; then
    log "Disabling duplicate sources file: $f"
    mv -f "$f" "$f.disabled"
  fi
done

# --- Keyring setup (canonical path) ---
mkdir -p "${KEYRING_DIR}"

if [[ ! -f "${KEYRING_FILE}" ]]; then
  log "Adding Microsoft signing key to ${KEYRING_FILE}..."
  wget -qO- "${MS_KEY_URL}" | gpg --dearmor > "${KEYRING_FILE}"
  chmod 644 "${KEYRING_FILE}"
else
  log "Microsoft keyring already present: ${KEYRING_FILE}"
fi

# --- Repo setup (canonical file + canonical Signed-By path) ---
log "Writing VS Code APT repository to ${VSCODE_LIST_FILE}..."
echo "${VSCODE_REPO_LINE}" > "${VSCODE_LIST_FILE}"
chmod 644 "${VSCODE_LIST_FILE}"

# --- Update & install ---
log "Updating package lists..."
apt-get update -y

log "Installing VS Code..."
apt-get install -y code

# --- Verify ---
if command -v code >/dev/null 2>&1; then
  log "Installed OK: $(code --version | head -n 1)"
  log "Binary: $(command -v code)"
else
  log "ERROR: VS Code command not found after install."
  exit 2
fi

log "Done."
