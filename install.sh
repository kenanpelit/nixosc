#!/usr/bin/env bash

# ==============================================================================
# NixOS Installation Script
# Author: kenanpelit (Enhanced version)
# Description: Complete script for NixOS installation and management
# Features:
#   - Automated installation for both laptop and VM configurations
#   - Multi-monitor wallpaper management
#   - Profile-based system management
#   - Advanced backup and restore capabilities
#   - Enhanced error handling and logging
#   - Progress visualization
#   - System health monitoring
# ==============================================================================

VERSION="2.2.0"
SCRIPT_NAME=$(basename "$0")

# Configuration Flags
DEBUG=false
SILENT=false
AUTO=false
UPDATE_FLAKE=false
UPDATE_MODULE=""
BACKUP_ONLY=false
PROFILE_NAME=""
PRE_INSTALL=false

# System Configuration
CURRENT_USERNAME='kenan'
DEFAULT_USERNAME='kenan'
CONFIG_DIR="$HOME/.config/nixos"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
BUILD_CORES=0 # Auto-detect CPU cores
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"
BACKUP_DIR="$HOME/.nixosb"
FLAKE_LOCK="flake.lock"
LOG_FILE="$HOME/.nixosb/nixos-install.log"

# ==============================================================================
# Terminal Color Support
# ==============================================================================
init_colors() {
	if [[ -t 1 ]]; then
		NORMAL=$(tput sgr0)
		WHITE=$(tput setaf 7)
		BLACK=$(tput setaf 0)
		RED=$(tput setaf 1)
		GREEN=$(tput setaf 2)
		YELLOW=$(tput setaf 3)
		BLUE=$(tput setaf 4)
		MAGENTA=$(tput setaf 5)
		CYAN=$(tput setaf 6)
		BRIGHT=$(tput bold)
		UNDERLINE=$(tput smul)
		BG_BLACK=$(tput setab 0)
		BG_GREEN=$(tput setab 2)
	else
		NORMAL=""
		WHITE=""
		BLACK=""
		RED=""
		GREEN=""
		YELLOW=""
		BLUE=""
		MAGENTA=""
		CYAN=""
		BRIGHT=""
		UNDERLINE=""
		BG_BLACK=""
		BG_GREEN=""
	fi
}

# ==============================================================================
# Logging System
# ==============================================================================
setup_logging() {
	mkdir -p "$(dirname "$LOG_FILE")"
	touch "$LOG_FILE"
	log "INFO" "🚀 Starting NixOS installation script v$VERSION"
}

log() {
	local level=$1
	shift
	local message=$*
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local symbol=""
	local color=""

	case "$level" in
	"INFO")
		symbol="ℹ"
		color=$CYAN
		;;
	"WARN")
		symbol="⚠"
		color=$YELLOW
		;;
	"ERROR")
		symbol="✖"
		color=$RED
		;;
	"DEBUG")
		[[ $DEBUG != true ]] && return
		symbol="🔍"
		color=$BLUE
		;;
	"OK")
		symbol="✔"
		color=$GREEN
		;;
	"STEP")
		symbol="→"
		color=$MAGENTA
		;;
	esac

	printf "%b%s %-7s%b %s - %s\n" "$color" "$symbol" "$level" "$NORMAL" "$timestamp" "$message"
	echo "[$level] $timestamp - $message" >>"$LOG_FILE"
}

# ==============================================================================
# Helper Functions
# ==============================================================================
print_header() {
	echo -E "$CYAN
 ═══════════════════════════════════════
   ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗
   ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝
   ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗
   ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║
   ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║
   ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
 ═══════════════════════════════════════

 $BLUE Installation Script v$VERSION $RED
  ! Please don't run as root for proper setup !$GREEN
  → $SCRIPT_NAME $NORMAL
    "
}

print_help() {
	cat <<EOF
${BRIGHT}${GREEN}NixOS Installation Script${NORMAL}
Version: $VERSION

${BRIGHT}Usage:${NORMAL}
    $SCRIPT_NAME [options]

${BRIGHT}Options:${NORMAL}
    -h, --help              Show this help message
    -v, --version           Show script version
    -s, --silent           Run in silent mode
    -d, --debug            Run in debug mode
    -a, --auto HOST        Run with defaults (hay/vhay)
    -u, --update-flake     Update flake.lock
    -m, --update-module    Update specific module
    -b, --backup           Only backup flake.lock
    -r, --restore          Restore from latest backup
    -p, --profile NAME     Specify profile name
    --pre-install          Initial system setup
    -hc, --health-check    System health check
    
${BRIGHT}Examples:${NORMAL}
    $SCRIPT_NAME -a hay    # Automatic laptop setup
    $SCRIPT_NAME -p S1     # Build with profile S1
EOF
}

