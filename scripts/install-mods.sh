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
# Update model (desired-state reconciliation):
#   The installed state is recorded in .fimbulwinter/manifest. On update,
#   the desired dependency set is reconciled against the manifest AND the
#   actual plugin directories on disk — only added/updated/missing mods
#   are downloaded, removed mods are deleted. All downloads are staged
#   BEFORE the live server is mutated (transactional apply); any download
#   failure aborts with the server untouched. No manifest (or --full)
#   falls back to a full sync. Configs are always re-overlaid wholesale.
#
# Usage:
#   install-mods.sh --server-dir DIR [--source thunderstore|local]
#                   [--repo-dir DIR] [--full]
#
#   --server-dir DIR   Target server root (e.g. /mnt/server, /home/container)
#   --source           thunderstore (default): latest published modpack
#                      local: resolve from --repo-dir's thunderstore.toml + config/
#   --repo-dir DIR     Repo checkout for --source local
#   --full             Force full sync (ignore manifest / delta path)
#
# Requires: bash, curl, jq, unzip
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

MODPACK_NAMESPACE="${MODPACK_NAMESPACE:-ibfleming}"
MODPACK_NAME="${MODPACK_NAME:-Fimbulwinter_Lite}"
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
    "ComfyMods-ComfyAutoRepair"
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
FORCE_FULL=false
while [ $# -gt 0 ]; do
    case "$1" in
        --server-dir) SERVER_DIR="$2"; shift 2 ;;
        --source)     SOURCE="$2"; shift 2 ;;
        --repo-dir)   REPO_DIR="$2"; shift 2 ;;
        --full)       FORCE_FULL=true; shift ;;
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
MANIFEST="${MARKER_DIR}/manifest"
PATCHER_LISTS="${MARKER_DIR}/patchers"
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
# Patcher files are recorded per-mod so delta removals can clean them up.
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
    rm -f "${PATCHER_LISTS}/${mod_name}.list"
    local has_patchers=false
    for item in "${entries[@]}"; do
        [ -e "$item" ] || continue
        local name
        name=$(basename "$item")
        case "${name,,}" in
            config)   mkdir -p "${CONFIG_DIR}" && cp -r "$item/"* "${CONFIG_DIR}/" ;;
            patchers)
                mkdir -p "${BEPINEX_DIR}/patchers" "${PATCHER_LISTS}"
                cp -r "$item/"* "${BEPINEX_DIR}/patchers/"
                (cd "$item" && find . -type f | sed 's|^\./||') >> "${PATCHER_LISTS}/${mod_name}.list"
                has_patchers=true
                ;;
            *)        cp -r "$item" "$dest/" ;;
        esac
    done

    local dll_count
    dll_count=$(find "$dest" -name "*.dll" 2>/dev/null | wc -l)
    if [ "$dll_count" -eq 0 ] && [ "$has_patchers" = false ]; then
        warn "  No DLLs installed for ${mod_name} — check zip packaging"
    fi
}

