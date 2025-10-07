#!/usr/bin/env bash
#######################################
# Enhanced Hyprland Workspace App Mover
# Version: 2.0.0
# Description: Move applications between workspaces with interactive selection
#######################################

# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────────────
NOTIFICATION_TIMEOUT=3000
SCRIPT_NAME="Hyprland Workspace Mover"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ──────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ──────────────────────────────────────────────────────────────────────────────
log() {
	local msg="$1" level="${2:-INFO}" color=""
	case "$level" in
	ERROR) color=$RED ;;
	SUCCESS) color=$GREEN ;;
	WARNING) color=$YELLOW ;;
	INFO) color=$BLUE ;;
	esac
	echo -e "${color}[$(date '+%H:%M:%S')] [$level] $msg${NC}" >&2
}

notify() {
	local title="$1" message="$2" urgency="${3:-normal}"
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -u "$urgency" -t "$NOTIFICATION_TIMEOUT" "$title" "$message"
	fi
}

check_dependencies() {
	local missing=()
	for cmd in hyprctl jq; do
		command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
	done

	if [ ${#missing[@]} -gt 0 ]; then
		log "Missing dependencies: ${missing[*]}" "ERROR"
		notify "$SCRIPT_NAME" "Missing: ${missing[*]}" "critical"
		exit 1
	fi
}

show_help() {
	cat <<EOF
Usage: $0 [OPTIONS] <workspace_number>

Move applications from a specific workspace to the current workspace.

OPTIONS:
    -h, --help              Show this help message
    -a, --all               Move ALL applications from source workspace
    -i, --interactive       Select which app to move (requires rofi/wofi/fuzzel)
    -f, --focus             Focus the moved window
    -s, --silent            No notifications
    -v, --verbose           Verbose output

EXAMPLES:
    $0 9                    # Move first app from workspace 9
    $0 -a 9                 # Move all apps from workspace 9
    $0 -i 9                 # Interactively select app from workspace 9
    $0 -f 9                 # Move and focus the app

KEYBINDINGS (add to hyprland.conf):
    bind = SUPER CTRL, 1, exec, $0 1
    bind = SUPER CTRL SHIFT, 1, exec, $0 -a 1
    bind = SUPER ALT, 1, exec, $0 -i 1
EOF
}

# ──────────────────────────────────────────────────────────────────────────────
# Core Functions
# ──────────────────────────────────────────────────────────────────────────────
get_current_workspace() {
	hyprctl activeworkspace -j | jq -r '.id'
}

get_apps_in_workspace() {
	local workspace="$1"
	hyprctl clients -j | jq -r --arg ws "$workspace" \
		'.[] | select(.workspace.id == ($ws | tonumber)) | 
        "\(.address)|\(.class)|\(.title)|\(.pid)"'
}

get_app_count() {
	local workspace="$1"
	hyprctl clients -j | jq --arg ws "$workspace" \
		'[.[] | select(.workspace.id == ($ws | tonumber))] | length'
}

format_app_info() {
	local address="$1"
	hyprctl clients -j | jq -r --arg addr "$address" \
		'.[] | select(.address == $addr) | 
        "\(.class) - \(.title[0:50])"' 2>/dev/null || echo "Application"
}

move_window() {
	local target_workspace="$1" app_address="$2" focus="$3"

	if ! hyprctl dispatch movetoworkspace "$target_workspace,address:$app_address" >/dev/null 2>&1; then
		log "Failed to move window: $app_address" "ERROR"
		return 1
	fi

	if [ "$focus" = "true" ]; then
		hyprctl dispatch focuswindow "address:$app_address" >/dev/null 2>&1
	fi

	return 0
}

interactive_select() {
	local workspace="$1"
	local selector=""

	# Detect available selector
	if command -v rofi >/dev/null 2>&1; then
		selector="rofi"
	elif command -v wofi >/dev/null 2>&1; then
		selector="wofi"
	elif command -v fuzzel >/dev/null 2>&1; then
		selector="fuzzel"
	else
		log "No selector found (rofi/wofi/fuzzel)" "ERROR"
		notify "$SCRIPT_NAME" "Install rofi, wofi, or fuzzel for interactive mode" "critical"
		return 1
	fi

	local apps
	apps=$(get_apps_in_workspace "$workspace")

	if [ -z "$apps" ]; then
		return 1
	fi

	# Format for display: "Class - Title"
	local display_list=""
	while IFS='|' read -r addr class title pid; do
		display_list+="${class} - ${title}\n"
	done <<<"$apps"

	local selected
	case "$selector" in
	rofi)
		selected=$(echo -e "$display_list" | rofi -dmenu -i -p "Select app from workspace $workspace:")
		;;
	wofi)
		selected=$(echo -e "$display_list" | wofi --dmenu -i -p "Select app from workspace $workspace:")
		;;
	fuzzel)
		selected=$(echo -e "$display_list" | fuzzel --dmenu -p "Select app from workspace $workspace: ")
		;;
	esac

	if [ -z "$selected" ]; then
		return 1
	fi

	# Find the address of selected app
	while IFS='|' read -r addr class title pid; do
		local display="${class} - ${title}"
		if [ "$display" = "$selected" ]; then
			echo "$addr"
			return 0
		fi
	done <<<"$apps"

	return 1
}

