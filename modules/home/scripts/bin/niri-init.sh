#!/usr/bin/env bash
# ==============================================================================
# niri-init - Session bootstrap for Niri (monitors + audio + layout)
# ------------------------------------------------------------------------------
# Runs early in the Niri session to:
#   1) Focus preferred monitor (best-effort)
#   2) Normalize PipeWire defaults via osc-soundctl init
#   3) Re-apply Semsumo daily window layout via niri-arrange-windows
#
# Safe to run multiple times. Every step is best-effort and skipped if missing.
# ==============================================================================

set -euo pipefail

LOG_TAG="niri-init"
log() { printf '[%s] %s\n' "$LOG_TAG" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$LOG_TAG" "$*" >&2; }

run_if_present() {
  local cmd="$1"; shift
  if command -v "$cmd" >/dev/null 2>&1; then
    if "$cmd" "$@"; then
      log "$cmd $*"
    else
      warn "$cmd failed (ignored): $*"
    fi
  else
    warn "$cmd not found; skipping"
  fi
}

if ! command -v niri >/dev/null 2>&1; then
  warn "niri not found; exiting"
  exit 0
fi

# Ensure we can talk to the compositor (skip silently if not in a Niri session).
if ! niri msg version >/dev/null 2>&1; then
  warn "cannot connect to niri (not in session / NIRI_SOCKET missing); exiting"
  exit 0
fi

# Step 1: focus preferred monitor (guarded)
preferred="${NIRI_INIT_PREFERRED_OUTPUT:-DP-3}"
if niri msg outputs 2>/dev/null | grep -q "(${preferred})"; then
  niri msg action focus-monitor "$preferred" >/dev/null 2>&1 || true
  log "focused monitor: $preferred"
fi

# Step 2: audio defaults (volume + last sink/source)
run_if_present osc-soundctl init

# Step 3: re-apply window layout (optional)
if [[ "${NIRI_INIT_SKIP_ARRANGE:-0}" != "1" ]]; then
  run_if_present niri-arrange-windows
fi

log "niri-init completed."
