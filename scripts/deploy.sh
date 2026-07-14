#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fimbulwinter Lite — Dev-Side Server Deploy (Pelican Client API)
#
# Pushes your LOCAL working state to the Valheim server managed by
# a Pelican panel, without publishing to Thunderstore. All traffic
# goes through the panel's client API (no SSH, no SFTP).
#
# Usage:
#   scripts/deploy.sh configs     Push local config/ only (fast path, default)
#   scripts/deploy.sh full        Resolve mods from local thunderstore.toml,
#                                 stage BepInEx payload locally, push everything
#   scripts/deploy.sh reinstall   Trigger a full panel reinstall (egg pulls the
#                                 latest PUBLISHED Thunderstore modpack)
#
# Options:
#   --no-restart    Don't stop/start the server around the deploy
#   --yes           Skip confirmation prompts
#
# Credentials/endpoint come from .env at the repo root (see .env.example):
#   PANEL_URL             e.g. https://panel.lan
#   PELICAN_CLIENT_KEY    Client API key (Account -> API Credentials, ptlc_...)
#   SERVER_ID             The server's short identifier (from the panel URL)
#
# Requires: bash, curl, jq, zip
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log()   { echo -e "[DEPLOY] $*"; }
fatal() { echo -e "[DEPLOY][FATAL] $*" >&2; exit 1; }

# ── Environment ────────────────────────────────────────────────
[ -f "${REPO_DIR}/.env" ] && { set -a; . "${REPO_DIR}/.env"; set +a; }
: "${PANEL_URL:?Set PANEL_URL in .env (see .env.example)}"
: "${PELICAN_CLIENT_KEY:?Set PELICAN_CLIENT_KEY in .env (see .env.example)}"
: "${SERVER_ID:?Set SERVER_ID in .env (see .env.example)}"
PANEL_URL="${PANEL_URL%/}"
API="${PANEL_URL}/api/client/servers/${SERVER_ID}"

for tool in curl jq zip; do
    command -v "$tool" >/dev/null || fatal "Required tool missing: $tool"
done

# ── Args ───────────────────────────────────────────────────────
MODE="${1:-configs}"
case "$MODE" in configs|full|reinstall) shift || true ;; *) MODE="configs" ;; esac
RESTART=true
ASSUME_YES=false
while [ $# -gt 0 ]; do
    case "$1" in
        --no-restart) RESTART=false; shift ;;
        --yes)        ASSUME_YES=true; shift ;;
        *) fatal "Unknown option: $1" ;;
    esac
done

confirm() {
    $ASSUME_YES && return 0
    read -r -p "$1 [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { log "Aborted."; exit 0; }
}

# ── API helpers ────────────────────────────────────────────────
api() {
    local method="$1" path="$2" body="${3:-}"
    local args=(-sfS -X "$method" \
        -H "Authorization: Bearer ${PELICAN_CLIENT_KEY}" \
        -H "Accept: application/json")
    [ -n "$body" ] && args+=(-H "Content-Type: application/json" -d "$body")
    curl "${args[@]}" "${API}${path}"
}

server_state() {
    api GET "/resources" | jq -r '.attributes.current_state'
}

power() {
    local signal="$1" target="$2"
    log "Power: ${signal}..."
    api POST "/power" "{\"signal\":\"${signal}\"}" >/dev/null || true
    for _ in $(seq 1 60); do
        [ "$(server_state)" = "$target" ] && { log "Server is ${target}."; return 0; }
        sleep 2
    done
    fatal "Server did not reach state '${target}' within 120s"
}

# Upload a local file into a remote directory via the panel's signed-URL flow.
upload_file() {
    local local_path="$1" remote_dir="$2"
    local signed
    signed=$(api GET "/files/upload" | jq -r '.attributes.url')
    [ -n "$signed" ] && [ "$signed" != "null" ] || fatal "Could not obtain upload URL"
    local encoded_dir
    encoded_dir=$(jq -rn --arg d "$remote_dir" '$d|@uri')
    curl -sfS -X POST -F "files=@${local_path}" "${signed}&directory=${encoded_dir}" >/dev/null \
        || fatal "Upload of $(basename "$local_path") failed"
}

