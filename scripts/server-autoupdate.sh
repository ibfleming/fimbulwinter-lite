#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fimbulwinter Lite — Boot-Time Mod Auto-Update
#
# Runs inside the RUNTIME container before the game starts, when
# the egg variable AUTO_UPDATE_MODS=1. Compares the installed
# modpack version marker against the latest published Thunderstore
# version and re-syncs mods + configs if they differ.
#
# Fails SOFT by design: any error (missing tools, network down,
# API unavailable) logs a warning and exits 0 so the server still
# boots with its existing mods.
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

SERVER_DIR="${SERVER_DIR:-/home/container}"
SCRIPT_REPO="${SCRIPT_REPO:-ibfleming/fimbulwinter-lite}"
SCRIPT_REF="${SCRIPT_REF:-main}"
MODPACK_NAMESPACE="${MODPACK_NAMESPACE:-ibfleming}"
MODPACK_NAME="${MODPACK_NAME:-FimbulwinterLite}"
MARKER="${SERVER_DIR}/.fimbulwinter/installed_version"
CACHED_INSTALLER="${SERVER_DIR}/.fimbulwinter/scripts/install-mods.sh"
RAW_BASE="https://raw.githubusercontent.com/${SCRIPT_REPO}/${SCRIPT_REF}/scripts"

log()  { echo -e "[MOD-UPDATE] $*"; }
skip() { echo -e "[MOD-UPDATE] $* — skipping mod update, booting with existing mods." >&2; exit 0; }

for tool in curl jq unzip; do
    command -v "$tool" >/dev/null 2>&1 || skip "Required tool '$tool' not available in runtime image"
done

installed="unknown"
[ -f "$MARKER" ] && installed=$(cat "$MARKER")

latest=$(curl -sfSL --max-time 20 -H "accept: application/json" \
    "https://thunderstore.io/api/experimental/package/${MODPACK_NAMESPACE}/${MODPACK_NAME}/" \
    | jq -r '.latest.version_number' 2>/dev/null) || latest=""
[ -n "$latest" ] && [ "$latest" != "null" ] || skip "Could not query Thunderstore for latest modpack version"

if [ "$installed" = "$latest" ]; then
    log "Modpack up to date (v${installed})."
    exit 0
fi

log "Modpack update available: ${installed} -> ${latest}. Re-syncing mods and configs..."

# Prefer a fresh installer from GitHub (thin-egg philosophy); fall back to
# the copy cached at install time if GitHub is unreachable.
installer="${SERVER_DIR}/.fimbulwinter/install-mods.latest.sh"
if ! curl -sfSL --max-time 20 -o "$installer" "${RAW_BASE}/install-mods.sh"; then
    if [ -f "$CACHED_INSTALLER" ]; then
        log "GitHub unreachable — using installer cached at install time."
        installer="$CACHED_INSTALLER"
    else
        skip "Could not fetch install-mods.sh and no cached copy exists"
    fi
fi

if bash "$installer" --server-dir "${SERVER_DIR}" --source thunderstore; then
    log "Mod update to v${latest} complete."
else
    skip "Mod update failed mid-run (server will boot with whatever is installed; consider a reinstall)"
fi
exit 0
