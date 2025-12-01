#!/usr/bin/env bash
# Update Maple Mono package version and hashes.
# - Fetches release archives, computes sha256 (base64), and rewrites hashes.json
# - Bumps the version in default.nix
# Usage:
#   ./update-maple.sh            # auto-detect latest release from GitHub
#   ./update-maple.sh 7.8        # or set an explicit version

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASHES_JSON="${ROOT}/hashes.json"
DEFAULT_NIX="${ROOT}/default.nix"

VERSION="${1:-}"

latest_version() {
  curl -s "https://api.github.com/repos/subframe7536/maple-font/releases/latest" \
    | jq -r '.tag_name' \
    | sed 's/^v//'
}

if [[ -z "${VERSION}" ]]; then
  VERSION="$(latest_version)"
fi

BASE="https://github.com/subframe7536/Maple-font/releases/download/v${VERSION}"

# Minimal set we actually use; extend if you need more variants.
FILES=(
  "MapleMono-TTF"
  "MapleMono-NF"
  "MapleMono-NF-CN-unhinted"
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo ">> Updating Maple Mono to v${VERSION}"
echo ">> Fetching and hashing:"

json_entries=()
for name in "${FILES[@]}"; do
  url="${BASE}/${name}.zip"
  out="${tmpdir}/${name}.zip"
  echo "   - ${name} ..."
  curl -L -o "${out}" "${url}"
  hash=$(nix hash file --type sha256 --base64 "${out}")
  json_entries+=( "\"${name}\": \"sha256-${hash}\"" )
done

printf "{\n  %s\n}\n" "$(IFS=$',\n  '; echo "${json_entries[*]}")" > "${HASHES_JSON}"
echo ">> Wrote hashes to ${HASHES_JSON}"

# Bump version in default.nix
sed -i "s/^  version = \".*\";/  version = \"${VERSION}\";/" "${DEFAULT_NIX}"
echo ">> Set version=${VERSION} in ${DEFAULT_NIX}"

echo ">> Done. Now commit hashes.json and default.nix, then rebuild."
