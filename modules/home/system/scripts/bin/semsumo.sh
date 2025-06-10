#!/usr/bin/env bash

#######################################
# Semsumo - Simple Script Generator
# Version: 6.3.0
# Author: Kenan Pelit
# Description: Working script generator
#######################################

readonly VERSION="6.3.0"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"

# Colors
if [[ -t 1 ]]; then
	readonly RED='\033[0;31m'
	readonly GREEN='\033[0;32m'
	readonly YELLOW='\033[1;33m'
	readonly BLUE='\033[0;34m'
	readonly CYAN='\033[0;36m'
	readonly BOLD='\033[1m'
	readonly NC='\033[0m'
else
	readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

#######################################
# Application Definitions
#######################################

# Terminal Applications
declare -A TERMINALS=(
	["kkenp"]="kitty|--class TmuxKenp -T Tmux -e tm|2|secure|1|false"
	["mkenp"]="kitty|--class TmuxKenp -T Tmux -e tm|2|secure|1|false"
	["wkenp"]="wezterm|start --class TmuxKenp -e tm|2|bypass|1|false"
	["wezterm"]="wezterm|start --class wezterm|2|secure|1|false"
	["kitty-single"]="kitty|--class kitty -T kitty --single-instance|2|secure|1|false"
	["wezterm-rmpc"]="wezterm|start --class rmpc -e rmpc|0|secure|1|false"
)

# Browser Applications
declare -A BROWSERS=(
	["brave-kenp"]="profile_brave|Kenp --class Kenp --title Kenp --restore-last-session|1|secure|2|false"
	["brave-ai"]="profile_brave|Ai --class Ai --title Ai --restore-last-session|3|secure|2|false"
	["brave-compecta"]="profile_brave|CompecTA --class CompecTA --title CompecTA --restore-last-session|4|secure|2|false"
	["brave-whats"]="profile_brave|Whats --class Whats --title Whats --restore-last-session|9|secure|1|false"
	["brave-exclude"]="profile_brave|Exclude --class Exclude --title Exclude --restore-last-session|6|bypass|1|false"
	["brave-youtube"]="profile_brave|--youtube --class youtube --title youtube|7|secure|1|true"
	["brave-tiktok"]="profile_brave|--tiktok --class tiktok --title tiktok|6|secure|1|true"
	["brave-spotify"]="profile_brave|--spotify --class spotify --title spotify|8|secure|1|true"
	["brave-discord"]="profile_brave|--discord --class discord --title discord|5|secure|1|true"
	["brave-whatsapp"]="profile_brave|--whatsapp --class whatsapp --title whatsapp|9|secure|1|true"
	["chrome-kenp"]="profile_chrome|Kenp --class Kenp|1|secure|1|false"
	["chrome-compecta"]="profile_chrome|CompecTA --class CompecTA|4|secure|1|false"
	["chrome-ai"]="profile_chrome|AI --class AI|3|secure|1|false"
	["chrome-whats"]="profile_chrome|Whats --class Whats|9|secure|1|false"
	["zen-kenp"]="zen|-P Kenp --class Kenp --name Kenp --restore-session|1|secure|1|false"
	["zen-novpn"]="zen|-P NoVpn --class AI --name AI --restore-session|3|bypass|1|false"
	["zen-compecta"]="zen|-P CompecTA --class CompecTA --name CompecTA --restore-session|4|secure|1|false"
	["zen-discord"]="zen|-P Discord --class Discord --name Discord --restore-session|5|secure|1|true"
	["zen-proxy"]="zen|-P Proxy --class Proxy --name Proxy --restore-session|7|bypass|1|false"
	["zen-spotify"]="zen|-P Spotify --class Spotify --name Spotify --restore-session|7|bypass|1|true"
	["zen-whats"]="zen|-P Whats --class Whats --name Whats --restore-session|9|secure|1|true"
)