# ──────────────────────────────────────────────────────────────────────────────
# Main Logic
# ──────────────────────────────────────────────────────────────────────────────
main() {
	local source_workspace=""
	local move_all=false
	local interactive=false
	local focus_window=false
	local silent=false
	local verbose=false

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help
			exit 0
			;;
		-a | --all)
			move_all=true
			shift
			;;
		-i | --interactive)
			interactive=true
			shift
			;;
		-f | --focus)
			focus_window=true
			shift
			;;
		-s | --silent)
			silent=true
			shift
			;;
		-v | --verbose)
			verbose=true
			shift
			;;
		-*)
			log "Unknown option: $1" "ERROR"
			show_help
			exit 1
			;;
		*)
			if [ -z "$source_workspace" ]; then
				source_workspace="$1"
			else
				log "Too many arguments" "ERROR"
				show_help
				exit 1
			fi
			shift
			;;
		esac
	done

	# Validate input
	if [ -z "$source_workspace" ]; then
		log "Workspace number required" "ERROR"
		show_help
		exit 1
	fi

	if ! [[ "$source_workspace" =~ ^[0-9]+$ ]]; then
		log "Invalid workspace number: $source_workspace" "ERROR"
		exit 1
	fi

	check_dependencies

	# Get current workspace
	local current_workspace
	current_workspace=$(get_current_workspace)

	if [ "$verbose" = true ]; then
		log "Current workspace: $current_workspace" "INFO"
		log "Source workspace: $source_workspace" "INFO"
	fi

	# Check if same workspace
	if [ "$source_workspace" -eq "$current_workspace" ]; then
		[ "$silent" = false ] && notify "$SCRIPT_NAME" "Already in workspace $source_workspace" "normal"
		exit 0
	fi

	# Get apps from source workspace
	local apps
	apps=$(get_apps_in_workspace "$source_workspace")
	local app_count
	app_count=$(get_app_count "$source_workspace")

	if [ -z "$apps" ] || [ "$app_count" -eq 0 ]; then
		[ "$silent" = false ] && notify "$SCRIPT_NAME" "No applications in workspace $source_workspace" "normal"
		log "No applications found in workspace $source_workspace" "WARNING"
		exit 1
	fi

	[ "$verbose" = true ] && log "Found $app_count app(s) in workspace $source_workspace" "INFO"

	# Move apps based on mode
	local moved_count=0
	local moved_names=()

	if [ "$interactive" = true ]; then
		# Interactive selection
		local selected_addr
		selected_addr=$(interactive_select "$source_workspace")

		if [ -n "$selected_addr" ]; then
			local app_info
			app_info=$(format_app_info "$selected_addr")

			if move_window "$current_workspace" "$selected_addr" "$focus_window"; then
				moved_count=1
				moved_names+=("$app_info")
				log "Moved: $app_info" "SUCCESS"
			fi
		fi

	elif [ "$move_all" = true ]; then
		# Move all apps
		while IFS='|' read -r addr class title pid; do
			local app_info="${class} - ${title:0:30}"

			if move_window "$current_workspace" "$addr" "$focus_window"; then
				moved_count=$((moved_count + 1))
				moved_names+=("$app_info")
				[ "$verbose" = true ] && log "Moved: $app_info" "SUCCESS"
			fi
		done <<<"$apps"

	else
		# Move first app only
		local first_addr
		first_addr=$(echo "$apps" | head -1 | cut -d'|' -f1)
		local app_info
		app_info=$(format_app_info "$first_addr")

		if move_window "$current_workspace" "$first_addr" "$focus_window"; then
			moved_count=1
			moved_names+=("$app_info")
			log "Moved: $app_info" "SUCCESS"
		fi
	fi

	# Send notification
	if [ "$silent" = false ] && [ $moved_count -gt 0 ]; then
		if [ $moved_count -eq 1 ]; then
			notify "$SCRIPT_NAME" "Moved ${moved_names[0]} from WS$source_workspace → WS$current_workspace" "normal"
		else
			notify "$SCRIPT_NAME" "Moved $moved_count apps from WS$source_workspace → WS$current_workspace" "normal"
		fi
	fi

	if [ $moved_count -eq 0 ]; then
		log "No windows were moved" "WARNING"
		exit 1
	fi

	log "Successfully moved $moved_count window(s)" "SUCCESS"
	exit 0
}

main "$@"
