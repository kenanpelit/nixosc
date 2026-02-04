#!/usr/bin/env bash
set -euo pipefail

# Launch `wiremix` in Kitty with a stable app-id/class so compositor rules can
# float/size it consistently (like clipse).

need() { command -v "$1" >/dev/null 2>&1; }
die() { echo "ERROR: $*" >&2; exit 1; }

need wiremix || die "wiremix not found (add pkgs.wiremix to your packages)"
need kitty || die "kitty not found"

exec kitty --class wiremix -T wiremix --single-instance -e wiremix "$@"
