#!/usr/bin/env bash

set -x

# GNOME Workspace Switcher with History Support - TOGGLE FIX
HISTORY_FILE="/tmp/gnome-workspace-history"

# Function to get current workspace (returns 1-based index from GNOME)
get_current_workspace() {
	wmctrl -d | grep '*' | awk '{print $NF}'
}

# Function to get current workspace INDEX (0-based for wmctrl commands)
get_current_workspace_index() {
	wmctrl -d | grep '*' | awk '{print $1}'
}

# Function to switch to workspace (expects 1-based GNOME workspace number)
switch_to_workspace() {
	local workspace_number=$1                       # 1-based (what user sees)
	local workspace_index=$((workspace_number - 1)) # 0-based (what wmctrl uses)

	echo "Switching to workspace: $workspace_number (index: $workspace_index)"
	wmctrl -s "$workspace_index"

	# Wait for workspace change to complete
	local timeout=10 # 1 second timeout
	while [[ $timeout -gt 0 ]]; do
		if [[ "$(get_current_workspace)" == "$workspace_number" ]]; then
			break
		fi
		sleep 0.1
		((timeout--))
	done
}

# Function to save workspace to history (saves 1-based workspace numbers)
save_to_history() {
	local workspace=$1

	# Create history file if it doesn't exist
	if [[ ! -f "$HISTORY_FILE" ]]; then
		touch "$HISTORY_FILE"
	fi

	# Always save - don't check for duplicates since we want history
	echo "$workspace" >>"$HISTORY_FILE"

	# Keep only last 10 entries
	tail -10 "$HISTORY_FILE" >"${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
	echo "Saved workspace $workspace to history"
}

# Function to read previous workspace from history (excluding current)
read_previous_workspace() {
	if [[ ! -f "$HISTORY_FILE" || ! -s "$HISTORY_FILE" ]]; then
		echo "1" # Return workspace 1 as default
		return
	fi

	local current=$(get_current_workspace)

	# Read history in reverse order and find first different workspace
	while IFS= read -r line; do
		if [[ "$line" != "$current" && -n "$line" ]]; then
			echo "$line"
			return
		fi
	done < <(tac "$HISTORY_FILE")

	# If no different workspace found, return 1
	echo "1"
}

# Main function with toggle support - CORRECTED VERSION
switch_to_workspace_with_history() {
	local target=$1 # 1-based workspace number
	local current=$(get_current_workspace)

	echo "Current: $current, Target: $target"

	if [[ "$current" != "$target" ]]; then
		echo "Switching to different workspace"
		# Save current workspace to history BEFORE switching
		save_to_history "$current"
		switch_to_workspace "$target"
	else
		echo "Same workspace - toggling to previous"
		# Get previous workspace from history
		local previous=$(read_previous_workspace)
		echo "Previous workspace from history: $previous"

		if [[ "$previous" != "$current" ]]; then
			# Switch to previous workspace (don't save current again)
			switch_to_workspace "$previous"
		else
			echo "No different previous workspace found"
		fi
	fi
}

# Debug function
show_history() {
	echo "=== Workspace History ==="
	if [[ -f "$HISTORY_FILE" ]]; then
		echo "History file contents:"
		cat -n "$HISTORY_FILE"
		echo "---"
		echo "Last 3 entries:"
		tail -3 "$HISTORY_FILE" | cat -n
	else
		echo "No history file"
	fi
	echo "Current workspace: $(get_current_workspace)"
	echo "Previous workspace: $(read_previous_workspace)"
	echo "======================="
}

# Parse command line argument - NOW USES 1-BASED NUMBERS
case "$1" in
1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9)
	target=$1 # Use workspace number directly (1-based)
	;;
debug)
	show_history
	exit 0
	;;
clear)
	rm -f "$HISTORY_FILE"
	echo "History cleared"
	exit 0
	;;
*)
	echo "Usage: $0 {1-9|debug|clear}"
	echo "Example: $0 2  # Switch to workspace 2"
	echo "Example: $0 2  # Press again to go back to previous"
	exit 1
	;;
esac

# Switch to workspace with history support
switch_to_workspace_with_history "$target"
