#!/usr/bin/env bash
# niri-workspace-monitor.sh - Niri workspace/monitor manager (Fusuma ready)
# Adapted from HyprFlow for Niri compositor

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME="NiriFlow"
readonly VERSION="1.0.0"
readonly CACHE_DIR="$HOME/.cache/niri/toggle"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"

# =============================================================================
# HELPERS
# =============================================================================

init_environment() {
    mkdir -p "$CACHE_DIR"
    if [ ! -f "$PREVIOUS_WS_FILE" ]; then echo "1" > "$PREVIOUS_WS_FILE"; fi
}

log() {
    echo "[$SCRIPT_NAME] $1" >&2
}

# Niri Actions
niri_msg() {
    niri msg "$@"
}

niri_action() {
    niri msg action "$@"
}

# Workspace Functions
get_current_workspace() {
    # Niri workspaces are 1-based indexes in the UI usually.
    # We parse 'niri msg workspaces' to find the active one's index.
    # Note: This relies on jq finding the index of the active workspace object.
    niri_msg workspaces | jq -r 'to_entries | .[] | select(.value.is_active) | .key + 1'
}

get_previous_workspace() {
    if [ -f "$PREVIOUS_WS_FILE" ]; then
        cat "$PREVIOUS_WS_FILE"
    else
        echo "1"
    fi
}

save_current_as_previous() {
    local current
    current=$(get_current_workspace)
    echo "$current" > "$PREVIOUS_WS_FILE"
}

# =============================================================================
# COMMANDS
# =============================================================================

# Switch to workspace by index
switch_to_workspace() {
    local index=$1
    save_current_as_previous
    niri_action focus-workspace "$index"
}

# Toggle previous workspace (Alt-Tab for workspaces)
toggle_workspace() {
    local target
    target=$(get_previous_workspace)
    local current
    current=$(get_current_workspace)
    
    if [ "$target" != "$current" ]; then
        switch_to_workspace "$target"
    else
        log "Already on previous workspace ($target)"
    fi
}

# Relative navigation (for Fusuma swipes)
# Niri workspaces are vertical.
# Map Left/Right swipes to Up/Down workspaces if desired, or use Up/Down swipes.
navigate_relative() {
    local direction=$1
    save_current_as_previous
    
    case $direction in
        "next"|"down"|"right")
            niri_action focus-workspace-down
            ;;
        "prev"|"up"|"left")
            niri_action focus-workspace-up
            ;;
    esac
}

move_window_to_workspace() {
    local index=$1
    niri_action move-column-to-workspace "$index"
}

move_window_relative() {
    local direction=$1
    case $direction in
        "next"|"down")
            niri_action move-column-to-workspace-down
            ;;
        "prev"|"up")
            niri_action move-column-to-workspace-up
            ;;
    esac
}

# Monitor Focus
focus_monitor() {
    local direction=$1
    case $direction in
        "left")  niri_action focus-monitor-left ;;
        "right") niri_action focus-monitor-right ;;
        "up")    niri_action focus-monitor-up ;;
        "down")  niri_action focus-monitor-down ;;
        "next")  niri_action focus-monitor-right ;; # Fallback
    esac
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    init_environment

    while [[ $# -gt 0 ]]; do
        case $1 in
            # Workspace Navigation (Fusuma compatible flags)
            -wl) # Workspace Left (Prev/Up)
                navigate_relative "prev"
                shift
                ;;
            -wr) # Workspace Right (Next/Down)
                navigate_relative "next"
                shift
                ;;
            -wt) # Toggle Previous Workspace
                toggle_workspace
                shift
                ;;
            -wn) # Jump to Workspace N
                if [[ -n "${2:-}" ]]; then
                    switch_to_workspace "$2"
                    shift 2
                else
                    log "Error: Workspace number required for -wn"
                    exit 1
                fi
                ;;
            
            # Window Movement
            -mw) # Move Window to Workspace N
                if [[ -n "${2:-}" ]]; then
                    move_window_to_workspace "$2"
                    shift 2
                else
                    log "Error: Workspace number required for -mw"
                    exit 1
                fi
                ;;
            
            # Monitor Focus
            -ml) focus_monitor "left"; shift ;;
            -mr) focus_monitor "right"; shift ;;
            -mu) focus_monitor "up"; shift ;;
            -md) focus_monitor "down"; shift ;;
            
            # Help
            -h|--help)
                echo "Usage: $0 [options]"
                echo "  -wl      Focus previous/up workspace"
                echo "  -wr      Focus next/down workspace"
                echo "  -wt      Toggle last workspace"
                echo "  -wn N    Focus workspace N"
                echo "  -mw N    Move window to workspace N"
                echo "  -ml/mr   Focus monitor left/right"
                exit 0
                ;;
            *)
                log "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

main "$@"