# Applications
declare -A APPS=(
	["discord"]="discord|-m --class=discord --title=discord|5|secure|1|true"
	["webcord"]="webcord|-m --class=WebCord --title=Webcord|5|secure|1|true"
	["spotify"]="spotify|--class Spotify -T Spotify|8|bypass|1|true"
	["mpv"]="mpv|--player-operation-mode=pseudo-gui --input-ipc-server=/tmp/mpvsocket|6|bypass|1|true"
	["ferdium"]="ferdium||9|secure|1|true"
)

#######################################
# Helper Functions
#######################################

log() {
	local level="$1"
	local message="$2"
	local color=""

	case "$level" in
	"INFO") color=$BLUE ;;
	"SUCCESS") color=$GREEN ;;
	"WARN") color=$YELLOW ;;
	"ERROR") color=$RED ;;
	esac

	echo -e "${color}${BOLD}[$level]${NC} $message"
}

show_help() {
	echo -e "${BOLD}${GREEN}Semsumo v$VERSION - Simple Script Generator${NC}"
	echo
	echo -e "${BOLD}Usage:${NC}"
	echo "    $0 <command> [options]"
	echo
	echo -e "${BOLD}Commands:${NC}"
	echo "    generate [profile]    Generate startup script(s)"
	echo "    list                  List all available profiles"
	echo "    clean                 Remove all generated scripts"
	echo "    help                  Show this help"
	echo
	echo -e "${BOLD}Options:${NC}"
	echo "    --all                 Generate scripts for all profiles"
	echo "    --type TYPE           Generate scripts for specific type (terminals, browsers, apps)"
	echo
	echo -e "${BOLD}Examples:${NC}"
	echo "    $0 generate discord              # Generate script for discord"
	echo "    $0 generate --all                # Generate scripts for all profiles"
	echo "    $0 generate --type browsers      # Generate scripts for all browsers"
	echo "    $0 list                          # List all available profiles"
	echo "    $0 clean                         # Remove all generated scripts"
	echo
	echo -e "${BOLD}Generated scripts location:${NC} $SCRIPTS_DIR"
}

