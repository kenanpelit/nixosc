#!/usr/bin/env bash
# universal-workspace-monitor.sh
# Unified wrapper for workspace management across compositors (Hyprland & Niri).
# Used by Fusuma gestures to route commands to the correct backend script.

# Resolve monitor binaries explicitly to avoid PATH issues (e.g., when launched by DM)
NIRI_MONITOR=$(command -v niri-workspace-monitor 2>/dev/null || true)
HYPR_MONITOR=$(command -v hypr-workspace-monitor 2>/dev/null || true)

if [[ "$XDG_CURRENT_DESKTOP" == "niri" ]] || [[ "$XDG_SESSION_DESKTOP" == "niri" ]]; then
  if [[ -n "$NIRI_MONITOR" ]]; then
    exec "$NIRI_MONITOR" "$@"
  else
    echo "niri-workspace-monitor not found in PATH" >&2
    exit 1
  fi
else
  if [[ -n "$HYPR_MONITOR" ]]; then
    exec "$HYPR_MONITOR" "$@"
  else
    echo "hypr-workspace-monitor not found in PATH" >&2
    exit 1
  fi
fi
