#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fimbulwinter Lite — Valheim Dedicated Server Provisioning
#
# Full day-0 install, executed by the Pelican/Pterodactyl egg's
# install container (ghcr.io/parkervcp/installers:debian, root).
# The egg is a thin bootstrap: it fetches this script (plus its
# sibling install-mods.sh) from GitHub at SCRIPT_REF and runs it.
#
# Installs:
#   1. Valheim dedicated server via SteamCMD
#   2. BepInEx + Fimbulwinter Lite mods + configs (install-mods.sh)
#
# Server Files: /mnt/server
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SERVER_DIR="${SERVER_DIR:-/mnt/server}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()   { echo -e "[INFO] $*"; }
fatal() { echo -e "[FATAL] $*" >&2; exit 1; }

[ -f "${SCRIPT_DIR}/install-mods.sh" ] || fatal "install-mods.sh not found next to server-install.sh"

# ── System Dependencies ────────────────────────────────────────
log "Installing system dependencies..."
apt -y update
apt -y --no-install-recommends --no-install-suggests install curl wget unzip jq

# ── Steam User Setup ───────────────────────────────────────────
if [ -z "${STEAM_USER:-}" ]; then
    log "Steam user not set — using anonymous login."
    STEAM_USER="anonymous"
    STEAM_PASS=""
    STEAM_AUTH=""
else
    log "Steam user set to ${STEAM_USER}"
fi

# ── SteamCMD ───────────────────────────────────────────────────
log "Installing SteamCMD..."
mkdir -p "${SERVER_DIR}/steamcmd"
curl -sSL -o /tmp/steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf /tmp/steamcmd.tar.gz -C "${SERVER_DIR}/steamcmd"
rm -f /tmp/steamcmd.tar.gz

chown -R root:root /mnt
export HOME="${SERVER_DIR}"

# Let SteamCMD self-update before the real install — a freshly extracted
# SteamCMD will update and restart, losing command-line arguments.
log "Updating SteamCMD..."
"${SERVER_DIR}/steamcmd/steamcmd.sh" +quit || true

# ── Valheim Dedicated Server ───────────────────────────────────
SRCDS_APPID="${SRCDS_APPID:-896660}"
log "Installing Valheim dedicated server (AppID: ${SRCDS_APPID})..."
"${SERVER_DIR}/steamcmd/steamcmd.sh" \
    +force_install_dir "${SERVER_DIR}" \
    +login "${STEAM_USER}" "${STEAM_PASS:-}" "${STEAM_AUTH:-}" \
    +app_info_update 1 \
    +app_update "${SRCDS_APPID}" ${EXTRA_FLAGS:-} \
    +quit

# ── Steam Runtime Libraries ───────────────────────────────────
log "Setting up Steam runtime libraries..."
mkdir -p "${SERVER_DIR}/.steam/sdk32" "${SERVER_DIR}/.steam/sdk64"
cp -v "${SERVER_DIR}/steamcmd/linux32/steamclient.so" "${SERVER_DIR}/.steam/sdk32/steamclient.so"
cp -v "${SERVER_DIR}/steamcmd/linux64/steamclient.so" "${SERVER_DIR}/.steam/sdk64/steamclient.so"

# ── BepInEx + Mods + Configs ───────────────────────────────────
# Soft-fail: if the modpack isn't published on Thunderstore yet (pre-release
# server), the game server still provisions — push mods afterwards with
# `scripts/deploy.sh full` from the repo.
if ! bash "${SCRIPT_DIR}/install-mods.sh" --server-dir "${SERVER_DIR}" --source thunderstore; then
    echo "[WARN] Mod installation failed (modpack not published yet?). Server is playable vanilla;" >&2
    echo "[WARN] deploy mods from your dev machine with: scripts/deploy.sh full" >&2
fi

# ── Fix Permissions ────────────────────────────────────────────
# Install container runs as root, but runtime container runs as non-root.
# Ensure all server files are world-readable so the runtime user can access them.
log "Fixing file permissions for runtime container..."
find "${SERVER_DIR}" -type d -exec chmod 755 {} +
find "${SERVER_DIR}" -type f -exec chmod 644 {} +
chmod +x "${SERVER_DIR}/valheim_server.x86_64"
chmod +x "${SERVER_DIR}/steamcmd/steamcmd.sh"
find "${SERVER_DIR}/.fimbulwinter/scripts" -name "*.sh" -exec chmod 755 {} + 2>/dev/null || true

# ── Cleanup ────────────────────────────────────────────────────
log "Cleaning up..."
rm -f "${SERVER_DIR}/icon.png" \
      "${SERVER_DIR}/manifest.json" \
      "${SERVER_DIR}/README.md" \
      "${SERVER_DIR}/CHANGELOG.md"

log "======================================================="
log "  Server provisioning complete!"
log "======================================================="