generate_script() {
	local profile="$1"
	local config="$2"
	local script_path="$SCRIPTS_DIR/start-${profile}.sh"

	# Parse config using simple cut method
	local cmd=$(echo "$config" | cut -d'|' -f1)
	local args=$(echo "$config" | cut -d'|' -f2)
	local workspace=$(echo "$config" | cut -d'|' -f3)
	local vpn=$(echo "$config" | cut -d'|' -f4)
	local wait=$(echo "$config" | cut -d'|' -f5)
	local fullscreen=$(echo "$config" | cut -d'|' -f6)

	# Set defaults
	[[ -z "$workspace" ]] && workspace="0"
	[[ -z "$vpn" ]] && vpn="secure"
	[[ -z "$wait" ]] && wait="1"
	[[ -z "$fullscreen" ]] && fullscreen="false"

	mkdir -p "$SCRIPTS_DIR"

	# Write script using simple echo method
	{
		echo "#!/usr/bin/env bash"
		echo "# Profile: $profile"
		echo "# Generated by Semsumo v$VERSION"
		echo "set -e"
		echo ""
		echo "echo \"Initializing $profile...\""
		echo ""
		echo "# Switch to workspace"
		echo "if [[ \"$workspace\" != \"0\" ]] && command -v hyprctl >/dev/null 2>&1; then"
		echo "    CURRENT_WORKSPACE=\$(hyprctl activeworkspace -j | grep -o '\"id\": [0-9]*' | grep -o '[0-9]*' || echo \"\")"
		echo "    "
		echo "    if [[ \"\$CURRENT_WORKSPACE\" != \"$workspace\" ]]; then"
		echo "        echo \"Switching to workspace $workspace...\""
		echo "        hyprctl dispatch workspace \"$workspace\""
		echo "        sleep 1"
		echo "        echo \"Waiting 1 seconds for transition...\""
		echo "    else"
		echo "        echo \"Already on workspace $workspace, skipping switch.\""
		echo "    fi"
		echo "fi"
		echo ""
		echo "echo \"Starting application...\""
		echo "echo \"COMMAND: $cmd $args\""
		echo "echo \"VPN MODE: $vpn\""
		echo ""
		echo "# Start application with VPN mode"
		echo "case \"$vpn\" in"
		echo "    bypass)"
		echo "        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q \"Connected\"; then"
		echo "            if command -v mullvad-exclude >/dev/null 2>&1; then"
		echo "                echo \"Starting with VPN bypass (mullvad-exclude)\""
		echo "                mullvad-exclude $cmd $args &"
		echo "            else"
		echo "                echo \"WARNING: mullvad-exclude not found, starting normally\""
		echo "                $cmd $args &"
		echo "            fi"
		echo "        else"
		echo "            echo \"VPN not connected, starting normally\""
		echo "            $cmd $args &"
		echo "        fi"
		echo "        ;;"
		echo "    secure|*)"
		echo "        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q \"Connected\"; then"
		echo "            echo \"Starting with VPN protection\""
		echo "        else"
		echo "            echo \"WARNING: VPN not connected! Starting without protection\""
		echo "        fi"
		echo "        $cmd $args &"
		echo "        ;;"
		echo "esac"
		echo ""
		echo "# Save PID"
		echo "APP_PID=\$!"
		echo "mkdir -p \"/tmp/sem\""
		echo "echo \"\$APP_PID\" > \"/tmp/sem/$profile.pid\""
		echo "echo \"Application started (PID: \$APP_PID)\""
		echo ""
		echo "# Make fullscreen if needed"
		echo "if [[ \"$fullscreen\" == \"true\" ]]; then"
		echo "    echo \"Waiting $wait seconds for application to load...\""
		echo "    sleep $wait"
		echo "    "
		echo "    if command -v hyprctl >/dev/null 2>&1; then"
		echo "        echo \"Making fullscreen...\""
		echo "        hyprctl dispatch fullscreen 1"
		echo "    fi"
		echo "fi"
		echo ""
		echo "# Switch to final workspace if different"
		echo "if [[ \"$workspace\" != \"0\" ]]; then"
		echo "    CURRENT_WORKSPACE=\$(hyprctl activeworkspace -j | grep -o '\"id\": [0-9]*' | grep -o '[0-9]*' || echo \"\")"
		echo "    "
		echo "    if [[ \"\$CURRENT_WORKSPACE\" != \"$workspace\" ]]; then"
		echo "        echo \"Switching to final workspace $workspace...\""
		echo "        if command -v hyprctl >/dev/null 2>&1; then"
		echo "            hyprctl dispatch workspace \"$workspace\""
		echo "        fi"
		echo "    else"
		echo "        echo \"Already on final workspace $workspace, skipping switch.\""
		echo "    fi"
		echo "fi"
		echo ""
		echo "exit 0"
	} >"$script_path"

	chmod +x "$script_path"
	log "SUCCESS" "Generated: start-${profile}.sh"
}

list_profiles() {
	echo -e "${BOLD}${CYAN}Available Profiles:${NC}\n"

	echo -e "${BOLD}${GREEN}Terminals:${NC}"
	for profile in "${!TERMINALS[@]}"; do
		local config="${TERMINALS[$profile]}"
		local cmd=$(echo "$config" | cut -d'|' -f1)
		local workspace=$(echo "$config" | cut -d'|' -f3)
		local vpn=$(echo "$config" | cut -d'|' -f4)
		printf "  %-15s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
	done

	echo -e "\n${BOLD}${GREEN}Browsers:${NC}"
	for profile in "${!BROWSERS[@]}"; do
		local config="${BROWSERS[$profile]}"
		local cmd=$(echo "$config" | cut -d'|' -f1)
		local workspace=$(echo "$config" | cut -d'|' -f3)
		local vpn=$(echo "$config" | cut -d'|' -f4)
		printf "  %-15s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
	done

	echo -e "\n${BOLD}${GREEN}Applications:${NC}"
	for profile in "${!APPS[@]}"; do
		local config="${APPS[$profile]}"
		local cmd=$(echo "$config" | cut -d'|' -f1)
		local workspace=$(echo "$config" | cut -d'|' -f3)
		local vpn=$(echo "$config" | cut -d'|' -f4)
		printf "  %-15s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
	done
}

