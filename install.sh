#!/usr/bin/env bash

# ==============================================================================
# NixOS Installation Script
# Author: kenanpelit (Enhanced version)
# Description: Complete script for NixOS installation and management
# ==============================================================================

VERSION="2.1.0"
SCRIPT_NAME=$(basename "$0")
DEBUG=false
SILENT=false
AUTO=false
UPDATE_FLAKE=false
UPDATE_MODULE=""
BACKUP_ONLY=false
PROFILE_NAME=""
PRE_INSTALL=false # Yeni eklenen parametre

# Configuration Variables
CURRENT_USERNAME='kenan'
DEFAULT_USERNAME='kenan'
CONFIG_DIR="$HOME/.config/nixos"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
BUILD_CORES=4
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"
BACKUP_DIR="$HOME/.nixosb"
FLAKE_LOCK="flake.lock"
LOG_FILE="$HOME/.nixosb/nixos-install.log"

# Color Definitions
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
	fi
}

# Logging Functions
setup_logging() {
	mkdir -p "$(dirname "$LOG_FILE")"
	touch "$LOG_FILE"
}

log() {
	local level=$1
	shift
	local message=$*
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	case "$level" in
	"INFO") echo -e "${GREEN}[INFO]${NORMAL} ${timestamp} - $message" ;;
	"WARN") echo -e "${YELLOW}[WARN]${NORMAL} ${timestamp} - $message" ;;
	"ERROR") echo -e "${RED}[ERROR]${NORMAL} ${timestamp} - $message" ;;
	"DEBUG") [[ $DEBUG == true ]] && echo -e "${BLUE}[DEBUG]${NORMAL} ${timestamp} - $message" ;;
	esac

	echo "[$level] $timestamp - $message" >>"$LOG_FILE"
}

# Helper Functions
print_help() {
	cat <<EOF
${BRIGHT}${GREEN}NixOS Installation and Management Script${NORMAL}
Version: $VERSION

${BRIGHT}Usage:${NORMAL}
    $SCRIPT_NAME [options]

${BRIGHT}Options:${NORMAL}
    -h, --help              Show this help message
    -v, --version           Show script version
    -s, --silent           Run in silent mode (no confirmations)
    -d, --debug            Run in debug mode
    -a, --auto HOST        Run with default settings for specified host (hay/vhay)
    -u, --update-flake     Update flake.lock
    -m, --update-module    Update specific module
    -b, --backup           Only backup flake.lock
    -r, --restore          Restore from latest backup
    -l, --list-modules     List available modules
    -p, --profile NAME     Specify profile name for nixos-rebuild
    --pre-install          Perform initial system setup before main installation
    -hc, --health-check    Perform system health check (disabled by default)
    --list-profiles        List all NixOS profiles
    --delete-profile ID    Delete a specific profile by ID

${BRIGHT}Host Types:${NORMAL}
    hay                    Laptop configuration (HAY)
    vhay                   QEMU Virtual Machine configuration (VHAY)

${BRIGHT}Examples:${NORMAL}
    $SCRIPT_NAME                      # Normal installation
    $SCRIPT_NAME --silent             # Silent installation
    $SCRIPT_NAME -a hay              # Automatic laptop setup
    $SCRIPT_NAME -a hay --pre-install # Initial system setup for laptop
    $SCRIPT_NAME -m home-manager      # Update home-manager module
    $SCRIPT_NAME -p myprofile        # Build with specific profile name
    $SCRIPT_NAME -hc                  # Check system health
EOF
}

print_version() {
	echo -e "${GREEN}NixOS Installation Script${NORMAL} version ${BLUE}$VERSION${NORMAL}"
}

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

 $BLUE Enhanced Installation Script v$VERSION $RED
  ! To make sure everything runs correctly DONT run as root !$GREEN
  → $SCRIPT_NAME $NORMAL
    "
}

