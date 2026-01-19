#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[arduino-ide] $*"; }

if [[ "${EUID}" -ne 0 ]]; then
  log "Run as root: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

TARGET_DIR="/opt/arduino-ide"
APPIMAGE_NAME="arduino-ide.AppImage"
APPIMAGE_PATH="${TARGET_DIR}/${APPIMAGE_NAME}"
SYMLINK="/usr/local/bin/arduino-ide"
DESKTOP_FILE="/usr/local/share/applications/arduino-ide.desktop"
ICON_PATH="${TARGET_DIR}/arduino-ide.png"

# Determine the "real" user (for dialout)
REAL_USER="${SUDO_USER:-}"
if [[ -z "${REAL_USER}" || "${REAL_USER}" == "root" ]]; then
  REAL_USER="$(logname 2>/dev/null || true)"
fi

log "Installing dependencies (curl, jq, ca-certificates, libfuse2)…"
apt-get update -y
apt-get install -y --no-install-recommends curl jq ca-certificates libfuse2

mkdir -p "${TARGET_DIR}"

# --- Download only if missing ---
if [[ -f "${APPIMAGE_PATH}" ]]; then
  log "Arduino IDE AppImage already present: ${APPIMAGE_PATH} (skipping download)"
else
  log "Finding latest Arduino IDE AppImage URL (GitHub Releases)…"
  API_JSON="$(curl -fsSL https://api.github.com/repos/arduino/arduino-ide/releases/latest)"
  APP_URL="$(echo "$API_JSON" | jq -r '.assets[] | select(.name | test("Linux_64bit\\.AppImage$")) | .browser_download_url' | head -n 1)"
  TAG="$(echo "$API_JSON" | jq -r '.tag_name')"

  if [[ -z "${APP_URL}" || "${APP_URL}" == "null" ]]; then
    log "ERROR: Could not find Linux_64bit.AppImage in latest release assets."
    exit 2
  fi

  log "Latest release: ${TAG}"
  log "Downloading AppImage…"
  curl -fL "${APP_URL}" -o "${APPIMAGE_PATH}"
fi

chmod +x "${APPIMAGE_PATH}"

# --- Ensure command symlink exists ---
log "Ensuring command symlink: ${SYMLINK}"
ln -sf "${APPIMAGE_PATH}" "${SYMLINK}"

# --- Icon (optional; skip if already present) ---
if [[ ! -f "${ICON_PATH}" ]]; then
  log "Downloading an icon (optional)…"
  curl -fL "https://raw.githubusercontent.com/arduino/arduino-ide/main/resources/icons/512x512.png" -o "${ICON_PATH}" \
    || curl -fL "https://raw.githubusercontent.com/arduino/arduino-ide/main/resources/icons/icon.png" -o "${ICON_PATH}" \
    || true
fi

# --- Desktop launcher ---
log "Ensuring desktop launcher…"
mkdir -p "$(dirname "${DESKTOP_FILE}")"
cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=Arduino IDE
Comment=Arduino IDE 2.x (AppImage)
Exec=${APPIMAGE_PATH}
Icon=${ICON_PATH}
Terminal=false
Categories=Development;IDE;Electronics;
StartupNotify=true
EOF
chmod 644 "${DESKTOP_FILE}"

# --- Udev rules for serial access ---
log "Ensuring udev rules for Arduino/USB-serial…"
UDEV_RULES="/etc/udev/rules.d/99-arduino-serial.rules"
cat > "${UDEV_RULES}" <<'EOF'
# Classroom-friendly permissions for Arduino / USB-Serial devices (permissive by design)
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", MODE:="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", MODE:="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE:="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE:="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", MODE:="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE:="0666"
EOF
chmod 644 "${UDEV_RULES}"

log "Reloading udev rules…"
udevadm control --reload-rules
udevadm trigger

# --- dialout group ---
if [[ -n "${REAL_USER}" && "${REAL_USER}" != "root" ]]; then
  if id -nG "${REAL_USER}" | grep -qw dialout; then
    log "User '${REAL_USER}' already in dialout"
  else
    log "Adding user '${REAL_USER}' to dialout (serial access)…"
    usermod -aG dialout "${REAL_USER}" || true
    log "NOTE: '${REAL_USER}' must log out/in (or reboot) for dialout to apply."
  fi
else
  log "Could not determine non-root user for dialout. You can do:"
  log "  sudo usermod -aG dialout <username>"
fi

log "Done. Run: arduino-ide"
