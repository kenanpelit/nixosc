#!/usr/bin/env bash

set -x

#===============================================================================
# GNOME Workspace History Switcher - FIXED
# Implements "go to previous workspace" functionality
#===============================================================================

HISTORY_FILE="/tmp/gnome-workspace-history"

# Get current workspace (0-based)
get_current_workspace() {
	wmctrl -d | grep '*' | awk '{print $1}'
}

# Switch to workspace
switch_to_workspace() {
	local workspace="$1"
	wmctrl -s "$workspace"
}

# Read previous workspace from history
read_previous_workspace() {
	if [[ -f "$HISTORY_FILE" ]]; then
		# Get the last different workspace from current
		local current=$(get_current_workspace)
		while IFS= read -r line; do
			if [[ "$line" != "$current" ]]; then
				echo "$line"
				return
			fi
		done < <(tac "$HISTORY_FILE")
	fi
	echo "0" # Default to workspace 0 if no history
}

# Save current workspace to history
save_to_history() {
	local workspace="$1"

	# Don't save if it's the same as the last entry
	if [[ -f "$HISTORY_FILE" ]]; then
		local last=$(tail -1 "$HISTORY_FILE" 2>/dev/null)
		if [[ "$last" == "$workspace" ]]; then
			return
		fi
	fi

	echo "$workspace" >>"$HISTORY_FILE"

	# Keep only last 20 entries
	tail -20 "$HISTORY_FILE" >"$HISTORY_FILE.tmp"
	mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
}

# Switch to specific workspace with history
switch_to_workspace_with_history() {
	local target="$1"
	local current=$(get_current_workspace)

	echo "Current: $current, Target: $target" >&2

	if [[ "$current" != "$target" ]]; then
		# Different workspace - save current and switch
		echo "Switching to different workspace" >&2
		save_to_history "$current"
		switch_to_workspace "$target"
	else
		# Same workspace - go to previous
		echo "Same workspace, going to previous" >&2
		local previous=$(read_previous_workspace)
		echo "Previous workspace: $previous" >&2

		if [[ "$previous" != "$current" ]]; then
			save_to_history "$current"
			switch_to_workspace "$previous"
		else
			echo "No different previous workspace found" >&2
		fi
	fi
}

# Debug: show history
show_history() {
	echo "=== Workspace History ===" >&2
	if [[ -f "$HISTORY_FILE" ]]; then
		cat "$HISTORY_FILE" >&2
	else
		echo "No history file" >&2
	fi
	echo "Current workspace: $(get_current_workspace)" >&2
	echo "=======================" >&2
}

case "$1" in
"1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9")
	# Convert to 0-based
	target=$((${1} - 1))
	switch_to_workspace_with_history "$target"
	;;
"previous")
	previous=$(read_previous_workspace)
	current=$(get_current_workspace)
	if [[ "$previous" != "$current" ]]; then
		save_to_history "$current"
		switch_to_workspace "$previous"
	fi
	;;
"debug")
	show_history
	;;
*)
	echo "Usage: $0 {1-9|previous|debug}"
	exit 1
	;;
esac