confirm() {
	[[ $SILENT == true || $AUTO == true ]] && return 0

	echo -en "[${GREEN}y${NORMAL}/${RED}n${NORMAL}]: "
	read -n 1 -r
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

# Get profile name if not specified via command line
get_profile_name() {
	if [[ -z "$PROFILE_NAME" && $SILENT == false ]]; then
		echo -en "Would you like to specify a profile name? "
		if confirm; then
			echo -en "Enter profile name: ${YELLOW}"
			read -r PROFILE_NAME
			echo -en "$NORMAL"
			log "DEBUG" "Profile name set to: $PROFILE_NAME"
		fi
	fi
}

# System Check Functions
check_root() {
	if [[ $EUID -eq 0 ]]; then
		log "ERROR" "This script should NOT be run as root!"
		exit 1
	fi
}

check_disk_space() {
	local required_space=10000000 # 10GB in KB
	local available_space=$(df -k "$HOME" | awk 'NR==2 {print $4}')

	if [[ $available_space -lt $required_space ]]; then
		log "ERROR" "Not enough disk space. Required: 10GB, Available: $((available_space / 1024 / 1024))GB"
		exit 1
	fi
	log "DEBUG" "Disk space check passed"
}

check_system_health() {
	log "INFO" "Performing system health check..."
	check_disk_space

	local available_mem=$(free -m | awk 'NR==2 {print $7}')
	if [[ $available_mem -lt 1024 ]]; then
		log "WARN" "Low memory available: ${available_mem}MB"
	fi

	local cpu_load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1)
	if [ "$(printf "%.0f" "${cpu_load}")" -gt 2 ]; then
		log "WARN" "High CPU load: $cpu_load"
	fi

	if ! nix-store --verify --check-contents >/dev/null 2>&1; then
		log "WARN" "Nix store integrity check failed"
	fi

	if ! nix-channel --update >/dev/null 2>&1; then
		log "WARN" "Unable to update nix-channel"
	fi

	log "INFO" "System health check completed"
}

# Pre-install Functions
setup_initial_config() {
	local host_type=$1
	local config_file="/etc/nixos/configuration.nix"

	log "INFO" "Setting up initial configuration for $host_type"

	# Template dosyasını hedef hosta göre seç
	local template_file="hosts/${host_type}/templates/initial-configuration.nix"

	if [[ ! -f "$template_file" ]]; then
		log "ERROR" "Initial configuration template not found for $host_type"
		return 1
	fi

	# Wheel grubunda olup olmadığını kontrol et
	if ! groups | grep -q '\bwheel\b'; then
		log "ERROR" "Current user must be in the wheel group"
		return 1
	fi

	# Mevcut configuration.nix'i yedekle
	if [[ -f "$config_file" ]]; then
		local backup_file="${config_file}.backup-$(date +%Y%m%d_%H%M%S)"
		log "INFO" "Backing up existing configuration to $backup_file"
		command sudo cp "$config_file" "$backup_file"
	fi

	# Yeni konfigürasyonu kopyala ve yetkilerini ayarla
	if command sudo cp "$template_file" "$config_file" &&
		command sudo chown root:root "$config_file" &&
		command sudo chmod 644 "$config_file"; then
		log "INFO" "Initial configuration setup completed"
		return 0
	else
		log "ERROR" "Failed to copy or set permissions on configuration file"
		return 1
	fi
}

pre_install() {
	local host_type=$1
	log "INFO" "Starting pre-installation process for $host_type"

	# İlk konfigürasyonu ayarla
	if ! setup_initial_config "$host_type"; then
		log "ERROR" "Failed to setup initial configuration"
		return 1
	fi

	# Sistemi yeniden yapılandır
	log "INFO" "Rebuilding system with initial configuration"
	if sudo nixos-rebuild switch --profile-name start; then
		log "INFO" "Pre-installation completed successfully"
		echo -e "\n${GREEN}Initial system configuration complete.${NORMAL}"
		echo -e "Please ${YELLOW}reboot${NORMAL} your system and then run:"
		echo -e "${BLUE}./install.sh${NORMAL} for the main installation."
		return 0
	else
		log "ERROR" "System rebuild failed"
		return 1
	fi
}

# Flake Management Functions
backup_flake() {
	local backup_file="$BACKUP_DIR/flake.lock.$(date +%Y%m%d_%H%M%S)"
	mkdir -p "$BACKUP_DIR"

	if [[ -f $FLAKE_LOCK ]]; then
		cp "$FLAKE_LOCK" "$backup_file"
		log "INFO" "Created backup of flake.lock: $backup_file"

		# Keep only last 5 backups
		ls -t "$BACKUP_DIR"/flake.lock.* 2>/dev/null | tail -n +6 | xargs -r rm
		return 0
	else
		log "ERROR" "flake.lock not found"
		return 1
	fi
}

