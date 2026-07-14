#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fimbulwinter Lite — Shared Mod Installer
#
# Resolves and installs BepInEx + all server-side mods + configs
# into a Valheim server directory. Single source of truth for the
# dependency/install logic, consumed by:
#   - server-install.sh   (egg install container, day-0 provisioning)
#   - server-autoupdate.sh (runtime container, boot-time re-sync)
#   - deploy.sh --full     (dev machine, staging a local-state payload)
#
# Usage:
#   install-mods.sh --server-dir DIR [--source thunderstore|local] [--repo-dir DIR]
#
#   --server-dir DIR   Target server root (e.g. /mnt/server, /home/container)
#   --source           thunderstore (default): latest published modpack
#                      local: resolve from --repo-dir's thunderstore.toml + config/
#   --repo-dir DIR     Repo checkout for --source local
#
# Requires: bash, curl, jq, unzip
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

MODPACK_NAMESPACE="${MODPACK_NAMESPACE:-ibfleming}"
MODPACK_NAME="${MODPACK_NAME:-FimbulwinterLite}"
THUNDERSTORE_API="https://thunderstore.io/api/experimental/package"

# Client-only mods — never installed on a dedicated server.
# THIS LIST IS THE SINGLE SOURCE OF TRUTH (the egg no longer embeds it).
CLIENT_ONLY_MODS=(
    "shudnal-ConfigurationManager"
    "shudnal-MyLittleUI"
    "MSchmoecker-VNEI"
    "Neobotics-HUDCompass"
    "Azumatt-AzuHoverStats"
    "ComfyMods-Gizmo"
    "Searica-Extra_Snap_Points_Made_Easy"
    "Goldenrevolver-Quick_Stack_Store_Sort_Trash_Restock"
    "Advize-PlantEasily"
    "k942-MassFarming"
    "bdew-QuickConnect"
    "VentureValheim-Venture_Logout_Tweaks"
)

log()   { echo -e "[INFO] $*"; }
warn()  { echo -e "[WARN] $*" >&2; }
fatal() { echo -e "[FATAL] $*" >&2; exit 1; }

# ── Argument parsing ───────────────────────────────────────────
SERVER_DIR=""
SOURCE="thunderstore"
REPO_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        --server-dir) SERVER_DIR="$2"; shift 2 ;;
        --source)     SOURCE="$2"; shift 2 ;;
        --repo-dir)   REPO_DIR="$2"; shift 2 ;;
        *) fatal "Unknown argument: $1" ;;
    esac
done
[ -n "$SERVER_DIR" ] || fatal "--server-dir is required"
if [ "$SOURCE" = "local" ]; then
    [ -n "$REPO_DIR" ] && [ -f "${REPO_DIR}/thunderstore.toml" ] \
        || fatal "--source local requires --repo-dir pointing at a repo with thunderstore.toml"
fi
for tool in curl jq unzip; do
    command -v "$tool" >/dev/null || fatal "Required tool missing: $tool"
done

BEPINEX_DIR="${SERVER_DIR}/BepInEx"
PLUGINS_DIR="${BEPINEX_DIR}/plugins"
CONFIG_DIR="${BEPINEX_DIR}/config"
MARKER_DIR="${SERVER_DIR}/.fimbulwinter"
# Stage on the server volume, NOT /tmp — Wings mounts /tmp as a small tmpfs.
STAGING_DIR="${SERVER_DIR}/.fimbulwinter_staging"

is_client_only() {
    local dep_fullname="$1"
    for mod in "${CLIENT_ONLY_MODS[@]}"; do
        [[ "$dep_fullname" == "$mod" ]] && return 0
    done
    return 1
}

parse_dependency() {
    local dep="$1"
    DEP_VERSION="${dep##*-}"
    DEP_FULLNAME="${dep%-*}"
    DEP_NAMESPACE="${DEP_FULLNAME%%-*}"
    DEP_NAME="${DEP_FULLNAME#*-}"
}

