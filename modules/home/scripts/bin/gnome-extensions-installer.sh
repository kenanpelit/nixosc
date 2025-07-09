#!/usr/bin/env bash

#===============================================================================
#
#   Script: GNOME Extensions Auto Installer
#   Version: 1.0.0
#   Description: Automatically install and enable GNOME Shell extensions
#
#===============================================================================

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Extension list from your config
declare -a EXTENSIONS=(
	"clipboard-indicator@tudmotu.com"
	"dash-to-panel@jderose9.github.com"
	"alt-tab-scroll-workaround@lucasresck.github.io"
	"extension-list@tu.berry"
	"auto-move-windows@gnome-shell-extensions.gcampax.github.com"
	"bluetooth-quick-connect@bjarosze.gmail.com"
	"no-overview@fthx"
	"Vitals@CoreCoding.com"
	"tilingshell@ferrarodomenico.com"
	"weatheroclock@CleoMenezesJr.github.io"
	"spotify-controls@Sonath21"
	"space-bar@luchrioh"
	"sound-percentage@subashghimire.info.np"
	"screenshort-cut@pauloimon"
	"window-centering@hnjjhmtr27"
	"disable-workspace-animation@ethnarque"
	"gsconnect@andyholmes.github.io"
	"mullvadindicator@pobega.github.com"
)

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

check_dependencies() {
	log "INFO" "Checking dependencies..."

	# Check if GNOME Shell is running (check for gnome-shell binary)
	if ! pgrep -f "gnome-shell" >/dev/null; then
		log "ERROR" "GNOME Shell is not running!"
		log "INFO" "Current desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
		exit 1
	fi

	log "SUCCESS" "GNOME Shell is running!"

	# Check if gnome-extensions command exists
	if ! command -v gnome-extensions &>/dev/null; then
		log "ERROR" "gnome-extensions command not found!"
		log "INFO" "Install with: sudo apt install gnome-shell-extension-prefs"
		exit 1
	fi

	# Check if curl exists for downloading
	if ! command -v curl &>/dev/null; then
		log "ERROR" "curl command not found!"
		log "INFO" "Install with: sudo apt install curl"
		exit 1
	fi

	# Check if unzip exists
	if ! command -v unzip &>/dev/null; then
		log "ERROR" "unzip command not found!"
		log "INFO" "Install with: sudo apt install unzip"
		exit 1
	fi

	log "SUCCESS" "All dependencies found!"
}

get_gnome_version() {
	gnome-shell --version | grep -oP '\d+\.\d+' | head -1
}

install_extension() {
	local extension_uuid="$1"
	local count="$2"
	local total="$3"

	log "INFO" "[$count/$total] Installing: $extension_uuid"

	# Check if already installed
	if gnome-extensions list | grep -q "^$extension_uuid$"; then
		log "WARN" "Already installed: $extension_uuid"
		return 0
	fi

	# Get GNOME Shell version
	local gnome_version=$(get_gnome_version)

	# Create temp directory
	local temp_dir=$(mktemp -d)

	# Try to download from extensions.gnome.org
	local extension_name=$(echo "$extension_uuid" | cut -d'@' -f1)
	local download_url="https://extensions.gnome.org/extension-data/${extension_name}.v1.shell-extension.zip"

	log "INFO" "Downloading from: $download_url"

	if curl -L -o "$temp_dir/extension.zip" "$download_url" 2>/dev/null; then
		# Extract to extensions directory
		local extensions_dir="$HOME/.local/share/gnome-shell/extensions/$extension_uuid"
		mkdir -p "$extensions_dir"

		if unzip -q "$temp_dir/extension.zip" -d "$extensions_dir"; then
			log "SUCCESS" "Downloaded and extracted: $extension_uuid"
		else
			log "ERROR" "Failed to extract: $extension_uuid"
			rm -rf "$temp_dir"
			return 1
		fi
	else
		log "WARN" "Could not download automatically: $extension_uuid"
		log "INFO" "Please install manually from: https://extensions.gnome.org/"
		rm -rf "$temp_dir"
		return 1
	fi

	# Cleanup
	rm -rf "$temp_dir"

	# Enable the extension
	if gnome-extensions enable "$extension_uuid" 2>/dev/null; then
		log "SUCCESS" "Enabled: $extension_uuid"
	else
		log "WARN" "Could not enable automatically: $extension_uuid"
		log "INFO" "You may need to restart GNOME Shell or enable manually"
	fi
}

install_all_extensions() {
	log "INFO" "Installing ${#EXTENSIONS[@]} GNOME Shell extensions..."
	echo

	local count=1
	local failed=0
	local success=0

	for extension in "${EXTENSIONS[@]}"; do
		if install_extension "$extension" "$count" "${#EXTENSIONS[@]}"; then
			((success++))
		else
			((failed++))
		fi
		echo
		((count++))
		sleep 1 # Small delay to avoid overwhelming the system
	done

	echo
	log "INFO" "Installation Summary:"
	log "SUCCESS" "Successfully installed: $success"
	if [[ $failed -gt 0 ]]; then
		log "WARN" "Failed to install: $failed"
	fi
}

restart_gnome_shell() {
	log "INFO" "Restarting GNOME Shell to apply changes..."

	# For Wayland, we can't restart shell directly, user needs to logout/login
	if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
		log "WARN" "You're using Wayland. Please logout and login to restart GNOME Shell."
		log "INFO" "Or run: Alt+F2 → type 'r' → Enter (if on X11)"
	else
		# For X11, we can restart shell
		if command -v gnome-shell &>/dev/null; then
			nohup gnome-shell --replace &>/dev/null &
			disown
			log "SUCCESS" "GNOME Shell restarted!"
		fi
	fi
}

show_installed_extensions() {
	log "INFO" "Currently installed extensions:"
	gnome-extensions list | while read extension; do
		local status=$(gnome-extensions info "$extension" | grep -i state | awk '{print $2}')
		if [[ "$status" == "ENABLED" ]]; then
			echo -e "  ${GREEN}✓${NC} $extension"
		else
			echo -e "  ${RED}✗${NC} $extension"
		fi
	done
}

main() {
	echo -e "${BOLD}${CYAN}GNOME Extensions Auto Installer${NC}"
	echo -e "${BOLD}Installing extensions from your NixOS config${NC}"
	echo

	check_dependencies
	echo

	log "INFO" "GNOME Shell version: $(get_gnome_version)"
	log "INFO" "Session type: ${XDG_SESSION_TYPE:-unknown}"
	echo

	install_all_extensions

	echo
	log "INFO" "Installation completed!"

	# Show current status
	echo
	show_installed_extensions

	echo
	log "INFO" "Manual installation links for failed extensions:"
	log "INFO" "• GNOME Extensions website: https://extensions.gnome.org/"
	log "INFO" "• Extension Manager: flatpak install flathub com.mattjakeman.ExtensionManager"

	echo
	log "WARN" "Some extensions may require GNOME Shell restart to work properly."

	# Ask if user wants to restart shell
	if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
		echo
		read -p "Do you want to restart GNOME Shell now? (y/N): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			restart_gnome_shell
		fi
	fi

	echo
	log "SUCCESS" "Done! Enjoy your GNOME extensions! 🎉"
}

# Run main function
main "$@"