# Remove an installed mod: its plugins dir and any tracked patcher files.
remove_mod() {
    local mod_name="$1"
    rm -rf "${PLUGINS_DIR:?}/${mod_name}"
    if [ -f "${PATCHER_LISTS}/${mod_name}.list" ]; then
        while IFS= read -r f; do
            [ -n "$f" ] && rm -f "${BEPINEX_DIR}/patchers/${f}"
        done < "${PATCHER_LISTS}/${mod_name}.list"
        rm -f "${PATCHER_LISTS}/${mod_name}.list"
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

# ── Plan: reconcile desired state vs installed state ──────────
# Desired server-side set (dep strings incl. BepInEx; client-only excluded).
desired=()
for dep in $dependencies; do
    parse_dependency "$dep"
    is_client_only "$DEP_FULLNAME" || desired+=("$dep")
done

mode="full"
if [ "$FORCE_FULL" = false ] && [ -f "$MANIFEST" ] && [ -s "$MANIFEST" ]; then
    mode="delta"
fi

to_install=()   # dep strings to download + (re)install
to_remove=()    # mod fullnames to delete
unchanged=0

if [ "$mode" = "delta" ]; then
    # Installed state = manifest, verified against the actual disk.
    declare -A desired_by_name=()
    for dep in "${desired[@]}"; do
        parse_dependency "$dep"
        desired_by_name["$DEP_FULLNAME"]="$dep"
    done
    declare -A installed_by_name=()
    while IFS= read -r dep; do
        [ -n "$dep" ] || continue
        parse_dependency "$dep"
        installed_by_name["$DEP_FULLNAME"]="$dep"
    done < "$MANIFEST"

    # Removals: installed but no longer desired.
    for name in "${!installed_by_name[@]}"; do
        [ "$name" = "denikson-BepInExPack_Valheim" ] && continue
        if [ -z "${desired_by_name[$name]:-}" ]; then
            to_remove+=("$name")
        fi
    done
    # Installs: new, version-changed, or manifest says installed but disk disagrees.
    for name in "${!desired_by_name[@]}"; do
        dep="${desired_by_name[$name]}"
        if [ "$name" = "denikson-BepInExPack_Valheim" ]; then
            if [ "${installed_by_name[$name]:-}" != "$dep" ] || [ ! -d "${BEPINEX_DIR}/core" ]; then
                to_install+=("$dep")
            else
                unchanged=$((unchanged + 1))
            fi
            continue
        fi
        if [ "${installed_by_name[$name]:-}" = "$dep" ] && [ -d "${PLUGINS_DIR}/${name}" ]; then
            unchanged=$((unchanged + 1))
        else
            to_install+=("$dep")
        fi
    done
    log "Delta plan: ${#to_install[@]} to install/update, ${#to_remove[@]} to remove, ${unchanged} unchanged."
else
    to_install=("${desired[@]}")
    log "Full sync: installing all ${#to_install[@]} server-side packages."
fi

if [ "$mode" = "delta" ] && [ "${#to_install[@]}" -eq 0 ] && [ "${#to_remove[@]}" -eq 0 ]; then
    log "Nothing to do — applying configs only."
fi

# ── Phase 1: stage ALL downloads before touching the server ───
# A failure here aborts with the live server completely untouched.
for dep in ${to_install[@]+"${to_install[@]}"}; do
    parse_dependency "$dep"
    dep_staging="${STAGING_DIR}/deps/${DEP_FULLNAME}"
    mkdir -p "${dep_staging}"
    log "[FETCH] ${DEP_FULLNAME} v${DEP_VERSION}"
    download_package "$DEP_NAMESPACE" "$DEP_NAME" "$DEP_VERSION" "${dep_staging}/mod.zip" \
        || fatal "Download failed for ${DEP_FULLNAME} v${DEP_VERSION} — server left untouched"
    unzip -qo "${dep_staging}/mod.zip" -d "${dep_staging}/contents" \
        || fatal "Extract failed for ${DEP_FULLNAME} — server left untouched"
done

# ── Phase 2: apply (mutations start here) ──────────────────────
mkdir -p "${PLUGINS_DIR}" "${MARKER_DIR}" "${PATCHER_LISTS}"

if [ "$mode" = "full" ]; then
    log "Clearing plugins for full sync..."
    rm -rf "${PLUGINS_DIR:?}/"*
    rm -rf "${PATCHER_LISTS:?}"; mkdir -p "${PATCHER_LISTS}"
fi

for name in ${to_remove[@]+"${to_remove[@]}"}; do
    log "[REMOVE] ${name}"
    remove_mod "$name"
done

installed_count=0
for dep in ${to_install[@]+"${to_install[@]}"}; do
    parse_dependency "$dep"
    if [ "$DEP_FULLNAME" = "denikson-BepInExPack_Valheim" ]; then
        log "[INSTALL] BepInEx v${DEP_VERSION}"
        cp -r "${STAGING_DIR}/deps/${DEP_FULLNAME}/contents/BepInExPack_Valheim/"* "${SERVER_DIR}/"
    else
        log "[INSTALL] ${DEP_FULLNAME} v${DEP_VERSION}"
        remove_mod "$DEP_FULLNAME"   # clear any stale copy before reinstalling
        install_mod_files "${STAGING_DIR}/deps/${DEP_FULLNAME}/contents" "$DEP_FULLNAME"
    fi
    installed_count=$((installed_count + 1))
done

# ── Configs (always re-overlaid; applied last to override defaults) ──
if [ -d "$config_source" ]; then
    log "Installing modpack configuration files..."
    mkdir -p "${CONFIG_DIR}"
    cp -r "${config_source}/"* "${CONFIG_DIR}/"
fi

# ── Record state (marker + manifest) ───────────────────────────
printf '%s\n' "${desired[@]}" | sort > "$MANIFEST"
echo "$modpack_version" > "${MARKER_DIR}/installed_version"

log "======================================================="
log "  Mod sync complete (${mode})"
log "  Modpack:            ${MODPACK_NAME} ${modpack_version} (source: ${SOURCE})"
log "  Installed/updated:  ${installed_count}"
log "  Removed:            ${#to_remove[@]}"
[ "$mode" = "delta" ] && log "  Unchanged (kept):   ${unchanged}"
log "======================================================="