update_single_module() {
	if [[ -z "$UPDATE_MODULE" ]]; then
		log "ERROR" "No module specified for update"
		return 1
	fi

	log "INFO" "Updating module: $UPDATE_MODULE"
	backup_flake

	if nix flake lock --update-input "$UPDATE_MODULE"; then
		log "INFO" "Successfully updated module: $UPDATE_MODULE"
		return 0
	else
		log "ERROR" "Failed to update module: $UPDATE_MODULE"
		return 1
	fi
}

list_available_modules() {
	log "INFO" "Available modules in flake:"
	if ! nix flake metadata 2>/dev/null | grep -A 100 "Inputs:" | grep -v "Inputs:" | awk '{print $1}' | grep -v "^$" | sort; then
		log "ERROR" "Failed to list modules. Make sure you're in a directory with a valid flake.nix"
		exit 1
	fi
}

restore_flake_backup() {
	local latest_backup=$(ls -t "$BACKUP_DIR"/flake.lock.* 2>/dev/null | head -n1)

	if [[ -n "$latest_backup" ]]; then
		cp "$latest_backup" "$FLAKE_LOCK"
		log "INFO" "Restored flake.lock from backup: $latest_backup"
		return 0
	else
		log "ERROR" "No backup found to restore"
		return 1
	fi
}

setup_nix_conf() {
	if [[ ! -f "$NIX_CONF_FILE" ]]; then
		mkdir -p "$NIX_CONF_DIR"
		echo "experimental-features = nix-command flakes" >"$NIX_CONF_FILE"
		log "INFO" "Created nix.conf with flakes support"
	else
		if ! grep -q "experimental-features.*=.*flakes" "$NIX_CONF_FILE"; then
			echo "experimental-features = nix-command flakes" >>"$NIX_CONF_FILE"
			log "INFO" "Added flakes support to existing nix.conf"
		else
			log "DEBUG" "Flakes support already configured in nix.conf"
		fi
	fi
}

update_flake() {
	if [[ $UPDATE_FLAKE == true ]]; then
		log "INFO" "Updating flake configuration"
		backup_flake
		setup_nix_conf
		if nix flake update; then
			log "INFO" "Flake update completed successfully"
			return 0
		else
			log "ERROR" "Flake update failed"
			return 1
		fi
	fi
}

# User and Host Management Functions
get_username() {
	if [[ $AUTO == true ]]; then
		username=$DEFAULT_USERNAME
		log "INFO" "Using default username: $username"
		return 0
	fi

	log "INFO" "Setting up username"
	echo -en "Enter your${GREEN} username${NORMAL}: ${YELLOW}"
	read -r username
	echo -en "$NORMAL"

	echo -en "Use${YELLOW} $username${NORMAL} as ${GREEN}username${NORMAL}? "
	if confirm; then
		log "DEBUG" "Username set to: $username"
		return 0
	else
		log "ERROR" "Username setup cancelled"
		exit 1
	fi
}

