#!/usr/bin/env bash

#######################################
# Script Generator for Session Management
#
# Description:
#   Generates session management scripts based on profiles
#   defined in the configuration file.
#
# Usage:
#   ./generate-scripts.sh
#
# Requirements:
#   - jq: for JSON parsing
#   - semsumo: session management tool
#######################################

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Base configuration
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sem/config.json"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"
readonly SEMSUMO="semsumo"
readonly TMP_DIR="/tmp/sem"

# Color definitions
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Helper functions
log_info() {
	echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
	echo -e "${GREEN}✓${NC} $1"
}

create_script() {
	local profile=$1
	local mode=$2
	local script_path="$SCRIPTS_DIR/start-${profile,,}-${mode}.sh"

	# Create script content
	cat >"$script_path" <<EOF
#!/usr/bin/env bash
# Generated script for $profile in $mode mode

# Error handling
set -euo pipefail

# Set temporary directory
export TMPDIR="$TMP_DIR"

# Start session
$SEMSUMO start $profile $mode
EOF

	# Make script executable
	chmod +x "$script_path"
	log_success "Created: start-${profile,,}-${mode}.sh"
}

main() {
	# Check requirements
	if ! command -v jq >/dev/null 2>&1; then
		echo "Error: jq is required but not installed."
		exit 1
	fi

	if [[ ! -f "$CONFIG_FILE" ]]; then
		echo "Error: Configuration file not found at: $CONFIG_FILE"
		exit 1
	fi

	# Create necessary directories
	mkdir -p "$SCRIPTS_DIR"
	mkdir -p "$TMP_DIR"
	chmod 700 "$TMP_DIR"

	log_info "Starting script generation..."
	echo "----------------------------------------"

	# Generate scripts for each profile
	jq -r '.sessions | keys[]' "$CONFIG_FILE" | while read -r profile; do
		log_info "Processing profile: $profile"

		# Generate scripts for each mode
		for mode in always never default; do
			create_script "$profile" "$mode"
		done
		echo ""
	done

	echo "----------------------------------------"
	log_info "Script generation complete!"
	echo ""
	log_info "Usage examples:"
	echo "  $SCRIPTS_DIR/start-zen-kenp-always.sh"
	echo "  $SCRIPTS_DIR/start-zen-kenp-never.sh"
	echo "  $SCRIPTS_DIR/start-zen-kenp-default.sh"
}

# Execute main function
main
