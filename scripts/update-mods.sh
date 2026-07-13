#!/bin/bash

# Thunderstore Mod Update Checker
# Parses thunderstore.toml and reports which dependencies have newer versions available.
# Usage: ./update-mods.sh [path/to/thunderstore.toml]
#
# Exit codes:
#   0 — all mods up to date (or updates found but not an error)
#   1 — script error (missing file, missing deps, API failure)
#
# CI mode (GITHUB_STEP_SUMMARY set):
#   Writes a Markdown summary table to $GITHUB_STEP_SUMMARY
#   Sets output variables: updates_available, update_list

set -euo pipefail

TOML_FILE="${1:-./thunderstore.toml}"
THUNDERSTORE_API="https://thunderstore.io/api/experimental/package"

# Colors (disabled in CI)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

# ── Preflight ─────────────────────────────────────────────────

if [[ ! -f "$TOML_FILE" ]]; then
    echo -e "${RED}Error: thunderstore.toml not found at $TOML_FILE${NC}" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}" >&2
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}" >&2
    exit 1
fi

# ── Parse Dependencies ────────────────────────────────────────
# thunderstore.toml format:
#   [package.dependencies]
#   Namespace-ModName = "1.2.3"

parse_dependencies() {
    local in_deps=0
    while IFS= read -r line; do
        # Detect [package.dependencies] section start
        if [[ "$line" =~ ^\[package\.dependencies\] ]]; then
            in_deps=1
            continue
        fi
        # Any other section header ends the deps block
        if [[ "$line" =~ ^\[.+\] ]]; then
            in_deps=0
            continue
        fi
        # Parse dependency lines: Namespace-ModName = "x.y.z"
        if [[ $in_deps -eq 1 && "$line" =~ ^([A-Za-z0-9_-]+)\ *=\ *\"([^\"]+)\" ]]; then
            echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
        fi
    done < "$1"
}

# ── Fetch Latest Version ─────────────────────────────────────
# API: GET /api/experimental/package/{Namespace}/{Name}/
# Returns JSON with .latest.version_number

get_latest_version() {
    local full_name="$1"  # Format: Namespace-ModName
    local namespace="${full_name%%-*}"
    local name="${full_name#*-}"

    local response
    response=$(curl -sfS --max-time 10 "${THUNDERSTORE_API}/${namespace}/${name}/" 2>/dev/null) || return 1

    echo "$response" | jq -r '.latest.version_number // empty' 2>/dev/null
}

# ── Version Comparison ────────────────────────────────────────
# Returns 0 if $1 > $2 (semver-ish: major.minor.patch)

version_gt() {
    local IFS='.'
    local -a v1=($1) v2=($2)
    for i in 0 1 2; do
        local a="${v1[$i]:-0}" b="${v2[$i]:-0}"
        if (( a > b )); then return 0; fi
        if (( a < b )); then return 1; fi
    done
    return 1
}

# ── Main ──────────────────────────────────────────────────────

main() {
    echo -e "${CYAN}Thunderstore Mod Update Checker${NC}"
    echo -e "${CYAN}TOML: $TOML_FILE${NC}"
    echo ""

    local updates_needed=0
    local up_to_date=0
    local not_found=0
    local errors=0
    local total=0
    local update_lines=()

    while IFS='|' read -r mod_name pinned_version; do
        [[ -z "$mod_name" ]] && continue
        total=$((total + 1))

        printf "  %-50s " "$mod_name"

        latest_version=$(get_latest_version "$mod_name" 2>/dev/null) || latest_version=""

        if [[ -z "$latest_version" ]]; then
            echo -e "${YELLOW}NOT FOUND${NC}"
            not_found=$((not_found + 1))
            continue
        fi

        if [[ "$latest_version" == "$pinned_version" ]]; then
            echo -e "${GREEN}OK $pinned_version${NC}"
            up_to_date=$((up_to_date + 1))
        elif version_gt "$latest_version" "$pinned_version"; then
            echo -e "${RED}UPDATE $pinned_version -> $latest_version${NC}"
            update_lines+=("$mod_name|$pinned_version|$latest_version")
            updates_needed=$((updates_needed + 1))
        else
            # Pinned version is newer than latest (pre-release or rollback)
            echo -e "${YELLOW}AHEAD $pinned_version (latest: $latest_version)${NC}"
            up_to_date=$((up_to_date + 1))
        fi

    done < <(parse_dependencies "$TOML_FILE")

    # ── Summary ───────────────────────────────────────────────

    echo ""
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "  Total:            $total"
    echo -e "  ${GREEN}Up to date:       $up_to_date${NC}"
    echo -e "  ${RED}Updates available: $updates_needed${NC}"
    echo -e "  ${YELLOW}Not found:        $not_found${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"

    # ── CI Outputs ────────────────────────────────────────────

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "updates_available=$updates_needed" >> "$GITHUB_OUTPUT"
        echo "total_checked=$total" >> "$GITHUB_OUTPUT"

        # Build a JSON array of updates for downstream steps
        local json="["
        local first=1
        for line in "${update_lines[@]:-}"; do
            [[ -z "$line" ]] && continue
            IFS='|' read -r name current latest <<< "$line"
            [[ $first -eq 0 ]] && json+=","
            json+="{\"mod\":\"$name\",\"current\":\"$current\",\"latest\":\"$latest\"}"
            first=0
        done
        json+="]"
        echo "update_list=$json" >> "$GITHUB_OUTPUT"
    fi

    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        {
            echo "## Thunderstore Mod Update Report"
            echo ""
            echo "| Status | Count |"
            echo "|--------|-------|"
            echo "| Up to date | $up_to_date |"
            echo "| Updates available | $updates_needed |"
            echo "| Not found | $not_found |"
            echo ""

            if [[ $updates_needed -gt 0 ]]; then
                echo "### Available Updates"
                echo ""
                echo "| Mod | Current | Latest |"
                echo "|-----|---------|--------|"
                for line in "${update_lines[@]}"; do
                    IFS='|' read -r name current latest <<< "$line"
                    echo "| \`$name\` | $current | **$latest** |"
                done
                echo ""
            fi
        } >> "$GITHUB_STEP_SUMMARY"
    fi

    if [[ $updates_needed -gt 0 ]]; then
        echo -e "\n${RED}$updates_needed mod(s) have updates available${NC}"
    else
        echo -e "\n${GREEN}All mods are up to date.${NC}"
    fi
}

main "$@"
