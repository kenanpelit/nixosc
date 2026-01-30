#!/usr/bin/env bash
# ==============================================================================
# osc-mullvad-slot - Shortcut wrapper for Mullvad slot recycle
# ==============================================================================
# Runs:
#   ~/.local/bin/osc-mullvad slot recycle
#
# Usage:
#   osc-mullvad-slot [--dry-run]
# ==============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SELF_PATH="$0"
OSC_MULLVAD_BIN="${OSC_MULLVAD_BIN:-$HOME/.local/bin/osc-mullvad}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [--dry-run]

Env:
  OSC_MULLVAD_BIN=$OSC_MULLVAD_BIN
EOF
}

log() {
  echo -e "${CYAN}==>${NC} $*"
}

die() {
  echo -e "${RED}ERROR:${NC} $*" >&2
  exit 1
}

main() {
  local dry_run=""
  local run_mode="false"
  if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run="--dry-run"
    shift || true
  fi
  if [[ "${1:-}" == "--run" ]]; then
    run_mode="true"
    shift || true
  fi

  [[ $# -eq 0 ]] || {
    usage >&2
    exit 2
  }

  if [[ "$run_mode" != "true" ]]; then
    if command -v kitty >/dev/null 2>&1; then
      exec kitty --hold --class mullvad -T mullvad --single-instance \
        -e bash --noprofile --norc -lc \
        "\"$SELF_PATH\" ${dry_run:+$dry_run }--run"
    else
      die "kitty not found; install kitty or run with --run"
    fi
  fi

  if [[ ! -x "$OSC_MULLVAD_BIN" ]]; then
    if command -v osc-mullvad >/dev/null 2>&1; then
      OSC_MULLVAD_BIN="$(command -v osc-mullvad)"
    else
      die "osc-mullvad not found in PATH and not executable at $OSC_MULLVAD_BIN"
    fi
  fi

  log "Running: osc-mullvad slot ${dry_run:+$dry_run }recycle"
  if "$OSC_MULLVAD_BIN" slot ${dry_run:+$dry_run }recycle; then
    echo -e "${GREEN}OK:${NC} slot recycle completed"
  else
    die "slot recycle failed"
  fi
}

main "$@"
