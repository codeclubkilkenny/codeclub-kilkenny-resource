#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Code Club Kilkenny - Ubuntu Setup (master script)
# - Updates Ubuntu
# - Installs prereqs + libfuse2 (for AppImages)
# - Runs VS Code / Firefox / Arduino scripts from your GitHub repo (raw URLs)
# ------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

log(){ echo "[setup] $*"; }

# --- PRE-FLIGHT: fix Microsoft VS Code repo Signed-By conflicts BEFORE any apt update ---
fix_microsoft_repo_conflicts() {
  # If both exist, APT can fail due to different Signed-By paths.
  # We enforce one canonical repo file (vscode.list) using /etc/apt/keyrings/microsoft.gpg
  local sources_file="/etc/apt/sources.list.d/vscode.sources"
  local list_file="/etc/apt/sources.list.d/vscode.list"

  # If a deb822 sources file exists, it often uses /usr/share/keyrings/microsoft.gpg
  # Disable it to avoid conflicting Signed-By definitions.
  if [[ -f "${sources_file}" ]]; then
    log "Pre-flight: disabling ${sources_file} to prevent Signed-By conflicts"
    mv -f "${sources_file}" "${sources_file}.disabled"
  fi

  # Also disable any other deb822 files that reference packages.microsoft.com/repos/code
  # (belt + braces for machines that have been tinkered with)
  for f in /etc/apt/sources.list.d/*.sources; do
    [[ -e "$f" ]] || continue
    if grep -q "packages.microsoft.com/repos/code" "$f" 2>/dev/null; then
      log "Pre-flight: disabling conflicting source file $f"
      mv -f "$f" "$f.disabled"
    fi
  done

  # If the list file exists but uses /usr/share/keyrings/microsoft.gpg, rewrite it to /etc/apt/keyrings/microsoft.gpg
  if [[ -f "${list_file}" ]]; then
    sed -i 's#signed-by=/usr/share/keyrings/microsoft.gpg#signed-by=/etc/apt/keyrings/microsoft.gpg#g' "${list_file}" || true
  fi
}
fix_microsoft_repo_conflicts


# ------------- CONFIG (edit if your paths differ) -------------
REPO_OWNER="codeclubkilkenny"
REPO_NAME="codeclub-kilkenny-resources"
REPO_BRANCH="main"

# Paths INSIDE the repo (must match your repo)
VSCODE_SCRIPT_PATH="/latop-config/ubuntu/install-vscode-ubuntu.sh"
FIREFOX_SCRIPT_PATH="/latop-config/ubuntu/firefox-codeclub-setup.sh"
ARDUINO_SCRIPT_PATH="/latop-config/ubuntu/install-arduino-ide-appimage.sh"

RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}"

VSCODE_URL="${RAW_BASE}/${VSCODE_SCRIPT_PATH}"
FIREFOX_URL="${RAW_BASE}/${FIREFOX_SCRIPT_PATH}"
ARDUINO_URL="${RAW_BASE}/${ARDUINO_SCRIPT_PATH}"
# -------------------------------------------------------------

WORKDIR="/tmp/codeclub-setup"
mkdir -p "${WORKDIR}"

download_and_run() {
  local url="$1"
  local name="$2"
  local file="${WORKDIR}/${name}"

  log "Downloading: ${url}"
  if ! wget -q -O "${file}" "${url}"; then
    log "ERROR: Failed to download ${name}"
    log "Check the path exists in the repo and the file is public."
    exit 2
  fi

  chmod +x "${file}"
  log "Running: ${name}"
  bash "${file}"
}

log "Updating Ubuntu packages…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

log "Installing prerequisites (wget, curl, ca-certificates) + libfuse2…"
apt-get install -y --no-install-recommends wget curl ca-certificates libfuse2

log "Running VS Code install script from repo…"
download_and_run "${VSCODE_URL}" "install-vscode-ubuntu.sh"

log "Running Firefox policy script from repo…"
download_and_run "${FIREFOX_URL}" "firefox-codeclub-setup.sh"

log "Running Arduino IDE (AppImage) install script from repo…"
download_and_run "${ARDUINO_URL}" "install-arduino-ide-appimage.sh"

log "All done."

echo
echo "Next steps (important):"
echo "1) Fully close Firefox and reopen it (policies apply on restart)."
echo "2) If Arduino ports don't appear, log out/in (dialout group) or reboot."
echo
echo "Quick checks:"
echo " - VS Code:   code --version"
echo " - Firefox:   about:policies (should be Active)"
echo " - Arduino:   arduino-ide"
