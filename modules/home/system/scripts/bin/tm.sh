#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2025-03-15
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TmuxMaster - Advanced Tmux Session and Layout Manager
#
# This script provides powerful session management and customized layouts for tmux.
# Key features:
#
# - Panel Layouts:
#   - 1-panel layout (single screen)
#   - 2-panel layout (horizontally split)
#   - 3-panel layout (L-shaped)
#   - 4-panel layout (2x2 grid)
#   - 5-panel layout (3 on top, 2 on bottom)
#   - Customized panel dimensions
#   - Automatic panel selection
#
# - Session Management:
#   - Smart session naming (git/directory based)
#   - Session creation, attachment, termination
#   - Switching between sessions
#   - Automatic window renaming
#
# - Terminal Integration:
#   - Kitty and Alacritty support
#   - Terminal class and title customization
#   - Working directory control
#
# - Security and Validation:
#   - Session name validation
#   - Error catching and reporting
#   - Colored terminal output
#
# Layout 1:
#  __________________
# |                 |
# |                 |
# |        1        |
# |                 |
# |                 |
# |                 |
# |                 |
# |_________________|
#
# Layout 2:
#  __________________
# |                 |
# |        1        |
# |                 |
# |_________________|
# |                 |
# |        2        |
# |                 |
# |_________________|
#
# Layout 3:
#  ___________________
# |        |          |
# |   1    |    2     |
# |        |__________|
# |        |          |
# |        |          |
# |        |    3     |
# |        |          |
# |________|__________|
#
# Layout 4:
#  __________________
# |       |          |
# |   1   |    2     |
# |_______|__________|
# |       |          |
# |   3   |    4     |
# |       |          |
# |       |          |
# |_______|__________|
#
# Layout 5:
#  __________________
# |       |    |    |
# |   1   | 2  | 3  |
# |_______|____|____|
# |       |         |
# |   4   |    5    |
# |       |         |
# |       |         |
# |_______|_________|
#
# Usage:
#   ./tm [options] [session_name]
#
# License: MIT
#
#######################################

# Error handling
set -euo pipefail

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Message functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
print_status() { echo -e "${BLUE}[STATUS]${NC} $1"; }

# Helper functions
has_session_exact() {
	if ! command -v tmux >/dev/null 2>&1; then
		print_error "tmux is not installed"
		return 1
	fi
	tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -qx "$1"
}

validate_session_name() {
	local name="$1"
	if [[ "$name" =~ [^a-zA-Z0-9_-] ]]; then
		print_error "Invalid session name. Only letters, numbers, hyphens, and underscores are allowed."
		return 1
	fi
	return 0
}

get_session_name() {
	local dir_name="$(basename "$(pwd)")"
	local git_name="$(git rev-parse --git-dir 2>/dev/null)"

	if [[ -n "$git_name" ]]; then
		echo "$(basename "$(git rev-parse --show-toplevel)")"
	else
		echo "$dir_name"
	fi
}

# Terminal operations
check_terminal() {
	if command -v kitty >/dev/null 2>&1; then
		echo "kitty"
	elif command -v alacritty >/dev/null 2>&1; then
		echo "alacritty"
	else
		echo "x-terminal-emulator"
	fi
}

open_terminal() {
	local terminal_type="$1"
	local session_name="$2"
	local class_name="tmux-$session_name"
	local title="Tmux: $session_name"
	local layout="${3:-1}"

	case "$terminal_type" in
	kitty)
		if ! command -v kitty >/dev/null 2>&1; then
			print_error "Kitty terminal is not installed!"
			return 1
		fi
		kitty --class="$class_name" \
			--title="$title" \
			--directory="$PWD" \
			-e bash -c "tmux new-session -A -s \"$session_name\" && $0 --layout $layout" &
		;;
	alacritty)
		if ! command -v alacritty >/dev/null 2>&1; then
			print_error "Alacritty terminal is not installed!"
			return 1
		fi
		alacritty --class "$class_name" \
			--title "$title" \
			--working-directory "$PWD" \
			-e bash -c "tmux new-session -A -s \"$session_name\" && $0 --layout $layout" &
		;;
	*)
		print_error "Unsupported terminal type: $terminal_type"
		return 1
		;;
	esac
}

# Tmux operations
attach_or_switch() {
	local session_name="$1"
	if [[ -n "${TMUX:-}" ]]; then
		tmux switch-client -t "$session_name" || print_error "Could not switch to session '$session_name'."
	else
		tmux attach-session -t "$session_name" || print_error "Could not attach to session '$session_name'."
	fi
}

list_sessions() {
	print_info "Available sessions:"
	tmux list-sessions 2>/dev/null || print_warning "No active sessions"
}

kill_session() {
	local session_name="$1"
	if has_session_exact "$session_name"; then
		tmux kill-session -t "$session_name" && print_info "Session '$session_name' terminated"
	else
		print_error "Session '$session_name' not found"
		return 1
	fi
}

