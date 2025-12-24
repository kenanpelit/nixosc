#!/usr/bin/env bash
# ==============================================================================
# hypr-init - Session bootstrap for Hyprland (monitors + audio)
# ------------------------------------------------------------------------------
# Runs early in the Hyprland session to:
#   1) Normalize monitor/workspace focus via hypr-switch
#   2) Initialize PipeWire defaults via osc-soundctl init
# Safe to run multiple times; each step is optional if the tool is missing.
# ==============================================================================

set -euo pipefail

LOG_TAG="hypr-init"
log() { printf '[%s] %s\n' "$LOG_TAG" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$LOG_TAG" "$*" >&2; }

run_if_present() {
  local cmd="$1"; shift
  if command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" "$@" && log "$cmd $*"
  else
    warn "$cmd not found; skipping"
  fi
}

# Ensure we are in a Hyprland session (best-effort)
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  warn "HYPRLAND_INSTANCE_SIGNATURE is unset; continuing anyway"
fi

# Step 1: monitor/workspace normalization
run_if_present hypr-set switch

# Step 2: audio defaults (volume + last sink/source)
run_if_present osc-soundctl init

log "hypr-init completed."