confirm() {
	[[ $SILENT == true || $AUTO == true ]] && return 0
	echo -en "${BRIGHT}[${GREEN}y${NORMAL}/${RED}n${NORMAL}]${NORMAL} "
	read -r -n 1
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

show_progress() {
	local current=$1
	local total=$2
	local percentage=$((current * 100 / total))

	# Progress bar genişliği 50 karakter
	local bar_width=50
	local completed_width=$((percentage * bar_width / 100))

	# Progress bar'ı oluştur
	printf "\r["
	printf "%${completed_width}s" | tr ' ' '#'
	printf "%$((bar_width - completed_width))s" | tr ' ' ' '
	printf "] %3d%%  " "$percentage"
}

# ==============================================================================
# System Check Functions
# ==============================================================================
check_root() {
	if [[ $EUID -eq 0 ]]; then
		log "ERROR" "This script should NOT be run as root!"
		exit 1
	fi
}

check_system_health() {
	log "STEP" "Performing system health check"

	# Memory check
	local total_mem=$(free -m | awk '/^Mem:/{print $2}')
	local used_mem=$(free -m | awk '/^Mem:/{print $3}')
	local mem_percent=$((used_mem * 100 / total_mem))

	log "INFO" "Memory Usage: ${mem_percent}%"
	[[ $mem_percent -gt 90 ]] && log "WARN" "High memory usage detected"

	# CPU load check
	local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
	log "INFO" "CPU Load: $cpu_load"
	[[ $(echo "$cpu_load > 2" | bc) -eq 1 ]] && log "WARN" "High CPU load"

	log "OK" "System health check completed"
}

# ==============================================================================
# Backup Management
# ==============================================================================
backup_flake() {
	local backup_file="$BACKUP_DIR/flake.lock.$(date +%Y%m%d_%H%M%S)"
	mkdir -p "$BACKUP_DIR"

	if [[ -f $FLAKE_LOCK ]]; then
		cp "$FLAKE_LOCK" "$backup_file"
		log "OK" "Created backup of flake.lock: $backup_file"

		# Keep only last 5 backups
		ls -t "$BACKUP_DIR"/flake.lock.* 2>/dev/null | tail -n +6 | xargs -r rm
		return 0
	else
		log "ERROR" "flake.lock not found"
		return 1
	fi
}

restore_flake_backup() {
	local latest_backup=$(ls -t "$BACKUP_DIR"/flake.lock.* 2>/dev/null | head -n1)

	if [[ -n "$latest_backup" ]]; then
		cp "$latest_backup" "$FLAKE_LOCK"
		log "OK" "Restored flake.lock from backup: $latest_backup"
		return 0
	else
		log "ERROR" "No backup found to restore"
		return 1
	fi
}

# ==============================================================================
# Flake Management
# ==============================================================================
update_single_module() {
	if [[ -z "$UPDATE_MODULE" ]]; then
		log "ERROR" "No module specified for update"
		return 1
	fi

	log "STEP" "Updating module: $UPDATE_MODULE"
	backup_flake

	if nix flake lock --update-input "$UPDATE_MODULE"; then
		log "OK" "Successfully updated module: $UPDATE_MODULE"
		return 0
	else
		log "ERROR" "Failed to update module: $UPDATE_MODULE"
		return 1
	fi
}

list_available_modules() {
	log "INFO" "Available modules in flake:"
	if ! nix flake metadata 2>/dev/null | grep -A 100 "Inputs:" | grep -v "Inputs:" | awk '{print $1}' | grep -v "^$" | sort; then
		log "ERROR" "Failed to list modules"
		exit 1
	fi
}

setup_nix_conf() {
	if [[ ! -f "$NIX_CONF_FILE" ]]; then
		mkdir -p "$NIX_CONF_DIR"
		echo "experimental-features = nix-command flakes" >"$NIX_CONF_FILE"
		log "OK" "Created nix.conf with flakes support"
	else
		if ! grep -q "experimental-features.*=.*flakes" "$NIX_CONF_FILE"; then
			echo "experimental-features = nix-command flakes" >>"$NIX_CONF_FILE"
			log "OK" "Added flakes support to existing nix.conf"
		fi
	fi
}

update_flake() {
	if [[ $UPDATE_FLAKE == true ]]; then
		log "STEP" "Updating flake configuration"
		backup_flake
		setup_nix_conf

		if nix flake update; then
			log "OK" "Flake update completed successfully"
			return 0
		else
			log "ERROR" "Flake update failed"
			return 1
		fi
	fi
}

# ==============================================================================
# User and Host Management
# ==============================================================================
print_question() {
	local question=$1
	echo
	echo -e "${BLUE}┌─────────────────────────── ? ───────────────────────────┐${NORMAL}"
	echo -e "${BLUE}│${NORMAL} $question"
	echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NORMAL}"
}

