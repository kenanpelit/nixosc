#!/usr/bin/env bash
# =============================================================================
# Niri Universal Launcher - TTY & GDM Compatible
# =============================================================================
# Based on hyprland_tty.sh
# Optimized for Niri compositor + DankMaterialShell integration
# =============================================================================

set -euo pipefail

# =============================================================================
# Sabit Değişkenler
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0-niri"
readonly LOG_DIR="$HOME/.logs"
readonly NIRI_LOG="$LOG_DIR/niri.log"
readonly DEBUG_LOG="$LOG_DIR/niri_debug.log"
readonly MAX_LOG_SIZE=10485760 # 10MB
readonly MAX_LOG_BACKUPS=3

# Terminal renk kodları
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[1;33m'
readonly C_RED='\033[0;31m'
readonly C_CYAN='\033[0;36m'
readonly C_MAGENTA='\033[0;35m'
readonly C_RESET='\033[0m'

# Catppuccin flavor ve accent
CATPPUCCIN_FLAVOR="${CATPPUCCIN_FLAVOR:-mocha}"
CATPPUCCIN_ACCENT="${CATPPUCCIN_ACCENT:-mauve}"

# Mode flags
DEBUG_MODE=false
DRY_RUN=false
GDM_MODE=false
FORCE_TTY_MODE=false

# =============================================================================
# GDM Detection
# =============================================================================
detect_gdm_session() {
	if [[ "$FORCE_TTY_MODE" == "true" ]]; then
		GDM_MODE=false
		return 0
	fi

	if [[ -n "${GDMSESSION:-}" ]] ||
		[[ "${XDG_SESSION_CLASS:-}" == "user" ]] ||
		[[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" && -n "${XDG_SESSION_ID:-}" ]] ||
		[[ "$(loginctl show-session "$XDG_SESSION_ID" -p Type 2>/dev/null)" == *"wayland"* ]]; then
		GDM_MODE=true
	else
		GDM_MODE=false
	fi
}

# =============================================================================
# Logging Fonksiyonları
# =============================================================================
debug_log() {
	local message="$1"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local full_msg="[${timestamp}] [DEBUG] ${message}"

	if [[ "$DEBUG_MODE" != "true" ]]; then
		echo "$full_msg" >>"$DEBUG_LOG" 2>/dev/null || true
		return
	fi

	echo -e "${C_CYAN}[DEBUG]${C_RESET} $message" >&2
	echo "$full_msg" >>"$DEBUG_LOG" 2>/dev/null || true
}

log() {
	local level="$1"
	local message="$2"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local log_entry="[${timestamp}] [${level}] ${message}"

	if [[ -d "$(dirname "$NIRI_LOG")" ]]; then
		echo "$log_entry" >>"$NIRI_LOG" 2>/dev/null || true
	fi
	debug_log "$message"
}

info() {
	local message="$1"
	echo -e "${C_GREEN}[INFO]${C_RESET} $message"
	log "INFO" "$message"
}

warn() {
	local message="$1"
	echo -e "${C_YELLOW}[WARN]${C_RESET} $message" >&2
	log "WARN" "$message"
}

error() {
	local message="$1"
	echo -e "${C_RED}[ERROR]${C_RESET} $message" >&2
	log "ERROR" "$message"
	exit 1
}

print_header() {
	local text="$1"
	echo
	echo -e "${C_BLUE}╔════════════════════════════════════════════════════════════╗${C_RESET}"
	echo -e "${C_BLUE}║  ${C_GREEN}${text}${C_RESET}"
	echo -e "${C_BLUE}╚════════════════════════════════════════════════════════════╝${C_RESET}"
	echo
}

# =============================================================================
# Dizin ve Log Yönetimi
# =============================================================================
setup_directories() {
	if [[ "$GDM_MODE" == "true" ]]; then return 0; fi

	if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
		LOG_DIR="/tmp/niri-logs-$USER"
		NIRI_LOG="$LOG_DIR/niri.log"
		DEBUG_LOG="$LOG_DIR/niri_debug.log"
		mkdir -p "$LOG_DIR"
	fi
	touch "$NIRI_LOG" "$DEBUG_LOG"
}

rotate_logs() {
	if [[ "$GDM_MODE" == "true" ]] || [[ ! -f "$NIRI_LOG" ]]; then return 0; fi

	local file_size=$(stat -c%s "$NIRI_LOG" 2>/dev/null || echo 0)
	if [[ $file_size -gt $MAX_LOG_SIZE ]]; then
		mv "$NIRI_LOG" "${NIRI_LOG}.old.0"
		touch "$NIRI_LOG"
	fi
}

# =============================================================================
# Sistem Kontrolleri
# =============================================================================
check_system() {
	if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
	fi

	# Niri session binary kontrolü
	if command -v niri-session &>/dev/null; then
		NIRI_BINARY="niri-session"
	elif command -v niri &>/dev/null; then
		NIRI_BINARY="niri"
		warn "niri-session bulunamadı, direkt niri kullanılacak (systemd entegrasyonu eksik olabilir)"
	else
		error "niri veya niri-session bulunamadı!"
	fi
}

# =============================================================================
# Environment Setup
# =============================================================================
setup_environment() {
	print_header "ENVIRONMENT SETUP - NIRI"

	# CRITICAL FIX: Set SYSTEMD_OFFLINE=0
	export SYSTEMD_OFFLINE=0
	debug_log "✓ SYSTEMD_OFFLINE=0 set"

	# Wayland Settings
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="niri"
	export XDG_CURRENT_DESKTOP="niri"
	export DESKTOP_SESSION="niri"
	
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM="wayland;xcb"
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export CLUTTER_BACKEND=wayland
	export NIXOS_OZONE_WL=1
    export EGL_PLATFORM=wayland

	# Theme
	local gtk_theme="catppuccin-${CATPPUCCIN_FLAVOR}-${CATPPUCCIN_ACCENT}-standard+normal"
	export GTK_THEME="$gtk_theme"
	export GTK_USE_PORTAL=1
    export QT_QPA_PLATFORMTHEME=gtk3

	if [[ "$CATPPUCCIN_FLAVOR" == "latte" ]]; then
		export GTK_APPLICATION_PREFER_DARK_THEME=0
	else
		export GTK_APPLICATION_PREFER_DARK_THEME=1
	fi

	local cursor_theme="catppuccin-${CATPPUCCIN_FLAVOR}-dark-cursors"
	export XCURSOR_THEME="$cursor_theme"
	export XCURSOR_SIZE=24

	# Niri Specific
	export NIRI_CONFIG_HOME="$HOME/.config/niri"
    
    # Apps
    export EDITOR=nvim
    export VISUAL=nvim
    export TERMINAL=kitty
    export BROWSER=brave

	info "Environment setup tamamlandı"
}

# =============================================================================
# Systemd Integration
# =============================================================================
setup_systemd_integration() {
    # Import environment to systemd user session
    local vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP GTK_THEME XCURSOR_THEME SYSTEMD_OFFLINE NIXOS_OZONE_WL"
    
    systemctl --user import-environment $vars 2>/dev/null || true
    dbus-update-activation-environment --systemd --all 2>/dev/null || true
    
    # Restart critical user services for correct environment
    if [[ "$GDM_MODE" == "true" ]]; then
        systemctl --user restart dms.service 2>/dev/null || true
    fi
}

# =============================================================================
# Start Niri
# =============================================================================
start_niri() {
	print_header "NIRI BAŞLATILIYOR"
    
    if [[ "$GDM_MODE" == "true" ]]; then
        # GDM modunda exec (systemd journal logging)
        exec "$NIRI_BINARY" 2>&1 | systemd-cat -t niri-gdm
    else
        # TTY modunda exec (file logging)
        exec "$NIRI_BINARY" >>"$NIRI_LOG" 2>&1
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
	detect_gdm_session
    
    if [[ "$1" == "--dry-run" ]]; then DRY_RUN=true; fi
    if [[ "$1" == "--force-tty" ]]; then GDM_MODE=false; fi

	setup_directories
	rotate_logs
	check_system
	setup_environment
	setup_systemd_integration
	start_niri
}

main "${@:-}"
