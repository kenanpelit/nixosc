#!/usr/bin/env bash
# ==============================================================================
# osc-dropdown.sh - Toggle a specialized dropdown terminal in Niri
# ==============================================================================
# Logic:
# 1. Look for a window with app-id "dropdown-terminal"
# 2. If it exists:
#    - If it's on current workspace and focused -> Move to scratchpad (hide)
#    - If it's elsewhere -> Pull to current workspace and focus
# 3. If it doesn't exist -> Spawn kitty with specific class
# ==============================================================================

set -euo pipefail

APP_ID="dropdown-terminal"
TERMINAL_CMD="kitty --class $APP_ID"

# Check if niri and jq are available
if ! command -v niri >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exec $TERMINAL_CMD
fi

# Get window info
window_info=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app)')

if [[ -z "$window_info" ]]; then
    # Case 1: Doesn't exist -> Spawn it
    exec $TERMINAL_CMD &
else
    window_id=$(echo "$window_info" | jq -r '.id')
    is_focused=$(echo "$window_info" | jq -r '.is_focused')
    
    # Get current workspace info
    current_ws_id=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .id')
    target_ws_id=$(echo "$window_info" | jq -r '.workspace_id')

    if [[ "$is_focused" == "true" ]]; then
        # Case 2: Exists, focused and here -> Hide it (move to a far workspace or use nirius scratchpad)
        # Using nirius if available, else just move it away
        if command -v nirius >/dev/null 2>&1; then
            nirius scratchpad-toggle --id "$window_id"
        else
            niri msg action move-window-to-workspace 255
        fi
    else
        # Case 3: Exists but not focused or elsewhere -> Bring it here
        niri msg action focus-window --id "$window_id"
        # If it was on another workspace, nirius pull or manual move
        if [[ "$current_ws_id" != "$target_ws_id" ]]; then
            niri msg action move-window-to-workspace "$current_ws_id"
        fi
    fi
fi