set_username() {
	log "INFO" "Updating configuration files with new username"

	# Kontrol edilecek güvenli dosya uzantıları ve dizinler
	local safe_files=(
		"*.nix"
		"configuration.yml"
		"config.toml"
		"*.conf"
	)

	# Yoksayılacak dizinler
	local exclude_dirs=(
		".git"
		"result"
		".direnv"
		"*.cache"
	)

	# Username formatını kontrol et
	if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
		log "ERROR" "Geçersiz username formatı. Sadece küçük harf, rakam, tire ve alt çizgi kullanılabilir"
		return 1
	fi

	# Mevcut kullanıcı adının boş olmadığından emin ol
	if [[ -z "$CURRENT_USERNAME" ]]; then
		log "ERROR" "Mevcut kullanıcı adı (CURRENT_USERNAME) tanımlanmamış"
		return 1
	fi

	# Değiştirilecek dosyaları önce listele
	local files_to_change=()
	for ext in "${safe_files[@]}"; do
		while IFS= read -r -d $'\0' file; do
			if grep -q "$CURRENT_USERNAME" "$file"; then
				files_to_change+=("$file")
			fi
		done < <(find . -type f -name "$ext" \
			$(printf "! -path '*/%s/*' " "${exclude_dirs[@]}") \
			-print0)
	done

	if [ ${#files_to_change[@]} -eq 0 ]; then
		log "WARN" "Değiştirilecek dosya bulunamadı"
		return 0
	fi

	echo -e "\nDeğiştirilecek dosyalar:"
	printf '%s\n' "${files_to_change[@]}"

	echo -en "\nBu dosyalarda '${CURRENT_USERNAME}' -> '${username}' değişikliği yapılacak. Onaylıyor musunuz? "
	if ! confirm; then
		log "INFO" "İşlem kullanıcı tarafından iptal edildi"
		return 1
	fi

	for file in "${files_to_change[@]}"; do
		cp "$file" "${file}.bak"
		if sed -i "s/${CURRENT_USERNAME}/${username}/g" "$file"; then
			log "DEBUG" "$file dosyası güncellendi (yedek: ${file}.bak)"
		else
			log "ERROR" "$file dosyası güncellenemedi"
			mv "${file}.bak" "$file"
		fi
	done

	log "INFO" "Username güncelleme işlemi tamamlandı"
	return 0
}

get_host() {
	if [[ $AUTO == true ]]; then
		log "INFO" "Using specified host: $HOST"
		return 0
	fi

	log "INFO" "Selecting host type"
	echo -en "Choose a ${GREEN}host${NORMAL} - [${YELLOW}H${NORMAL}]ay (Laptop) or [${YELLOW}V${NORMAL}]hay (Virtual Machine): "
	read -n 1 -r
	echo

	case ${REPLY,,} in
	h) HOST='hay' ;;
	v) HOST='vhay' ;;
	*)
		log "ERROR" "Invalid host type selected"
		exit 1
		;;
	esac

	echo -en "Use the${YELLOW} $HOST${NORMAL} ${GREEN}host${NORMAL}? "
	if confirm; then
		log "DEBUG" "Host type set to: $HOST"
		return 0
	else
		log "ERROR" "Host selection cancelled"
		exit 1
	fi
}

# Installation Functions
setup_directories() {
	log "INFO" "Creating required directories"
	local dirs=(
		"$HOME/Music"
		"$HOME/Documents"
		"$HOME/Tmp"
		"$HOME/Pictures/wallpapers/others"
		"$HOME/Pictures/wallpapers/nixos"
		"$CONFIG_DIR"
	)

	for dir in "${dirs[@]}"; do
		mkdir -p "$dir"
		log "DEBUG" "Created directory: $dir"
	done
}

