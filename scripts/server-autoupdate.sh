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
MODPACK_NAME="${MODPACK_NAME:-Fimbulwinter_Lite}"
MARKER="${SERVER_DIR}/.fimbulwinter/installed_version"
CACHED_INSTALLER="${SERVER_DIR}/.fimbulwinter/scripts/install-mods.sh"
RAW_BASE="https://raw.githubusercontent.com/${SCRIPT_REPO}/${SCRIPT_REF}/scripts"

log()  { echo -e "[MOD-UPDATE] $*"; }
skip() { echo -e "[MOD-UPDATE] $* — skipping mod update, booting with existing mods." >&2; exit 0; }

command -v curl >/dev/null 2>&1 || skip "curl not available in runtime image (cannot bootstrap anything without it)"

# The runtime image (ghcr.io/parkervcp/games:valheim) lacks jq (and possibly
# unzip), and the container user cannot apt-install. Bootstrap static binaries
# into the persistent server volume instead — one-time download, reused on
# every subsequent boot via PATH.
BIN_DIR="${SERVER_DIR}/.fimbulwinter/bin"
export PATH="${BIN_DIR}:${PATH}"

if ! command -v jq >/dev/null 2>&1; then
    log "jq not found — bootstrapping static binary into ${BIN_DIR}..."
    mkdir -p "${BIN_DIR}"
    curl -fsSL --max-time 60 -o "${BIN_DIR}/jq" \
        "https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64" \
        && chmod +x "${BIN_DIR}/jq" || skip "Could not bootstrap jq"
    "${BIN_DIR}/jq" --version >/dev/null 2>&1 || { rm -f "${BIN_DIR}/jq"; skip "Bootstrapped jq does not run"; }
    log "jq $("${BIN_DIR}/jq" --version) ready."
fi

if ! command -v unzip >/dev/null 2>&1; then
    log "unzip not found — bootstrapping static busybox into ${BIN_DIR}..."
    mkdir -p "${BIN_DIR}"
    curl -fsSL --max-time 60 -o "${BIN_DIR}/busybox" \
        "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox" \
        && chmod +x "${BIN_DIR}/busybox" || skip "Could not bootstrap busybox (for unzip)"
    [ "$("${BIN_DIR}/busybox" echo ok 2>/dev/null)" = "ok" ] || { rm -f "${BIN_DIR}/busybox"; skip "Bootstrapped busybox does not run"; }
    printf '#!/bin/sh\nexec "%s" unzip "$@"\n' "${BIN_DIR}/busybox" > "${BIN_DIR}/unzip"
    chmod +x "${BIN_DIR}/unzip"
    log "busybox unzip ready."
fi

installed="unknown"
[ -f "$MARKER" ] && installed=$(cat "$MARKER")

# A "local-*" marker means a dev-side deploy.sh full pushed unpublished
# working-tree state. Auto-update must NOT revert it to the published pack;
# the pin clears the next time a published version is deployed or reinstalled.
case "$installed" in
    local-*) skip "Local dev deploy pinned (${installed}) - skipping auto-update. Publish the pack or run deploy.sh reinstall to resume auto-updates." ;;
esac

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
