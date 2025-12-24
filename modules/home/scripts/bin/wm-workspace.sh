#!/usr/bin/env bash
# wm-workspace.sh
# Workspace router across compositors (Hyprland & Niri).
# Used by Fusuma (and other callers) to route workspace/monitor actions to the
# correct backend (`hypr-set workspace-monitor` or `niri-set workspace-monitor`).

# Resolve monitor binaries explicitly to avoid PATH issues (e.g., when launched by DM)
BASE_DIR=$(dirname "$(readlink -f "$0")")
NIRI_MONITOR=$(command -v niri-set 2>/dev/null || true)
HYPR_MONITOR=$(command -v hypr-set 2>/dev/null || true)

# Fallback to same prefix as this script
[[ -z "$NIRI_MONITOR" && -x "$BASE_DIR/niri-set" ]] && NIRI_MONITOR="$BASE_DIR/niri-set"
[[ -z "$HYPR_MONITOR" && -x "$BASE_DIR/hypr-set" ]] && HYPR_MONITOR="$BASE_DIR/hypr-set"

if [[ -n "${NIRI_SOCKET:-}" ]] || [[ "$XDG_CURRENT_DESKTOP" == "niri" ]] || [[ "$XDG_SESSION_DESKTOP" == "niri" ]]; then
  if [[ -n "$NIRI_MONITOR" ]]; then
    exec "$NIRI_MONITOR" workspace-monitor "$@"
  else
    echo "niri-set not found in PATH" >&2
    exit 1
  fi
else
  if [[ -n "$HYPR_MONITOR" ]]; then
    exec "$HYPR_MONITOR" workspace-monitor "$@"
  else
    echo "hypr-set not found in PATH" >&2
    exit 1
  fi
fi
