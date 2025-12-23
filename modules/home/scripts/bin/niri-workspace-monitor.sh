#!/usr/bin/env bash
# niri-workspace-monitor.sh - Niri workspace/monitor manager (Fusuma ready)
# Adapted from HyprFlow for Niri compositor

set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
readonly SCRIPT_NAME="NiriFlow"
readonly VERSION="1.0.0"
readonly NIRI_MSG="niri msg"

# Prefer user cache dir; fall back to runtime dir if cache has bad perms (e.g. created by root)
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_dir_candidate="$cache_root/niri/toggle"
if ! mkdir -p "$cache_dir_candidate" 2>/dev/null || [[ ! -w "$cache_dir_candidate" ]]; then
    cache_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    cache_dir_candidate="$cache_root/niri-flow"
    mkdir -p "$cache_dir_candidate" 2>/dev/null || true
fi

readonly CACHE_DIR="$cache_dir_candidate"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
readonly MONITOR_STATE_FILE="$CACHE_DIR/monitor_state"

# =============================================================================
# HELPERS
# =============================================================================

init_environment() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
    if [ ! -f "$PREVIOUS_WS_FILE" ]; then echo "1" > "$PREVIOUS_WS_FILE" 2>/dev/null || true; fi
    if [ ! -f "$MONITOR_STATE_FILE" ]; then echo "right" > "$MONITOR_STATE_FILE" 2>/dev/null || true; fi
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
    # Fetch workspaces JSON
    local output
    output=$($NIRI_MSG workspaces 2>/dev/null)

    # Check if output is valid JSON (basic check)
    if [[ -z "$output" ]] || [[ "${output:0:1}" != "[" ]]; then
        # Fallback if IPC fails or returns non-JSON
        echo "1"
        return
    fi

    # Extract active workspace ID
    # Note: Niri workspace IDs are usually persistent integers.
    # If using indexes (1-based from list order):
    # echo "$output" | jq -r 'to_entries | .[] | select(.value.is_active) | .key + 1'
    
    # Using ID directly (safest if IDs correspond to numbers user sees)
    local id
    id=$(echo "$output" | jq -r '.[] | select(.is_active) | .id' 2>/dev/null)
    
    if [[ -n "$id" ]] && [[ "$id" != "null" ]]; then
        echo "$id"
    else
        echo "1"
    fi
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
        "next")  niri_action focus-monitor-next ;;
        "prev")  niri_action focus-monitor-previous ;;
    esac
}

# Toggle between left/right monitors (simple 2-monitor setups)
toggle_monitor_focus() {
    local state
    state="$(cat "$MONITOR_STATE_FILE" 2>/dev/null || echo "right")"

    if [[ "$state" == "right" ]]; then
        focus_monitor "right"
        echo "left" > "$MONITOR_STATE_FILE"
    else
        focus_monitor "left"
        echo "right" > "$MONITOR_STATE_FILE"
    fi
}

# Browser tab navigation (works compositor-agnostic; uses wtype)
navigate_browser_tab() {
    local direction=$1

    if command -v wtype >/dev/null 2>&1; then
        if [[ "$direction" == "next" ]]; then
            wtype -M ctrl -k tab 2>/dev/null || true
        else
            wtype -M ctrl -M shift -k tab 2>/dev/null || true
        fi
        return 0
    fi

    log "Browser tab navigation requires wtype"
    return 1
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
            -mn) focus_monitor "next"; shift ;; # monitor next
            -mp) focus_monitor "prev"; shift ;; # monitor previous

            # HyprFlow-compatible monitor aliases (used by Fusuma configs)
            -ms)  focus_monitor "right"; shift ;; # monitor shift (best-effort)
            -msf) focus_monitor "right"; shift ;; # monitor shift with focus (best-effort)
            -mt)  toggle_monitor_focus; shift ;;  # toggle monitor focus

            # HyprFlow-compatible browser tab aliases (used by Fusuma configs)
            -tn) navigate_browser_tab "next"; shift ;;
            -tp) navigate_browser_tab "prev"; shift ;;
            
            # Help
            -h|--help)
                echo "Usage: $0 [options]"
                echo "  -wl      Focus previous/up workspace"
                echo "  -wr      Focus next/down workspace"
                echo "  -wt      Toggle last workspace"
                echo "  -wn N    Focus workspace N"
                echo "  -mw N    Move window to workspace N"
                echo "  -ml/mr   Focus monitor left/right"
                echo "  -mn/-mp  Focus next/previous monitor"
                echo "  -ms/-msf Focus monitor right (alias)"
                echo "  -mt      Toggle monitor focus (left/right)"
                echo "  -tn/-tp  Next/previous browser tab (wtype)"
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