copy_wallpapers() {
	log "INFO" "Copying wallpapers"
	cp -r wallpapers/wallpaper.png "$WALLPAPER_DIR"
	cp -r wallpapers/others/* "$WALLPAPER_DIR/others/"
	cp -r wallpapers/nixos/* "$WALLPAPER_DIR/nixos/"
	log "DEBUG" "Wallpapers copied successfully"
}

copy_hardware_config() {
	local source="/etc/nixos/hardware-configuration.nix"
	local target="hosts/${HOST}/hardware-configuration.nix"

	if [[ ! -f "$source" ]]; then
		log "ERROR" "Hardware configuration not found at $source"
		exit 1
	fi

	log "INFO" "Copying hardware configuration"
	cp "$source" "$target"
	log "DEBUG" "Hardware configuration copied for host: $HOST"
}

build_system() {
	log "INFO" "Starting system build"
	echo -en "You are about to start the system build, do you want to proceed? "
	if confirm; then
		log "INFO" "Building the system..."

		local build_command="sudo nixos-rebuild switch --cores $BUILD_CORES --flake \".#${HOST}\" --option warn-dirty false"

		if [[ -n "$PROFILE_NAME" ]]; then
			build_command+=" --profile-name \"$PROFILE_NAME\""
			log "INFO" "Using profile name: $PROFILE_NAME"
			log "DEBUG" "Final build command: $build_command"
		fi

		echo -e "${BLUE}Executing:${NORMAL} $build_command"

		if eval "$build_command"; then
			log "INFO" "System built successfully"
			if [[ -n "$PROFILE_NAME" ]]; then
				log "INFO" "System profile created with name: $PROFILE_NAME"
			fi
			return 0
		else
			log "ERROR" "System build failed"
			exit 1
		fi
	else
		log "ERROR" "System build cancelled"
		exit 1
	fi
}

# Main Installation Process
install() {
	if [[ $BACKUP_ONLY == true ]]; then
		backup_flake
		exit $?
	fi

	if [[ -n "$UPDATE_MODULE" ]]; then
		update_single_module
		exit $?
	fi

	if [[ $PRE_INSTALL == true ]]; then
		pre_install "$HOST"
		exit $?
	fi

	setup_directories
	copy_wallpapers
	copy_hardware_config
	get_profile_name

	if [[ $UPDATE_FLAKE == true ]]; then
		update_flake
	fi

	build_system
}

show_summary() {
	log "INFO" "Installation Summary"
	echo -e "${GREEN}✓${NORMAL} Username: ${YELLOW}$username${NORMAL}"
	echo -e "${GREEN}✓${NORMAL} Host: ${YELLOW}$HOST${NORMAL}"
	if [[ -n "$PROFILE_NAME" ]]; then
		echo -e "${GREEN}✓${NORMAL} Profile Name: ${YELLOW}$PROFILE_NAME${NORMAL}"
	fi
	echo -e "${GREEN}✓${NORMAL} Configuration: ${YELLOW}/etc/nixos${NORMAL}"
	echo -e "${GREEN}✓${NORMAL} Home Directory: ${YELLOW}$HOME${NORMAL}"
	if [[ $UPDATE_FLAKE == true ]]; then
		echo -e "${GREEN}✓${NORMAL} Flake Status: ${YELLOW}Updated${NORMAL}"
	fi
	if [[ -n "$UPDATE_MODULE" ]]; then
		echo -e "${GREEN}✓${NORMAL} Updated Module: ${YELLOW}$UPDATE_MODULE${NORMAL}"
	fi
	echo
	log "INFO" "Installation completed successfully!"
}

# Profile Management Functions
list_profiles() {
	log "INFO" "Listing all NixOS profiles:"
	nix profile list
	local num_profiles=$(nix profile list | wc -l)
	log "INFO" "Found $num_profiles profiles"
}

delete_profile() {
	local profile_id=$1
	if [[ -z "$profile_id" ]]; then
		log "ERROR" "No profile ID specified for deletion"
		return 1
	fi

	log "INFO" "Attempting to delete profile ID: $profile_id"
	if nix profile remove "$profile_id"; then
		log "INFO" "Successfully deleted profile ID: $profile_id"
		return 0
	else
		log "ERROR" "Failed to delete profile ID: $profile_id"
		return 1
	fi
}

# Command Line Arguments Processing
process_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--pre-install)
			PRE_INSTALL=true
			shift
			;;
		--list-profiles)
			list_profiles
			exit 0
			;;
		--delete-profile)
			shift
			delete_profile "$1"
			exit $?
			;;
		-h | --help)
			print_help
			exit 0
			;;
		-v | --version)
			print_version
			exit 0
			;;
		-s | --silent)
			SILENT=true
			shift
			;;
		-d | --debug)
			DEBUG=true
			shift
			;;
		-p | --profile)
			shift
			PROFILE_NAME="$1"
			shift
			;;
		-u | --update-flake)
			UPDATE_FLAKE=true
			shift
			;;
		-m | --update-module)
			shift
			UPDATE_MODULE="$1"
			shift
			;;
		-b | --backup)
			BACKUP_ONLY=true
			shift
			;;
		-r | --restore)
			restore_flake_backup
			exit $?
			;;
		-l | --list-modules)
			list_available_modules
			exit 0
			;;
		-hc | --health-check)
			check_system_health
			exit 0
			;;
		-a | --auto)
			AUTO=true
			SILENT=true
			shift
			if [[ -n "$1" && "$1" =~ ^(hay|vhay)$ ]]; then
				HOST="$1"
				shift
			else
				log "ERROR" "Invalid or missing host for auto mode. Use 'hay' or 'vhay'"
				exit 1
			fi
			;;
		*)
			log "ERROR" "Unknown option: $1"
			print_help
			exit 1
			;;
		esac
	done
}

# Main Function
main() {
	init_colors
	setup_logging
	process_args "$@"
	check_root
	check_disk_space

	if [[ $AUTO == false ]]; then
		print_header
	fi

	get_username
	set_username
	get_host
	install
	show_summary
}

# Start the script
main "$@"
exit 0