decompress_remote() {
    local remote_dir="$1" file="$2"
    api POST "/files/decompress" "{\"root\":\"${remote_dir}\",\"file\":\"${file}\"}" >/dev/null \
        || fatal "Remote decompress of ${file} failed"
}

delete_remote() {
    local remote_dir="$1"; shift
    local files_json
    files_json=$(printf '%s\n' "$@" | jq -R . | jq -sc .)
    api POST "/files/delete" "{\"root\":\"${remote_dir}\",\"files\":${files_json}}" >/dev/null || true
}

# ServerCharacters generates a random 'Server key' on the server at startup.
# The repo copy keeps that field intentionally EMPTY (never commit a real key),
# but pushing an empty key rotates it on the next boot — invalidating every
# client's cached profile signature (Bad PKCS7 padding on their next join).
# Preserve the live key by injecting it into the staged payload.
inject_remote_server_key() {
    local staged_cfg="$1/org.bepinex.plugins.servercharacters.cfg"
    [ -f "$staged_cfg" ] || return 0
    local remote_key
    remote_key=$(api GET "/files/contents?file=%2FBepInEx%2Fconfig%2Forg.bepinex.plugins.servercharacters.cfg" 2>/dev/null \
        | grep -m1 '^Server key = .' | sed 's/^Server key = //' | tr -d '\r') || true
    if [ -n "${remote_key:-}" ]; then
        sed -i "s|^Server key = *$|Server key = ${remote_key}|" "$staged_cfg"
        log "Preserved live ServerCharacters key in payload."
    fi
}

# ── Preflight ──────────────────────────────────────────────────
server_name=$(api GET "" | jq -r '.attributes.name') || fatal "Cannot reach panel/server — check PANEL_URL, key, SERVER_ID"
log "Target server: ${server_name} (${SERVER_ID}) @ ${PANEL_URL}"
log "Mode: ${MODE}"

STAMP="$(date +%Y%m%d-%H%M%S)"

case "$MODE" in
# ───────────────────────────────────────────────────────────────
configs)
    confirm "Push local config/ (overwrites server configs)?"
    payload="/tmp/fimbulwinter-configs-${STAMP}.zip"
    log "Staging local config/ ..."
    stagec=$(mktemp -d)
    trap 'rm -rf "$stagec"' EXIT
    cp -r "${REPO_DIR}/config" "${stagec}/config"
    inject_remote_server_key "${stagec}/config"
    (cd "$stagec" && zip -qr "$payload" config)
    $RESTART && power stop offline

    log "Uploading $(du -h "$payload" | cut -f1) config payload..."
    upload_file "$payload" "/BepInEx"
    decompress_remote "/BepInEx" "$(basename "$payload")"
    delete_remote "/BepInEx" "$(basename "$payload")"
    rm -f "$payload"

    $RESTART && power start running
    log "Config deploy complete."
    ;;
# ───────────────────────────────────────────────────────────────
full)
    confirm "Stage mods from local thunderstore.toml and push FULL payload (replaces server plugins + configs)?"
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT

    log "Staging local-state payload (this downloads all server-side mods from Thunderstore)..."
    bash "${REPO_DIR}/scripts/install-mods.sh" \
        --server-dir "$staging" --source local --repo-dir "$REPO_DIR"

    inject_remote_server_key "${staging}/BepInEx/config"

    payload="/tmp/fimbulwinter-full-${STAMP}.zip"
    log "Zipping payload..."
    (cd "$staging" && zip -qr "$payload" .)

    $RESTART && power stop offline

    log "Removing stale remote plugins..."
    delete_remote "/BepInEx" "plugins"

    log "Uploading $(du -h "$payload" | cut -f1) full payload..."
    upload_file "$payload" "/"
    decompress_remote "/" "$(basename "$payload")"
    delete_remote "/" "$(basename "$payload")"
    rm -f "$payload"

    $RESTART && power start running
    log "Full deploy complete (local working state is now live)."
    ;;
# ───────────────────────────────────────────────────────────────
reinstall)
    confirm "Trigger a FULL panel reinstall? This reruns the egg install (game files revalidated, mods reinstalled from the latest PUBLISHED modpack). World saves are preserved."
    $RESTART && power stop offline
    api POST "/settings/reinstall" "{}" >/dev/null || fatal "Reinstall request failed"
    log "Reinstall triggered — watch progress in the panel. Start the server manually when it finishes."
    ;;
esac
