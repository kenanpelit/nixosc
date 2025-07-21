#!/usr/bin/env bash

# layout-toggle.sh - Hyprland Master/Dwindle Layout Toggle Script
# Version: 1.0
# Author: Auto-generated for Hyprland layout switching

set -euo pipefail

# Script configuration
SCRIPT_NAME="layout-toggle"
LOG_ENABLED=false

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
	if [[ "$LOG_ENABLED" == true ]]; then
		echo -e "${BLUE}[$(date +'%H:%M:%S')] ${SCRIPT_NAME}:${NC} $1" >&2
	fi
}

# Error handling
error_exit() {
	echo -e "${RED}Error: $1${NC}" >&2
	exit 1
}

# Success message
success() {
	echo -e "${GREEN}✓ $1${NC}"
}

# Warning message
warning() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if Hyprland is running
check_hyprland() {
	if ! hyprctl version >/dev/null 2>&1; then
		error_exit "Hyprland is not running or hyprctl is not responding"
	fi
}

# Check if required commands are available
check_dependencies() {
	local deps=("hyprctl" "jq")
	for cmd in "${deps[@]}"; do
		if ! command -v "$cmd" &>/dev/null; then
			error_exit "Required command '$cmd' not found. Please install it."
		fi
	done
}

# Get current layout
get_current_layout() {
	local current_layout
	current_layout=$(hyprctl getoption general:layout -j | jq -r '.str' 2>/dev/null)

	if [[ -z "$current_layout" || "$current_layout" == "null" ]]; then
		error_exit "Could not retrieve current layout"
	fi

	echo "$current_layout"
}

# Set layout
set_layout() {
	local new_layout="$1"

	log "Setting layout to: $new_layout"

	if hyprctl keyword general:layout "$new_layout" >/dev/null 2>&1; then
		success "Layout switched to: $new_layout"
	else
		error_exit "Failed to set layout to: $new_layout"
	fi
}

# Toggle between master and dwindle layouts
toggle_layout() {
	local current_layout new_layout

	current_layout=$(get_current_layout)
	log "Current layout: $current_layout"

	case "$current_layout" in
	"master")
		new_layout="dwindle"
		;;
	"dwindle")
		new_layout="master"
		;;
	*)
		warning "Unknown layout '$current_layout', defaulting to master"
		new_layout="master"
		;;
	esac

	set_layout "$new_layout"
}

# Show current layout
show_current() {
	local current_layout
	current_layout=$(get_current_layout)
	echo "Current layout: $current_layout"
}

# Show help
show_help() {
	cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Hyprland Layout Toggle Script

COMMANDS:
    toggle          Toggle between master and dwindle layouts (default)
    master          Set layout to master
    dwindle         Set layout to dwindle
    current         Show current layout
    help            Show this help message

OPTIONS:
    -v, --verbose   Enable verbose logging
    -h, --help      Show this help message

EXAMPLES:
    $0              # Toggle layout
    $0 toggle       # Toggle layout (explicit)
    $0 master       # Set to master layout
    $0 dwindle      # Set to dwindle layout
    $0 current      # Show current layout
    $0 -v toggle    # Toggle with verbose output

EOF
}

# Main function
main() {
	local command="toggle"

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		-v | --verbose)
			LOG_ENABLED=true
			shift
			;;
		-h | --help)
			show_help
			exit 0
			;;
		toggle | master | dwindle | current | help)
			command="$1"
			shift
			;;
		*)
			error_exit "Unknown option: $1. Use '$0 --help' for usage information."
			;;
		esac
	done

	# Check dependencies first
	check_dependencies
	check_hyprland

	# Execute command
	case "$command" in
	"toggle")
		toggle_layout
		;;
	"master")
		set_layout "master"
		;;
	"dwindle")
		set_layout "dwindle"
		;;
	"current")
		show_current
		;;
	"help")
		show_help
		;;
	*)
		error_exit "Invalid command: $command"
		;;
	esac
}

# Run main function with all arguments
main "$@"