confirm() {
	[[ $SILENT == true || $AUTO == true ]] && return 0
	echo -en "${BRIGHT}[${GREEN}y${NORMAL}/${RED}n${NORMAL}]${NORMAL} "
	read -r -n 1
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

get_username() {
	if [[ $AUTO == true ]]; then
		username=$DEFAULT_USERNAME
		log "INFO" "Using default username: $username"
		return 0
	fi

	log "STEP" "Setting up username"
	print_question "Enter your ${GREEN}username${NORMAL}: ${YELLOW}"
	read -r username
	echo -en "${NORMAL}"

	print_question "Use ${YELLOW}$username${NORMAL} as ${GREEN}username${NORMAL}?"
	if confirm; then
		log "DEBUG" "Username set to: $username"
		return 0
	fi
	exit 1
}

set_username() {
	log "STEP" "Updating configuration files with username"

	# Güvenli dosya uzantıları ve dizinler
	local safe_files=("*.nix" "configuration.yml" "config.toml" "*.conf")
	local exclude_dirs=(".git" "result" ".direnv" "*.cache")

	# Username formatı kontrolü
	if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
		log "ERROR" "Invalid username format - Use lowercase letters, numbers, - and _"
		return 1
	fi

	# Mevcut kullanıcı adı kontrolü
	if [[ -z "$CURRENT_USERNAME" ]]; then
		log "ERROR" "Current username not defined"
		return 1
	fi

	# Değiştirilecek dosyaları bul
	local files_to_change=()
	for ext in "${safe_files[@]}"; do
		while IFS= read -r -d $'\0' file; do
			if grep -q "$CURRENT_USERNAME" "$file"; then
				files_to_change+=("$file")
			fi
		done < <(find . -type f -name "$ext" $(printf "! -path '*/%s/*' " "${exclude_dirs[@]}") -print0)
	done

	# Dosya kontrolü
	if [ ${#files_to_change[@]} -eq 0 ]; then
		log "WARN" "No files found to update"
		return 0
	fi

	# Değiştirilecek dosyaları göster
	log "INFO" "Files to update:"
	printf '%s\n' "${files_to_change[@]}"

	# Onay al
	echo -en "\nUpdate '${CURRENT_USERNAME}' to '${username}' in these files? "
	if ! confirm; then
		log "INFO" "Operation cancelled by user"
		return 1
	fi

	# Dosyaları güncelle
	local success=0
	for file in "${files_to_change[@]}"; do
		cp "$file" "${file}.bak"
		if sed -i "s/${CURRENT_USERNAME}/${username}/g" "$file"; then
			log "DEBUG" "Updated: $file (backup: ${file}.bak)"
		else
			log "ERROR" "Failed to update: $file"
			mv "${file}.bak" "$file"
			success=1
		fi
	done

	if [ $success -eq 0 ]; then
		log "OK" "Username update completed"
	else
		log "ERROR" "Username update failed"
	fi

	return $success
}

get_host() {
	if [[ $AUTO == true ]]; then
		log "INFO" "Using specified host: $HOST"
		return 0
	fi

	log "STEP" "Selecting host type"
	print_question "Choose host type - [${YELLOW}H${NORMAL}]ay (Laptop) or [${YELLOW}V${NORMAL}]hay (VM): "
	read -n 1 -r
	echo

	case ${REPLY,,} in
	h) HOST='hay' ;;
	v) HOST='vhay' ;;
	*)
		log "ERROR" "Invalid host type"
		exit 1
		;;
	esac

	print_question "Use ${YELLOW}$HOST${NORMAL} as ${GREEN}host${NORMAL}?"
	if confirm; then
		log "DEBUG" "Host type set to: $HOST"
		return 0
	fi
	exit 1
}