create_session() {
	local session_name="$1"
	if ! validate_session_name "$session_name"; then
		return 1
	fi

	if has_session_exact "$session_name"; then
		if tmux list-sessions | grep -q "^${session_name}: .* (attached)$"; then
			print_warning "Session '${session_name}' is already attached, opening a new window..."
			local window_count
			window_count=$(tmux list-windows -t "$session_name" | wc -l)
			print_status "Current window count: $window_count"
			tmux new-window -t "$session_name"
		fi
		attach_or_switch "$session_name"
	else
		print_info "Starting new tmux session '${session_name}'..."
		tmux new-session -d -s "$session_name" && attach_or_switch "$session_name"
	fi
}

# Layout Functions
# Function: Create single panel layout
function layout_1() {
	print_info "Creating 1-panel layout..."
	# Simply create a new window in the current session
	tmux new-window -n 'kenp' \; \
		select-pane -t 1

	# Silent execution
	exec 2>/dev/null &
	disown
}

# Function: Create two panel layout
function layout_2() {
	print_info "Creating 2-panel layout..."
	tmux new-window -n 'kenp' \; \
		split-window -v -p 80 \; \
		select-pane -t 2

	# Silent execution
	exec 2>/dev/null &
	disown
}

# Function: Create three panel layout
function layout_3() {
	print_info "Creating 3-panel layout..."
	tmux new-window -n 'kenp' \; \
		split-window -h -p 80 \; \
		select-pane -t 2 \; \
		split-window -v -p 85 \; \
		select-pane -t 3

	# Silent execution
	exec 2>/dev/null &
	disown
}

# Function: Create four panel layout
function layout_4() {
	print_info "Creating 4-panel layout..."
	tmux new-window -n 'kenp' \; \
		split-window -h -p 80 \; \
		split-window -v -p 80 \; \
		select-pane -t 1 \; \
		split-window -v -p 80 \; \
		select-pane -t 4

	# Silent execution
	exec 2>/dev/null &
	disown
}

# Function: Create five panel layout
function layout_5() {
	print_info "Creating 5-panel layout..."
	tmux new-window -n 'kenp' \; \
		split-window -h -p 70 \; \
		split-window -h -p 50 \; \
		select-pane -t 1 \; \
		split-window -v -p 50 \; \
		select-pane -t 2 \; \
		split-window -v -p 50 \; \
		select-pane -t 5

	# Silent execution
	exec 2>/dev/null &
	disown
}

# Usage information
show_help() {
	cat <<EOF
TmuxMaster - Advanced Tmux Session and Layout Manager

Usage: $(basename "$0") [options] [session_name]

Session Management:
    -l, --list          List available sessions
    -k, --kill <n>      Terminate the specified session
    -n, --new <n>       Create a new session
    -a, --attach <n>    Attach to an existing session
    -d, --detach        Detach from session

Terminal Options:
    -t, --terminal <type> <n> [layout]   
                        Open session in a new terminal window
                        Example: -t kitty mysession 3

Layout Options:
    --layout <1-5>      Create the specified layout in the current session
                          1: Single panel
                          2: Two panels
                          3: Three panels (L-shaped)
                          4: Four panels (2x2 grid)
                          5: Five panels

Other:
    -h, --help          Show this help message

Notes:
    - If no parameter is provided, a session is created with current directory name
    - If in a git repo, the repo name is used as the session name
    - Kitty and Alacritty terminal support
    - Session names can only contain letters, numbers, hyphens, and underscores
EOF
}

# Main function
main() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	-h | --help)
		show_help
		;;
	-l | --list)
		list_sessions
		;;
	-k | --kill)
		if [ -z "${1:-}" ]; then
			print_error "Session name not specified"
			return 1
		fi
		kill_session "$1"
		;;
	-n | --new)
		if [ -z "${1:-}" ]; then
			print_error "Session name not specified"
			return 1
		fi
		create_session "$1"
		;;
	-t | --terminal)
		if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
			print_error "Terminal type and session name must be specified"
			return 1
		fi
		local layout="${3:-1}"
		open_terminal "$1" "$2" "$layout"
		;;
	-d | --detach)
		tmux detach-client
		;;
	-a | --attach)
		if [ -z "${1:-}" ]; then
			print_error "Session name not specified"
			return 1
		fi
		if has_session_exact "$1"; then
			attach_or_switch "$1"
		else
			print_error "Session '$1' not found"
			return 1
		fi
		;;
	--layout)
		if [ -z "${1:-}" ]; then
			print_error "Layout number must be specified"
			return 1
		fi

		local layout_num="$1"

		# Check if we're in a tmux session
		if [ -z "${TMUX:-}" ]; then
			print_error "Not in a tmux session. Please run this inside tmux."
			return 1
		fi

		case "$layout_num" in
		1)
			layout_1
			;;
		2)
			layout_2
			;;
		3)
			layout_3
			;;
		4)
			layout_4
			;;
		5)
			layout_5
			;;
		*)
			print_error "Invalid layout number. Enter a value between 1-5."
			return 1
			;;
		esac
		;;
	*)
		local session_name="${command:-$(get_session_name)}"
		create_session "$session_name"
		;;
	esac
}

# Automatic window renaming
if [[ -n "${TMUX:-}" ]]; then
	LAST_DIR=""
	function precmd() {
		local current_dir="$(pwd)"
		if [[ "$LAST_DIR" != "$current_dir" ]]; then
			tmux rename-window "$(basename "$current_dir")"
		fi
		LAST_DIR="$current_dir"
	}
fi

# Run the script
main "$@"
