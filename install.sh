#!/usr/bin/env bash

# ==============================================================================
# NixOS Installation Script
# Author: kenanpelit
# Description: This script helps to setup a new NixOS installation with custom
#              configurations including home-manager setup.
#
# Usage: ./install.sh [options]
# Options:
#   -h, --help     Show this help message
#   -v, --version  Show script version
#   -s, --silent   Run in silent mode (no confirmations)
#   -d, --debug    Run in debug mode
# ==============================================================================

VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")
DEBUG=false
SILENT=false

# ==============================================================================
# Configuration Variables
# ==============================================================================
CURRENT_USERNAME='kenan'
CONFIG_DIR="$HOME/.config/nixos"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
BUILD_CORES=2 # Number of CPU cores to use during build

# ==============================================================================
# Color Definitions
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

# ==============================================================================
# Helper Functions
# ==============================================================================
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
}

print_help() {
  cat <<EOF
${BRIGHT}${GREEN}NixOS Installation Script${NORMAL}
This script helps you set up a new NixOS installation with custom configurations.

${BRIGHT}Usage:${NORMAL}
    $SCRIPT_NAME [options]

${BRIGHT}Options:${NORMAL}
    -h, --help     Show this help message
    -v, --version  Show script version
    -s, --silent   Run in silent mode (no confirmations)
    -d, --debug    Run in debug mode

${BRIGHT}Examples:${NORMAL}
    $SCRIPT_NAME              # Run normally with all confirmations
    $SCRIPT_NAME --silent     # Run without confirmations
    $SCRIPT_NAME --debug      # Run with debug information

${BRIGHT}Note:${NORMAL}
    This script should NOT be run as root!
EOF
}

print_version() {
  echo -e "${GREEN}NixOS Installation Script${NORMAL} version ${BLUE}$VERSION${NORMAL}"
}

print_header() {
  echo -E "$CYAN
 ═══════════════════════════════════════
   ██ ▄█▀▓█████  ███▄    █  ██▓███  
   ██▄█▒ ▓█   ▀  ██ ▀█   █ ▓██░  ██▒
   ▓███▄░ ▒███   ▓██  ▀█ ██▒▓██░ ██▓▒
   ▓██ █▄ ▒▓█  ▄ ▓██▒  ▐▌██▒▒██▄█▓▒ ▒
   ▒██▒ █▄░▒████▒▒██░   ▓██░▒██▒ ░  ░
   ▒ ▒▒ ▓▒░░ ▒░ ░░ ▒░   ▒ ▒ ▒▓▒░ ░  ░
   ░ ░▒ ▒░ ░ ░  ░░ ░░   ░ ▒░░▒ ░     
   ░ ░░ ░    ░      ░   ░ ░ ░░       
   ░  ░      ░  ░         ░          
 ═══════════════════════════════════════

 $BLUE https://github.com/kenanpelit$RED
 ! To make sure everything runs correctly DONT run as root !$GREEN
          → $SCRIPT_NAME $NORMAL
    "
}

confirm() {
  [[ $SILENT == true ]] && return 0

  echo -en "[${GREEN}y${NORMAL}/${RED}n${NORMAL}]: "
  read -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

check_root() {
  if [[ $EUID -eq 0 ]]; then
    log "ERROR" "This script should NOT be run as root!"
    exit 1
  fi
}

# ==============================================================================
# Core Functions
# ==============================================================================
get_username() {
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
  sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./flake.nix
  sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./modules/home/audacious.nix
  log "DEBUG" "Username updated in configuration files"
}

get_host() {
  log "INFO" "Selecting host type"
  echo -en "Choose a ${GREEN}host${NORMAL} - [${YELLOW}D${NORMAL}]esktop, [${YELLOW}L${NORMAL}]aptop or [${YELLOW}V${NORMAL}]irtual machine: "
  read -n 1 -r
  echo

  case ${REPLY,,} in
  d) HOST='desktop' ;;
  l) HOST='laptop' ;;
  v) HOST='vm' ;;
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

setup_directories() {
  log "INFO" "Creating required directories"
  local dirs=(
    "$HOME/Music"
    "$HOME/Documents"
    "$HOME/Pictures/wallpapers/others"
  )

  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    log "DEBUG" "Created directory: $dir"
  done
}

copy_wallpapers() {
  log "INFO" "Copying wallpapers"
  cp -r wallpapers/wallpaper.png "$WALLPAPER_DIR"
  cp -r wallpapers/otherWallpaper/gruvbox/* "$WALLPAPER_DIR/others/"
  cp -r wallpapers/otherWallpaper/nixos/* "$WALLPAPER_DIR/others/"
  log "DEBUG" "Wallpapers copied successfully"
}

copy_hardware_config() {
  log "INFO" "Copying hardware configuration"
  cp /etc/nixos/hardware-configuration.nix "hosts/${HOST}/hardware-configuration.nix"
  log "DEBUG" "Hardware configuration copied for host: $HOST"
}

build_system() {
  log "INFO" "Starting system build"
  echo -en "You are about to start the system build, do you want to proceed? "
  if confirm; then
    log "INFO" "Building the system..."
    if sudo nixos-rebuild switch --cores 4 --flake ".#${HOST}"; then
      log "INFO" "System built successfully"
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

# ==============================================================================
# Main Installation Process
# ==============================================================================
install() {
  setup_directories
  copy_wallpapers
  copy_hardware_config
  build_system
}

# ==============================================================================
# Command Line Arguments Processing
# ==============================================================================
process_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
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
    *)
      log "ERROR" "Unknown option: $1"
      print_help
      exit 1
      ;;
    esac
  done
}

# ==============================================================================
# Main Function
# ==============================================================================
main() {
  init_colors
  process_args "$@"
  check_root
  print_header
  get_username
  set_username
  get_host
  install
}

# Start the script
main "$@"
exit 0