generate_all() {
	log "INFO" "Generating scripts for all profiles..."

	local count=0

	# Generate terminal scripts
	for profile in "${!TERMINALS[@]}"; do
		generate_script "$profile" "${TERMINALS[$profile]}"
		((count++))
	done

	# Generate browser scripts
	for profile in "${!BROWSERS[@]}"; do
		generate_script "$profile" "${BROWSERS[$profile]}"
		((count++))
	done

	# Generate app scripts
	for profile in "${!APPS[@]}"; do
		generate_script "$profile" "${APPS[$profile]}"
		((count++))
	done

	log "SUCCESS" "Generated $count startup scripts in $SCRIPTS_DIR"

	# Show created files
	echo
	echo "Created scripts:"
	if ls "$SCRIPTS_DIR"/start-*.sh >/dev/null 2>&1; then
		ls -1 "$SCRIPTS_DIR"/start-*.sh | sed 's|.*/||' | sort
	else
		echo "No scripts found!"
	fi
}

generate_by_type() {
	local type="$1"
	local count=0

	case "$type" in
	terminals)
		log "INFO" "Generating terminal scripts..."
		for profile in "${!TERMINALS[@]}"; do
			generate_script "$profile" "${TERMINALS[$profile]}"
			((count++))
		done
		;;
	browsers)
		log "INFO" "Generating browser scripts..."
		for profile in "${!BROWSERS[@]}"; do
			generate_script "$profile" "${BROWSERS[$profile]}"
			((count++))
		done
		;;
	apps)
		log "INFO" "Generating application scripts..."
		for profile in "${!APPS[@]}"; do
			generate_script "$profile" "${APPS[$profile]}"
			((count++))
		done
		;;
	*)
		log "ERROR" "Unknown type: $type"
		log "INFO" "Available types: terminals, browsers, apps"
		return 1
		;;
	esac

	log "SUCCESS" "Generated $count $type scripts"
}

generate_single() {
	local profile="$1"

	if [[ -v TERMINALS["$profile"] ]]; then
		generate_script "$profile" "${TERMINALS[$profile]}"
	elif [[ -v BROWSERS["$profile"] ]]; then
		generate_script "$profile" "${BROWSERS[$profile]}"
	elif [[ -v APPS["$profile"] ]]; then
		generate_script "$profile" "${APPS[$profile]}"
	else
		log "ERROR" "Profile not found: $profile"
		log "INFO" "Use 'list' command to see available profiles"
		return 1
	fi
}

clean_scripts() {
	log "INFO" "Removing all generated scripts..."

	if [[ -d "$SCRIPTS_DIR" ]]; then
		rm -f "$SCRIPTS_DIR"/start-*.sh
		log "SUCCESS" "All scripts removed from $SCRIPTS_DIR"
	else
		log "INFO" "Scripts directory doesn't exist"
	fi
}

#######################################
# Main Function
#######################################

main() {
	case "${1:-help}" in
	generate)
		shift
		case "${1:-}" in
		--all)
			generate_all
			;;
		--type)
			if [[ -z "${2:-}" ]]; then
				log "ERROR" "Type required after --type"
				show_help
				exit 1
			fi
			generate_by_type "$2"
			;;
		"")
			log "ERROR" "Profile name or option required"
			show_help
			exit 1
			;;
		*)
			generate_single "$1"
			;;
		esac
		;;
	list)
		list_profiles
		;;
	clean)
		clean_scripts
		;;
	help | --help | -h)
		show_help
		;;
	version | --version | -v)
		echo "Semsumo v$VERSION"
		;;
	*)
		log "ERROR" "Unknown command: $1"
		show_help
		exit 1
		;;
	esac
}

main "$@"