build_system() {
	log "STEP" "Starting system build"
	print_question "Proceed with system build?"
	if confirm; then
		local build_command="sudo nixos-rebuild switch --cores $BUILD_CORES --flake \".#${HOST}\" --option warn-dirty false"

		[[ -n "$PROFILE_NAME" ]] && {
			build_command+=" --profile-name \"$PROFILE_NAME\""
			log "INFO" "Using profile: $PROFILE_NAME"
		}

		log "INFO" "Executing: $build_command"

		if eval "$build_command"; then
			log "OK" "System built successfully"
			[[ -n "$PROFILE_NAME" ]] && log "OK" "Profile created: $PROFILE_NAME"
			return 0
		else
			log "ERROR" "Build failed"
			return 1
		fi
	else
		log "ERROR" "Build cancelled by user"
		exit 1
	fi
}

# ==============================================================================
# Installation Functions
# ==============================================================================
setup_directories() {
	log "STEP" "Creating required directories"
	local dirs=(
		"$HOME/Pictures/wallpapers/others"
		"$HOME/Pictures/wallpapers/nixos"
		"$CONFIG_DIR"
	)

	for dir in "${dirs[@]}"; do
		mkdir -p "$dir"
		log "DEBUG" "Created: $dir"
	done
}

copy_wallpapers() {
	log "STEP" "Setting up wallpapers"
	cp -r wallpapers/wallpaper.png "$WALLPAPER_DIR"
	cp -r wallpapers/others/* "$WALLPAPER_DIR/others/"
	cp -r wallpapers/nixos/* "$WALLPAPER_DIR/nixos/"
	log "OK" "Wallpapers copied successfully"
}

copy_hardware_config() {
	local source="/etc/nixos/hardware-configuration.nix"
	local target="hosts/${HOST}/hardware-configuration.nix"

	if [[ ! -f "$source" ]]; then
		log "ERROR" "Hardware configuration not found: $source"
		exit 1
	fi

	log "STEP" "Copying hardware configuration"
	cp "$source" "$target"
	log "OK" "Hardware configuration copied for host: $HOST"
}

build_system() {
	log "STEP" "Starting system build"
	echo -en "Proceed with system build? "
	if confirm; then
		local build_command="sudo nixos-rebuild switch --cores $BUILD_CORES --flake \".#${HOST}\" --option warn-dirty false"

		[[ -n "$PROFILE_NAME" ]] && {
			build_command+=" --profile-name \"$PROFILE_NAME\""
			log "INFO" "Using profile: $PROFILE_NAME"
		}

		log "INFO" "Executing: $build_command"

		if eval "$build_command"; then
			log "OK" "System built successfully"
			[[ -n "$PROFILE_NAME" ]] && log "OK" "Profile created: $PROFILE_NAME"
			return 0
		else
			log "ERROR" "Build failed"
			return 1
		fi
	else
		log "ERROR" "Build cancelled by user"
		exit 1
	fi
}

# ==============================================================================
# Profile Management
# ==============================================================================
list_profiles() {
	log "STEP" "Listing NixOS profiles"
	if output=$(nix profile list); then
		echo "$output"
		local count=$(echo "$output" | wc -l)
		log "INFO" "Found $count profiles"
	else
		log "ERROR" "Failed to list profiles"
		return 1
	fi
}

delete_profile() {
	local profile_id=$1
	[[ -z "$profile_id" ]] && {
		log "ERROR" "No profile ID specified"
		return 1
	}

	log "STEP" "Deleting profile: $profile_id"
	if nix profile remove "$profile_id"; then
		log "OK" "Deleted profile: $profile_id"
		return 0
	else
		log "ERROR" "Failed to delete profile: $profile_id"
		return 1
	fi
}

get_profile_name() {
	if [[ -z "$PROFILE_NAME" && $SILENT == false ]]; then
		echo # Yeni satır
		print_question "Specify a profile name?"
		if confirm; then
			print_question "Enter profile name: ${YELLOW}"
			read -r PROFILE_NAME
			echo -en "$NORMAL"
			log "DEBUG" "Profile name: $PROFILE_NAME"
		fi
	fi
}

# ==============================================================================
# Pre-installation Setup
# ==============================================================================
setup_initial_config() {
	local host_type=$1
	log "STEP" "Setting up initial configuration for $host_type"

	local template="hosts/${host_type}/templates/initial-configuration.nix"
	local config="/etc/nixos/configuration.nix"

	# Verify prerequisites
	[[ ! -f "$template" ]] && {
		log "ERROR" "Template not found: $template"
		return 1
	}

	groups | grep -q '\bwheel\b' || {
		log "ERROR" "Current user must be in wheel group"
		return 1
	}

	# Backup existing config
	[[ -f "$config" ]] && {
		local backup="${config}.backup-$(date +%Y%m%d_%H%M%S)"
		log "INFO" "Backing up: $config → $backup"
		command sudo cp "$config" "$backup"
	}

	# Apply new config
	if command sudo cp "$template" "$config" &&
		command sudo chown root:root "$config" &&
		command sudo chmod 644 "$config"; then
		log "OK" "Initial configuration complete"
		return 0
	else
		log "ERROR" "Failed to setup configuration"
		return 1
	fi
}

pre_install() {
	local host_type=$1
	log "STEP" "Starting pre-installation for $host_type"

	setup_initial_config "$host_type" || {
		log "ERROR" "Initial configuration failed"
		return 1
	}

	log "STEP" "Rebuilding system"
	if sudo nixos-rebuild switch --profile-name start; then
		log "OK" "Pre-installation complete"
		echo -e "\n${GREEN}Initial setup complete.${NORMAL}"
		echo -e "Please ${YELLOW}reboot${NORMAL} and run:"
		echo -e "${BLUE}$SCRIPT_NAME${NORMAL} for main installation"
		return 0
	else
		log "ERROR" "System rebuild failed"
		return 1
	fi
}

# ==============================================================================
# Main Installation Process
# ==============================================================================
install() {
	[[ $BACKUP_ONLY == true ]] && {
		backup_flake
		exit $?
	}

	[[ -n "$UPDATE_MODULE" ]] && {
		update_single_module
		exit $?
	}

	[[ $PRE_INSTALL == true ]] && {
		pre_install "$HOST"
		exit $?
	}

	# Main installation steps
	local steps=(
		"setup_directories"
		"copy_wallpapers"
		"copy_hardware_config"
		"get_profile_name"
	)

	[[ $UPDATE_FLAKE == true ]] && steps+=("update_flake")
	steps+=("build_system")

	local total=${#steps[@]}
	local current=0

	for step in "${steps[@]}"; do
		((current++))
		show_progress $current $total
		$step || {
			log "ERROR" "Failed at step: $step"
			exit 1
		}
	done
	echo # New line after progress
}

# ==============================================================================
# Command Line Argument Processing
# ==============================================================================
process_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--pre-install) PRE_INSTALL=true ;;
		--list-profiles)
			list_profiles
			exit
			;;
		--delete-profile)
			shift
			delete_profile "$1"
			exit
			;;
		-h | --help)
			print_help
			exit
			;;
		-v | --version)
			echo "v$VERSION"
			exit
			;;
		-s | --silent) SILENT=true ;;
		-d | --debug) DEBUG=true ;;
		-p | --profile)
			shift
			PROFILE_NAME="$1"
			;;
		-u | --update-flake) UPDATE_FLAKE=true ;;
		-m | --update-module)
			shift
			UPDATE_MODULE="$1"
			;;
		-b | --backup) BACKUP_ONLY=true ;;
		-r | --restore)
			restore_flake_backup
			exit
			;;
		-l | --list-modules)
			list_available_modules
			exit
			;;
		-hc | --health-check)
			check_system_health
			exit
			;;
		-a | --auto)
			AUTO=true
			SILENT=true
			shift
			if [[ -n "$1" && "$1" =~ ^(hay|vhay)$ ]]; then
				HOST="$1"
			else
				log "ERROR" "Invalid host (use hay/vhay)"
				exit 1
			fi
			;;
		*)
			log "ERROR" "Unknown option: $1"
			print_help
			exit 1
			;;
		esac
		shift
	done
}

show_summary() {
	log "INFO" "Installation Summary"
	local items=(
		"Username|$username"
		"Host|$HOST"
		"Configuration|/etc/nixos"
		"Home Directory|$HOME"
	)

	[[ -n "$PROFILE_NAME" ]] && items+=("Profile Name|$PROFILE_NAME")
	[[ $UPDATE_FLAKE == true ]] && items+=("Flake Status|Updated")
	[[ -n "$UPDATE_MODULE" ]] && items+=("Updated Module|$UPDATE_MODULE")

	for item in "${items[@]}"; do
		local key=${item%|*}
		local value=${item#*|}
		echo -e "${GREEN}✓${NORMAL} ${key}: ${YELLOW}${value}${NORMAL}"
	done

	log "OK" "Installation completed successfully!"
}

# ==============================================================================
# Main Entry Point
# ==============================================================================
main() {
	init_colors
	setup_logging
	process_args "$@"
	check_root
	check_system_health

	[[ $AUTO == false ]] && print_header

	get_username
	set_username
	get_host
	install
	show_summary
}

main "$@"
exit 0
