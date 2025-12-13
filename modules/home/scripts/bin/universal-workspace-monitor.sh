#!/usr/bin/env bash
# universal-workspace-monitor.sh
# Unified wrapper for workspace management across compositors (Hyprland & Niri).
# Used by Fusuma gestures to route commands to the correct backend script.

# Detect session
if [[ "$XDG_CURRENT_DESKTOP" == "niri" ]] || [[ "$XDG_SESSION_DESKTOP" == "niri" ]]; then
  exec niri-workspace-monitor "$@"
else
  # Default to Hyprland
  exec hypr-workspace-monitor "$@"
fi
