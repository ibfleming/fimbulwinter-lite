#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fimbulwinter Lite — r2modman Profile Exporter
#
# Builds an importable .r2z profile from the repo's thunderstore.toml
# (exact pinned mod versions) plus the tuned config/ tree, ready to
# hand to friends:
#   r2modman → Profiles → Import / Update → From file
#
# Usage: scripts/export-profile.sh [output.r2z]
#   Default output: dist/Fimbulwinter_Lite-v<version>-profile.r2z
#
# Requires: bash, python3
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-}"

python3 - "$REPO_DIR" "$OUT" <<'EOF'
import os, re, sys, zipfile

repo, out = sys.argv[1], sys.argv[2]
toml = open(os.path.join(repo, "thunderstore.toml")).read()
version = re.search(r'versionNumber = "([^"]+)"', toml).group(1)
deps = re.findall(r'^([A-Za-z0-9_]+-[A-Za-z0-9_]+) = "([^"]+)"$',
                  toml.split("[package.dependencies]", 1)[1].split("\n[", 1)[0], re.M)
if not out:
    out = os.path.join(repo, "dist", f"Fimbulwinter_Lite-v{version}-profile.r2z")
os.makedirs(os.path.dirname(os.path.abspath(out)) or ".", exist_ok=True)

lines = [f"profileName: Fimbulwinter-Lite-v{version}", "mods:"]
for full, ver in deps:
    major, minor, patch = ver.split(".")
    lines += [f"  - name: {full}",
              "    version:",
              f"      major: {major}",
              f"      minor: {minor}",
              f"      patch: {patch}",
              "    enabled: true"]

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("export.r2x", "\n".join(lines) + "\n")
    cfg_root = os.path.join(repo, "config")
    for root, _, files in os.walk(cfg_root):
        for f in files:
            p = os.path.join(root, f)
            arc = os.path.join("config", os.path.relpath(p, cfg_root))
            z.write(p, arc)

n_cfg = sum(len(f) for _, _, f in os.walk(cfg_root))
print(f"Wrote {out}")
print(f"  mods: {len(deps)}  |  configs bundled: {n_cfg}")
print("Import in r2modman: Profiles -> Import / Update -> From file")
EOF
