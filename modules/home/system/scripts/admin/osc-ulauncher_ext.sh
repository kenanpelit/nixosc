#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Ulauncher Extension Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive Ulauncher extension manager with installation
#                and metadata tracking capabilities
#
#   Features:
#   - Batch extension installation
#   - Commit tracking
#   - JSON metadata generation
#   - Extension cleanup
#   - Progress tracking
#
#   License: MIT
#
#===============================================================================

# Configuration
readonly EXTENSIONS_DIR="$HOME/.local/share/ulauncher/extensions"
readonly CONFIG_DIR="$HOME/.config/ulauncher/ext_preferences"
readonly PREFERENCES_FILE="$CONFIG_DIR/extensions.json"
readonly DATE_FORMAT="%Y-%m-%dT%H:%M:%S.%6N"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Function to print colorized messages
log() {
	local color=$1
	local message=$2
	echo -e "${color}${message}${NC}"
}

# Initialize directories
init_directories() {
	mkdir -p "$EXTENSIONS_DIR"
	mkdir -p "$CONFIG_DIR"
	chmod 755 "$EXTENSIONS_DIR" "$CONFIG_DIR"
}

# Initialize JSON structure
init_json() {
	echo "{" >"$PREFERENCES_FILE"
}

# Add extension metadata to JSON
add_to_json() {
	local repo=$1
	local ext_name="com.github.${repo//\//.}"
	local ext_dir="$EXTENSIONS_DIR/$ext_name"

	cd "$ext_dir" || return 1

	# Give git a moment to finish
	sleep 1

	# Git commands with error checking
	local last_commit=$(git rev-parse HEAD 2>/dev/null)
	if [ $? -ne 0 ]; then
		log $RED "Failed to get last commit for $ext_name"
		return 1
	fi

	local last_commit_time=$(git log -1 --format=%cI 2>/dev/null)
	if [ $? -ne 0 ]; then
		log $RED "Failed to get commit time for $ext_name"
		return 1
	fi

	local current_time=$(date +"$DATE_FORMAT")

	# Create extension DB file
	touch "$CONFIG_DIR/$ext_name.db"

	# Append to JSON
	cat >>"$PREFERENCES_FILE" <<EOF
    "$ext_name": {
        "id": "$ext_name",
        "url": "https://github.com/$repo",
        "updated_at": "$current_time",
        "last_commit": "$last_commit",
        "last_commit_time": "$last_commit_time"
    }$([ $2 == true ] && echo "," || echo "")
EOF
}

# Finish JSON file
finish_json() {
	echo "}" >>"$PREFERENCES_FILE"
}

# Clean old extensions
clean_extensions() {
	log $YELLOW "Cleaning old extensions..."
	if [ -d "$EXTENSIONS_DIR" ]; then
		rm -rf "${EXTENSIONS_DIR:?}"/*
	fi
	if [ -d "$CONFIG_DIR" ]; then
		rm -f "$CONFIG_DIR"/*.db
		rm -f "$CONFIG_DIR"/extensions.json
	fi
	log $GREEN "Cleanup completed."
}

# Array of extension repositories
declare -a repos=(
	"abhishekmj303/ulauncher-playerctl"
	"alexnabokikh/ulauncher-power-manager"
	"brpaz/ulauncher-file-search"
	"brpaz/ulauncher-pwgen"
	"cardoprimo/ulauncher-recent-files"
	"dankni95/ulauncher-playerctl"
	"devkleber/ulauncher-open-link"
	"dhelmr/ulauncher-tldr"
	"E1Bos/ulauncher-media-controller"
	"Eckhoff42/Ulauncher-favorite-directories"
	"floydjohn/ulauncher-chrome-profiles"
	"hillaryychan/ulauncher-fzf"
	"iboyperson/ulauncher-system"
	"IkorJefocur/ulauncher-commandrunner"
	"kenanpelit/ulauncher-start-scripts"
	"kenanpelit/ulauncher-zen-profiles"
	"kleber-swf/ulauncher-firefox-profiles"
	"lighttigerxiv/ulauncher-terminal-runner-extension"
	"manahter/ulauncher-doviz"
	"manahter/ulauncher-ip-analysis"
	"manahter/ulauncher-translate"
	"mathe00/ulauncher-plugin-text-tools"
	"maynouf/ulauncher-simple-notes"
	"melianmiko/ulauncher-bluetoothd"
	"nastuzzisamy/ulauncher-google-search"
	"nastuzzisamy/ulauncher-translate"
	"nastuzzisamy/ulauncher-youtube-search"
	"nortmas/chrome-bookmarks"
	"seofernando25/ulauncher-gpt"
	"seon22break/bitcoin-exchange"
	"ulauncher/ulauncher-emoji"
	"ulauncher/ulauncher-kill"
	"yetanothersimon/ulauncher-pulsecontrol"
)

# Main function
main() {
	log $BLUE "Starting Ulauncher Extension Manager..."

	# Initialize directories
	init_directories

	# Clean old installations if requested
	if [[ "$1" == "--clean" || "$1" == "-c" ]]; then
		clean_extensions
	fi

	# Change to extensions directory
	cd "$EXTENSIONS_DIR" || exit 1

	# Initialize JSON
	init_json

	# Total number of extensions
	local total=${#repos[@]}
	local current=0
	local failed=()

	# Install extensions and generate JSON
	for repo in "${repos[@]}"; do
		((current++))
		log $BLUE "[$current/$total] Installing $repo..."

		# Extract extension name
		local ext_name="com.github.${repo//\//.}"

		# Remove if exists
		rm -rf "$ext_name"

		# Clone repository and verify
		if git clone --quiet "https://github.com/$repo" "$ext_name" && [ -d "$ext_name" ]; then
			cd "$EXTENSIONS_DIR/$ext_name" || {
				log $RED "Failed to access repository directory"
				failed+=("$repo")
				continue
			}

			# Add to JSON (true if not last item, false if last)
			if add_to_json "$repo" $([ $current -lt $total ] && echo true || echo false); then
				log $GREEN "✓ Installed $ext_name"
			else
				log $RED "✗ Failed to add metadata for $ext_name"
				failed+=("$repo")
			fi

			cd "$EXTENSIONS_DIR" || exit 1
		else
			log $RED "✗ Failed to clone $repo"
			failed+=("$repo")
		fi
		echo "----------------------------------------"
	done

	# Finish JSON
	finish_json

	# Set proper permissions for generated files
	chmod 644 "$CONFIG_DIR"/*.db "$CONFIG_DIR"/extensions.json

	# Installation summary
	log $BLUE "\nInstallation Summary:"
	log $GREEN "Successfully installed: $((total - ${#failed[@]})) extensions"

	if [ ${#failed[@]} -gt 0 ]; then
		log $RED "Failed installations: ${#failed[@]}"
		for fail in "${failed[@]}"; do
			log $RED "  - $fail"
		done
	fi

	log $BLUE "\nMetadata saved to: $PREFERENCES_FILE"
}

# Handle script arguments
case "$1" in
--help | -h)
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo "  --clean, -c    Clean existing extensions before installation"
	echo "  --help, -h     Show this help message"
	exit 0
	;;
esac

# Run main function with arguments
main "$@"
