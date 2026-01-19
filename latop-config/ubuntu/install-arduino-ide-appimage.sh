#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Install Arduino IDE 2.x (AppImage) on Ubuntu (repeatable)
# - Fetches latest release from GitHub
# - Installs to /opt/arduino-ide
# - Adds /usr/local/bin/arduino-ide symlink
# - Creates .desktop launcher + icon
# - Adds udev rules + dialout group for serial access
# ------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

log(){ echo "[arduino-ide] $*"; }

TARGET_DIR="/opt/arduino-ide"
APPIMAGE_NAME="arduino-ide.AppImage"
APPIMAGE_PATH="${TARGET_DIR}/${APPIMAGE_NAME}"
SYMLINK="/usr/local/bin/arduino-ide"
DESKTOP_FILE="/usr/local/share/applications/arduino-ide.desktop"
ICON_PATH="${TARGET_DIR}/arduino-ide.png"

# Determine the "real" user when running with sudo
REAL_USER="${SUDO_USER:-}"
if [[ -z "${REAL_USER}" || "${REAL_USER}" == "root" ]]; then
  # fallback (still works, but won't auto-add a normal user to dialout)
  REAL_USER="$(logname 2>/dev/null || true)"
fi

log "Installing dependencies…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl jq ca-certificates

log "Finding latest Arduino IDE AppImage URL (GitHub Releases)…"
API_JSON="$(curl -fsSL https://api.github.com/repos/arduino/arduino-ide/releases/latest)"
APP_URL="$(echo "$API_JSON" | jq -r '.assets[] | select(.name | test("Linux_64bit\\.AppImage$")) | .browser_download_url' | head -n 1)"
TAG="$(echo "$API_JSON" | jq -r '.tag_name')"

if [[ -z "${APP_URL}" || "${APP_URL}" == "null" ]]; then
  log "ERROR: Could not find Linux_64bit.AppImage in latest release assets."
  exit 2
fi

log "Latest release: ${TAG}"
log "Download URL: ${APP_URL}"

log "Creating install directory: ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

log "Downloading AppImage…"
curl -fL "${APP_URL}" -o "${APPIMAGE_PATH}"
chmod +x "${APPIMAGE_PATH}"

log "Creating command symlink: ${SYMLINK}"
ln -sf "${APPIMAGE_PATH}" "${SYMLINK}"

log "Downloading an icon…"
# Simple Arduino logo icon (public, stable-ish). If it ever moves, the IDE still works.
curl -fL "https://raw.githubusercontent.com/arduino/arduino-ide/main/resources/icons/512x512.png" -o "${ICON_PATH}" \
  || curl -fL "https://raw.githubusercontent.com/arduino/arduino-ide/main/resources/icons/icon.png" -o "${ICON_PATH}" \
  || true

if [[ ! -f "${ICON_PATH}" ]]; then
  log "Icon download failed (not fatal)."
fi

log "Creating desktop launcher…"
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

log "Installing udev rules for common Arduino/USB-serial devices…"
UDEV_RULES="/etc/udev/rules.d/99-arduino-serial.rules"
cat > "${UDEV_RULES}" <<'EOF'
# Allow easy access to Arduino / USB-Serial devices for Code Club setups
# NOTE: This is intentionally permissive (MODE 0666) for classroom environments.

# Official Arduino vendor IDs
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", MODE:="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", MODE:="0666"

# Common USB-serial chips used by clones
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE:="0666"   # CH340/CH341
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE:="0666"   # Silicon Labs CP210x
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", MODE:="0666"   # Prolific PL2303
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE:="0666"   # FTDI

EOF

chmod 644 "${UDEV_RULES}"

log "Reloading udev rules…"
udevadm control --reload-rules
udevadm trigger

if [[ -n "${REAL_USER}" && "${REAL_USER}" != "root" ]]; then
  log "Adding user '${REAL_USER}' to 'dialout' group (serial access)…"
  usermod -aG dialout "${REAL_USER}" || true
  log "NOTE: '${REAL_USER}' must log out/in (or reboot) for group change to apply."
else
  log "Could not determine non-root user to add to dialout. You can do it manually:"
  log "  sudo usermod -aG dialout <username>"
fi

log "Installed."
log "Run from terminal: arduino-ide"
log "Or open from Applications menu: Arduino IDE"