# Download a Thunderstore package zip with retries.
# Browser UA avoids CDN bot detection on datacenter IPs.
download_package() {
    local namespace="$1" name="$2" version="$3" dest="$4"
    local url="https://thunderstore.io/package/download/${namespace}/${name}/${version}/"
    local http_code
    for attempt in 1 2 3; do
        http_code=$(curl -sL -o "$dest" -w "%{http_code}" \
            --connect-timeout 10 --max-time 300 \
            -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0.0.0" \
            "$url")
        if [ "$http_code" = "200" ] && [ -s "$dest" ]; then
            return 0
        fi
        if [ "$attempt" -lt 3 ]; then
            warn "  HTTP ${http_code} on attempt ${attempt} for ${namespace}-${name} — retrying in 3s..."
            sleep 3
        fi
    done
    return 1
}

# Install an extracted mod into BepInEx directories.
# config/ → BepInEx/config/, patchers/ → BepInEx/patchers/,
# everything else → plugins/<ModName>/ (preserving asset-relative paths).
install_mod_files() {
    local contents_dir="$1"
    local mod_name="$2"
    local dest="${PLUGINS_DIR}/${mod_name}"

    local entries=()
    for item in "${contents_dir}"/*; do
        [ -e "$item" ] || continue
        case "$(basename "$item")" in
            icon.png|manifest.json|README.md|CHANGELOG.md|LICENSE|LICENSE.md) continue ;;
        esac
        entries+=("$item")
    done
    # Unwrap a sole top-level wrapper directory — but never config/ or
    # patchers/: those names drive routing below, and unwrapping them would
    # dump patcher DLLs into plugins/ (e.g. ShutUp ships as patchers/ShutUp.dll).
    if [ "${#entries[@]}" -eq 1 ] && [ -d "${entries[0]}" ]; then
        case "$(basename "${entries[0]}" | tr '[:upper:]' '[:lower:]')" in
            config|patchers) ;;
            *)
                log "  → unwrapped: $(basename "${entries[0]}")"
                entries=("${entries[0]}"/*)
                ;;
        esac
    fi

    mkdir -p "$dest"
    local has_patchers=false
    for item in "${entries[@]}"; do
        [ -e "$item" ] || continue
        local name
        name=$(basename "$item")
        case "${name,,}" in
            config)   mkdir -p "${CONFIG_DIR}" && cp -r "$item/"* "${CONFIG_DIR}/" ;;
            patchers) mkdir -p "${BEPINEX_DIR}/patchers" && cp -r "$item/"* "${BEPINEX_DIR}/patchers/" && has_patchers=true ;;
            *)        cp -r "$item" "$dest/" ;;
        esac
    done

    local dll_count
    dll_count=$(find "$dest" -name "*.dll" 2>/dev/null | wc -l)
    if [ "$dll_count" -eq 0 ] && [ "$has_patchers" = false ]; then
        warn "  No DLLs installed for ${mod_name} — check zip packaging"
    fi
}

# ── Resolve dependency list + config source ───────────────────
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
trap 'rm -rf "${STAGING_DIR}"' EXIT

modpack_version=""
config_source=""
dependencies=""

if [ "$SOURCE" = "thunderstore" ]; then
    log "Fetching ${MODPACK_NAMESPACE}/${MODPACK_NAME} info from Thunderstore..."
    modpack_response=$(curl -sfSL -H "accept: application/json" \
        "${THUNDERSTORE_API}/${MODPACK_NAMESPACE}/${MODPACK_NAME}/") \
        || fatal "Could not retrieve modpack info from Thunderstore API"
    modpack_version=$(jq -r '.latest.version_number' <<< "$modpack_response")
    dependencies=$(jq -r '.latest.dependencies[]' <<< "$modpack_response")

    log "Downloading modpack v${modpack_version} (configs)..."
    download_package "$MODPACK_NAMESPACE" "$MODPACK_NAME" "$modpack_version" "${STAGING_DIR}/modpack.zip" \
        || fatal "Could not download modpack zip"
    unzip -qo "${STAGING_DIR}/modpack.zip" -d "${STAGING_DIR}/modpack"
    config_source="${STAGING_DIR}/modpack/config"
else
    modpack_version="local-$(date +%Y%m%d%H%M%S)"
    log "Resolving dependencies from ${REPO_DIR}/thunderstore.toml (local working state)..."
    dependencies=$(sed -n '/^\[package.dependencies\]/,/^\[/p' "${REPO_DIR}/thunderstore.toml" \
        | grep -E '^[A-Za-z0-9_]+-[A-Za-z0-9_]+ = "' \
        | sed -E 's/^([A-Za-z0-9_]+-[A-Za-z0-9_]+) = "([^"]+)"/\1-\2/')
    config_source="${REPO_DIR}/config"
fi

[ -n "$dependencies" ] || fatal "No dependencies resolved"

# ── Install BepInEx + mods ─────────────────────────────────────
rm -rf "${PLUGINS_DIR:?}/"*
mkdir -p "${PLUGINS_DIR}"

dep_count=0
skip_count=0
fail_count=0
bepinex_version=""
total=$(echo "$dependencies" | wc -l)

for dep in $dependencies; do
    parse_dependency "$dep"

    if [[ "$DEP_FULLNAME" == "denikson-BepInExPack_Valheim" ]]; then
        log "Installing BepInEx v${DEP_VERSION}..."
        download_package "$DEP_NAMESPACE" "$DEP_NAME" "$DEP_VERSION" "${STAGING_DIR}/bepinex.zip" \
            || fatal "Could not download BepInEx"
        unzip -qo "${STAGING_DIR}/bepinex.zip" -d "${STAGING_DIR}/bepinex"
        cp -r "${STAGING_DIR}/bepinex/BepInExPack_Valheim/"* "${SERVER_DIR}/"
        bepinex_version="$DEP_VERSION"
        total=$((total - 1))
        continue
    fi

    if is_client_only "$DEP_FULLNAME"; then
        log "[SKIP] ${DEP_FULLNAME} (client-only)"
        skip_count=$((skip_count + 1))
        continue
    fi

    progress="[$((dep_count + skip_count + fail_count + 1))/${total}]"
    log "${progress} ${DEP_FULLNAME} v${DEP_VERSION}"

    dep_staging="${STAGING_DIR}/deps/${DEP_FULLNAME}"
    mkdir -p "${dep_staging}"

    if ! download_package "$DEP_NAMESPACE" "$DEP_NAME" "$DEP_VERSION" "${dep_staging}/mod.zip"; then
        warn "  Failed to download ${DEP_FULLNAME} v${DEP_VERSION} after 3 attempts — skipping"
        fail_count=$((fail_count + 1))
        continue
    fi

    unzip_exit=0
    unzip -qo "${dep_staging}/mod.zip" -d "${dep_staging}/contents" || unzip_exit=$?
    if [ "$unzip_exit" -ge 2 ]; then
        warn "  Failed to extract ${DEP_FULLNAME} — skipping"
        fail_count=$((fail_count + 1))
        continue
    fi

    install_mod_files "${dep_staging}/contents" "$DEP_FULLNAME"
    dep_count=$((dep_count + 1))
    rm -rf "${dep_staging}"
done

# ── Configs (applied last to override mod defaults) ────────────
if [ -d "$config_source" ]; then
    log "Installing modpack configuration files..."
    mkdir -p "${CONFIG_DIR}"
    cp -r "${config_source}/"* "${CONFIG_DIR}/"
fi

# ── Version marker (read by server-autoupdate.sh) ──────────────
mkdir -p "${MARKER_DIR}"
echo "$modpack_version" > "${MARKER_DIR}/installed_version"

log "======================================================="
log "  Mod installation complete"
log "  Modpack:          ${MODPACK_NAME} ${modpack_version} (source: ${SOURCE})"
[ -n "$bepinex_version" ] && log "  BepInEx:          v${bepinex_version}"
log "  Mods installed:   ${dep_count}"
log "  Skipped (client): ${skip_count}"
if [ "$fail_count" -gt 0 ]; then
    warn "  Failed downloads: ${fail_count}"
    exit 1
fi
log "======================================================="
