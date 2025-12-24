#!/usr/bin/env bash
# ==============================================================================
# hypr-set - Hyprland session helper multiplexer (single-file)
# ==============================================================================
# This script intentionally embeds all Hyprland helper logic that used to live in
# separate scripts under `modules/home/scripts/bin/`.
#
# Usage:
#   hypr-set <subcommand> [args...]
#
# Commands:
#   tty                Start Hyprland from TTY/DM (was: hyprland_tty)
#   init               Session bootstrap (was: hypr-init)
#   workspace-monitor  Workspace/monitor helper (was: hypr-workspace-monitor)
#   switch             Smart monitor/workspace switcher (was: hypr-switch)
#   layout-toggle      Toggle layout preset (was: hypr-layout_toggle)
#   vlc-toggle         VLC helper (was: hypr-vlc_toggle)
#   wifi-power-save    WiFi power save helper (was: hypr-wifi-power-save)
#   airplane-mode      Airplane mode helper (was: hypr-airplane_mode)
#   colorpicker        Color picker helper (was: hypr-colorpicker)
#   start-batteryd     Battery daemon helper (was: hypr-start-batteryd)
# ==============================================================================

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  hypr-set <command> [args...]

Commands:
  tty                Start Hyprland from TTY/DM
  init               Session bootstrap
  workspace-monitor  Workspace/monitor helper
  switch             Smart monitor/workspace switcher
  layout-toggle      Toggle layout preset
  vlc-toggle         VLC helper
  wifi-power-save    WiFi power save helper
  airplane-mode      Airplane mode helper
  colorpicker        Color picker helper
  start-batteryd     Battery daemon helper
EOF
}

cmd="${1:-}"
shift || true

case "${cmd}" in
  ""|-h|--help|help)
    usage
    exit 0
    ;;
  tty)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hyprland_tty.sh
# ------------------------------------------------------------------------------

# =============================================================================
# Hyprland Universal Launcher - TTY & GDM Compatible
# =============================================================================
# ThinkPad E14 Gen 6 + Intel Arc Graphics + NixOS
# Dinamik Catppuccin tema desteği + GDM session awareness
# =============================================================================
# KULLANIM:
#   hyprland_tty              - Auto-detect (TTY/GDM) ve başlat
#   hyprland_tty -d           - Debug modu
#   hyprland_tty --dry-run    - Sadece kontroller, başlatma
#   hyprland_tty --force-tty  - GDM tespit edilse bile TTY modu zorla
# =============================================================================
# GDM vs TTY Farkları:
#   TTY Mode:
#     - Tam environment setup (systemd, D-Bus, theme, vs.)
#     - Log rotation ve cleanup
#     - Eski proses temizliği
#
#   GDM Mode:
#     - Minimal setup (GDM zaten yaptı)
#     - SADECE user service environment sync
#     - Aggressive import (Waybar fix)
# =============================================================================

set -euo pipefail

# =============================================================================
# Sabit Değişkenler
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="3.0.0-gdm-aware"
readonly LOG_DIR="$HOME/.logs"
readonly HYPRLAND_LOG="$LOG_DIR/hyprland.log"
readonly DEBUG_LOG="$LOG_DIR/hyprland_debug.log"
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

# Catppuccin flavor ve accent - Environment'tan oku veya varsayılan
CATPPUCCIN_FLAVOR="${CATPPUCCIN_FLAVOR:-mocha}"
CATPPUCCIN_ACCENT="${CATPPUCCIN_ACCENT:-mauve}"

# Mode flags
DEBUG_MODE=false
DRY_RUN=false
GDM_MODE=false
FORCE_TTY_MODE=false

# =============================================================================
# GDM Detection - Script Başlangıcında Otomatik
# =============================================================================
# GDM session indicators (multiple checks for reliability):
#   1. GDMSESSION environment variable (set by GDM)
#   2. XDG_SESSION_CLASS=user (GDM sets this)
#   3. DBUS_SESSION_BUS_ADDRESS already set (GDM provides D-Bus)
#   4. Systemd user session already active (GDM starts it)

detect_gdm_session() {
	if [[ "$FORCE_TTY_MODE" == "true" ]]; then
		GDM_MODE=false
		return 0
	fi

	# More aggressive GDM detection
	if [[ -n "${GDMSESSION:-}" ]] ||
		[[ "${XDG_SESSION_CLASS:-}" == "user" ]] ||
		[[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" && -n "${XDG_SESSION_ID:-}" ]] ||
		[[ "$(loginctl show-session "$XDG_SESSION_ID" -p Type 2>/dev/null)" == *"wayland"* ]]; then
		GDM_MODE=true
	else
		GDM_MODE=false
	fi

	# Log detection result
	debug_log "GDM Detection: GDM_MODE=$GDM_MODE"
	debug_log "  GDMSESSION=${GDMSESSION:-unset}"
	debug_log "  XDG_SESSION_CLASS=${XDG_SESSION_CLASS:-unset}"
	debug_log "  DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:+set}"
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

	if [[ "$(tty 2>/dev/null)" =~ ^/dev/tty[0-9]+$ ]]; then
		logger -t "$SCRIPT_NAME" "DEBUG: $message" 2>/dev/null || true
	fi
}

log() {
	local level="$1"
	local message="$2"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local log_entry="[${timestamp}] [${level}] ${message}"

	if [[ -d "$(dirname "$HYPRLAND_LOG")" ]]; then
		echo "$log_entry" >>"$HYPRLAND_LOG" 2>/dev/null || true
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
	debug_log "FATAL ERROR - Script sonlandırılıyor: $message"
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

print_mode_banner() {
	if [[ "$GDM_MODE" == "true" ]]; then
		echo -e "${C_MAGENTA}╔════════════════════════════════════════════════════════════╗${C_RESET}"
		echo -e "${C_MAGENTA}║  MODE: GDM Session (Simplified Startup)                    ║${C_RESET}"
		echo -e "${C_MAGENTA}╚════════════════════════════════════════════════════════════╝${C_RESET}"
		info "GDM session tespit edildi - minimal setup modu"
	else
		echo -e "${C_CYAN}╔════════════════════════════════════════════════════════════╗${C_RESET}"
		echo -e "${C_CYAN}║  MODE: TTY Direct Launch (Full Setup)                      ║${C_RESET}"
		echo -e "${C_CYAN}╚════════════════════════════════════════════════════════════╝${C_RESET}"
		info "TTY direct launch - tam setup modu"
	fi
}

# =============================================================================
# Dizin ve Log Yönetimi (Sadece TTY Modu)
# =============================================================================

setup_directories() {
	# GDM modunda log setup atla (GDM zaten journal'a yönlendiriyor)
	if [[ "$GDM_MODE" == "true" ]]; then
		debug_log "GDM mode: Log setup atlandı (systemd journal kullanılıyor)"
		return 0
	fi

	debug_log "setup_directories başlatılıyor"

	if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
		warn "Log dizini oluşturulamadı: $LOG_DIR, /tmp kullanılıyor"
		LOG_DIR="/tmp/hyprland-logs-$USER"
		HYPRLAND_LOG="$LOG_DIR/hyprland.log"
		DEBUG_LOG="$LOG_DIR/hyprland_debug.log"
		mkdir -p "$LOG_DIR" || error "Hiçbir log dizini oluşturulamadı"
	fi

	if [[ ! -w "$LOG_DIR" ]]; then
		error "Log dizinine yazma izni yok: $LOG_DIR"
	fi

	touch "$HYPRLAND_LOG" "$DEBUG_LOG" 2>/dev/null || {
		error "Log dosyaları oluşturulamadı"
	}

	debug_log "Log dizini hazır: $LOG_DIR"
}

rotate_logs() {
	# GDM modunda log rotation atla
	if [[ "$GDM_MODE" == "true" ]]; then
		return 0
	fi

	debug_log "Log rotasyonu kontrol ediliyor"

	if [[ ! -f "$HYPRLAND_LOG" ]]; then
		return 0
	fi

	local file_size=$(stat -c%s "$HYPRLAND_LOG" 2>/dev/null || echo 0)
	debug_log "Ana log dosyası boyutu: $file_size bytes"

	if [[ $file_size -gt $MAX_LOG_SIZE ]]; then
		info "Log dosyası ${MAX_LOG_SIZE} byte'ı aştı, rotasyon yapılıyor"

		for ((i = $MAX_LOG_BACKUPS; i > 0; i--)); do
			local old_backup="${HYPRLAND_LOG}.old.$((i - 1))"
			local new_backup="${HYPRLAND_LOG}.old.$i"

			if [[ -f "$old_backup" ]]; then
				if [[ $i -eq $MAX_LOG_BACKUPS ]]; then
					rm -f "$old_backup"
				else
					mv "$old_backup" "$new_backup"
				fi
			fi
		done

		mv "$HYPRLAND_LOG" "${HYPRLAND_LOG}.old.0"
		touch "$HYPRLAND_LOG"
	fi
}

# =============================================================================
# Sistem Kontrolleri
# =============================================================================

check_system() {
	debug_log "Sistem kontrolleri başlıyor"

	# XDG_RUNTIME_DIR (GDM zaten set etmiş olmalı, ama kontrol et)
	if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
		if [[ "$GDM_MODE" == "true" ]]; then
			warn "GDM mode ama XDG_RUNTIME_DIR yok! Ayarlandı: $XDG_RUNTIME_DIR"
		fi
	else
		debug_log "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
	fi

	if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
		error "XDG_RUNTIME_DIR dizini mevcut değil: $XDG_RUNTIME_DIR"
	fi

	if [[ ! -w "$XDG_RUNTIME_DIR" ]]; then
		error "XDG_RUNTIME_DIR yazılabilir değil: $XDG_RUNTIME_DIR"
	fi

	# TTY kontrolü (sadece TTY modunda önemli)
	if [[ -z "${XDG_VTNR:-}" && "$GDM_MODE" == "false" ]]; then
		export XDG_VTNR=1
		warn "XDG_VTNR varsayılan değere ayarlandı: 1"
	fi

	# Intel Arc Graphics kontrolü ve optimizasyonları
	if lspci 2>/dev/null | grep -qi "arc\|meteor\|alchemist"; then
		info "Intel Arc Graphics tespit edildi"

		export WLR_DRM_NO_ATOMIC=1
		export WLR_RENDERER=gles2
		export INTEL_DEBUG=norbc
		export LIBVA_DRIVER_NAME=iHD
		export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json

		info "Intel Arc optimizasyonları aktif"
	fi

	# Hyprland binary kontrolü (yeni launcher)
	if command -v start-hyprland &>/dev/null; then
		HYPRLAND_BINARY="start-hyprland"
	else
		error "start-hyprland bulunamadı! PATH: $PATH"
	fi

	local hypr_version=$("$HYPRLAND_BINARY" --version 2>&1 | head -n1 || echo "Unknown")
	info "Hyprland launcher version: $hypr_version"

	info "Sistem kontrolleri tamamlandı"
}

# =============================================================================
# Environment Setup - GDM-Aware
# =============================================================================

setup_environment() {
	print_header "ENVIRONMENT SETUP - ${CATPPUCCIN_FLAVOR^^} ($([ "$GDM_MODE" == "true" ] && echo "GDM" || echo "TTY"))"
	debug_log "Environment değişkenleri ayarlanıyor (GDM_MODE=$GDM_MODE)"

	# =========================================================================
	# CRITICAL FIX: Set SYSTEMD_OFFLINE=0 for proper systemd user session
	# =========================================================================
	# Setting SYSTEMD_OFFLINE=0 (not unsetting!) ensures systemd user services
	# start immediately without delays. This is critical for:
	# - Waybar and other user services to start properly
	# - Session to launch without slowdown
	# - GDM compatibility when launched via display manager
	export SYSTEMD_OFFLINE=0
	debug_log "✓ SYSTEMD_OFFLINE=0 set - systemd user services enabled"

	# -------------------------------------------------------------------------
	# Temel Wayland Ayarları
	# -------------------------------------------------------------------------
	# GDM modunda bazıları zaten set edilmiş olabilir, ama override et
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"
	export DESKTOP_SESSION="Hyprland"
	debug_log "Wayland session: $XDG_CURRENT_DESKTOP"

	# -------------------------------------------------------------------------
	# Wayland Backend Tercihleri (Her iki modda da gerekli)
	# -------------------------------------------------------------------------
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM="wayland;xcb"
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export CLUTTER_BACKEND=wayland
	export NIXOS_OZONE_WL=1
	export _JAVA_AWT_WM_NONREPARENTING=1

	# -------------------------------------------------------------------------
	# Catppuccin Tema
	# -------------------------------------------------------------------------
	local gtk_theme="catppuccin-${CATPPUCCIN_FLAVOR}-${CATPPUCCIN_ACCENT}-standard+normal"
	export GTK_THEME="$gtk_theme"
	export GTK_USE_PORTAL=1

	if [[ "$CATPPUCCIN_FLAVOR" == "latte" ]]; then
		export GTK_APPLICATION_PREFER_DARK_THEME=0
	else
		export GTK_APPLICATION_PREFER_DARK_THEME=1
	fi

	info "GTK Theme: $gtk_theme"

	local cursor_theme="catppuccin-${CATPPUCCIN_FLAVOR}-dark-cursors"
	export XCURSOR_THEME="$cursor_theme"
	export XCURSOR_SIZE=24
	info "Cursor Theme: $cursor_theme"

	# -------------------------------------------------------------------------
	# Qt Tema
	# -------------------------------------------------------------------------
	export QT_QPA_PLATFORMTHEME=gtk3
	export QT_STYLE_OVERRIDE=kvantum
	export QT_AUTO_SCREEN_SCALE_FACTOR=1

	# -------------------------------------------------------------------------
	# Klavye (Sadece TTY modunda - GDM zaten ayarladı)
	# -------------------------------------------------------------------------
	if [[ "$GDM_MODE" == "false" ]]; then
		export XKB_DEFAULT_LAYOUT=tr
		export XKB_DEFAULT_VARIANT=f
		export XKB_DEFAULT_OPTIONS=ctrl:nocaps
		debug_log "Klavye: Türkçe F"
	fi

	# -------------------------------------------------------------------------
	# Hyprland Daemon Ayarları
	# -------------------------------------------------------------------------
	export HYPRLAND_LOG_WLR=1
	export HYPRLAND_NO_RT=1
	export HYPRLAND_NO_SD_NOTIFY=1
	export WLR_LOG=INFO

	# -------------------------------------------------------------------------
	# Varsayılan Uygulamalar
	# -------------------------------------------------------------------------
	export EDITOR=nvim
	export VISUAL=nvim
	export TERMINAL=kitty
	export TERM=xterm-256color
	export BROWSER=brave

	# -------------------------------------------------------------------------
	# Font Rendering
	# -------------------------------------------------------------------------
	export FREETYPE_PROPERTIES="truetype:interpreter-version=40"
	if [[ -f /etc/fonts/fonts.conf ]]; then
		export FONTCONFIG_FILE=/etc/fonts/fonts.conf
	fi

	# -------------------------------------------------------------------------
	# Catppuccin Metadata
	# -------------------------------------------------------------------------
	export CATPPUCCIN_FLAVOR="$CATPPUCCIN_FLAVOR"
	export CATPPUCCIN_ACCENT="$CATPPUCCIN_ACCENT"

	info "Environment setup tamamlandı"
}

# =============================================================================
# Eski Prosesleri Temizleme (Sadece TTY Modu)
# =============================================================================

cleanup_old_processes() {
	# GDM modunda eski proses temizliği yapma (GDM manage eder)
	if [[ "$GDM_MODE" == "true" ]]; then
		debug_log "GDM mode: Eski proses temizliği atlandı"
		return 0
	fi

	debug_log "Eski Hyprland prosesleri kontrol ediliyor"

	local old_pids=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)

	if [[ -z "$old_pids" ]]; then
		debug_log "Eski Hyprland prosesi bulunamadı"
		return 0
	fi

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Eski prosesler sonlandırılmayacak"
		return 0
	fi

	warn "Eski Hyprland prosesleri tespit edildi: $old_pids"
	info "Eski prosesler zarif şekilde sonlandırılıyor..."

	echo "$old_pids" | xargs -r kill -TERM 2>/dev/null || true
	sleep 2

	local remaining_pids=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)
	if [[ -n "$remaining_pids" ]]; then
		warn "Bazı prosesler hala aktif, zorla sonlandırılıyor..."
		echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
		sleep 1
	fi

	debug_log "Eski prosesler temizlendi"
}

# =============================================================================
# Systemd ve DBus Entegrasyonu - GDM-AWARE (CRITICAL!)
# =============================================================================

setup_systemd_integration() {
	print_header "SYSTEMD/DBUS ENTEGRASYONU"
	debug_log "Systemd entegrasyonu başlatılıyor (GDM_MODE=$GDM_MODE)"

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Systemd entegrasyonu atlanıyor"
		return 0
	fi

	# CRITICAL: Check if systemd user session is running
	if ! systemctl --user is-system-running &>/dev/null; then
		warn "Systemd user session çalışmıyor!"

		# Try to start it
		if systemctl --user start default.target 2>/dev/null; then
			info "✓ Systemd user session başlatıldı"
			sleep 2 # Wait for services to initialize
		else
			error "Systemd user session başlatılamadı! User services çalışmayacak."
		fi
	else
		debug_log "Systemd user session zaten çalışıyor"
	fi

	# -------------------------------------------------------------------------
	# GDM MODE: Aggressive Environment Sync (Waybar Fix!)
	# -------------------------------------------------------------------------
	# GDM session'ında user services (Waybar, Mako, vs.) zaten başlamış durumda
	# ANCAK yanlış environment ile başlamış olabilirler!
	# Bu yüzden AGGRESSIVE sync + service restart gerekli

	if [[ "$GDM_MODE" == "true" ]]; then
		info "GDM Mode: Aggressive environment sync başlatılıyor..."

		# FULL environment import - Waybar için CRITICAL
		local full_vars=(
			"WAYLAND_DISPLAY"
			"XDG_CURRENT_DESKTOP"
			"XDG_SESSION_TYPE"
			"XDG_SESSION_DESKTOP"
			"GTK_THEME"
			"XCURSOR_THEME"
			"XCURSOR_SIZE"
			"CATPPUCCIN_FLAVOR"
			"CATPPUCCIN_ACCENT"
			"QT_QPA_PLATFORM"
			"MOZ_ENABLE_WAYLAND"
			"NIXOS_OZONE_WL"
			"LIBVA_DRIVER_NAME"
			"VK_ICD_FILENAMES"
		)

		if systemctl --user import-environment "${full_vars[@]}" 2>/dev/null; then
			info "✓ Systemd user environment güncellendi (${#full_vars[@]} variables)"
		else
			warn "Systemd import kısmen başarısız"
		fi

		# D-Bus activation environment - FULL sync
		if dbus-update-activation-environment --systemd --all 2>/dev/null; then
			info "✓ D-Bus activation environment güncellendi (--all)"
		else
			warn "D-Bus update başarısız"
		fi

		# CRITICAL: User services'i restart et (yeni environment ile başlasın)
		# Waybar en önemli, ama diğerleri de restart edilebilir
		info "User services restart ediliyor (yeni environment için)..."

		local services_to_restart=(
			"waybar.service"
			"mako.service"
			"hypridle.service"
		)

		sleep 2

		for svc in "${services_to_restart[@]}"; do
			if systemctl --user is-active "$svc" &>/dev/null; then
				debug_log "Restarting: $svc"
				systemctl --user restart "$svc" 2>/dev/null || true
			fi
		done

		info "✓ GDM aggressive sync tamamlandı"

	# -------------------------------------------------------------------------
	# TTY MODE: Standard Sync
	# -------------------------------------------------------------------------
	else
		info "TTY Mode: Standard environment sync..."

		local std_vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"

		if systemctl --user import-environment $std_vars 2>/dev/null; then
			debug_log "Systemd environment import başarılı"
		else
			warn "Systemd import başarısız (systemd user session yok olabilir)"
		fi

		local dbus_vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE"

		if dbus-update-activation-environment --systemd $dbus_vars 2>/dev/null; then
			debug_log "DBus activation environment güncellendi"
		else
			warn "DBus update başarısız"
		fi

		info "✓ TTY standard sync tamamlandı"
	fi
}

# =============================================================================
# Cleanup Trap (Sadece TTY Modu)
# =============================================================================

cleanup() {
	# GDM modunda cleanup yapma (GDM handle eder)
	if [[ "$GDM_MODE" == "true" ]]; then
		return 0
	fi

	debug_log "Cleanup fonksiyonu tetiklendi"
	info "Hyprland oturumu sonlandırılıyor..."

	local hypr_pids=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)

	if [[ -n "$hypr_pids" ]]; then
		echo "$hypr_pids" | xargs -r kill -TERM 2>/dev/null || true
		sleep 2

		local remaining=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)
		if [[ -n "$remaining" ]]; then
			echo "$remaining" | xargs -r kill -KILL 2>/dev/null || true
		fi
	fi

	debug_log "Cleanup tamamlandı"
}

# =============================================================================
# Hyprland Başlatma
# =============================================================================

start_hyprland() {
	print_header "HYPRLAND BAŞLATILIYOR"
	debug_log "Hyprland başlatma fonksiyonu çağrıldı"

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Hyprland başlatılmayacak"
		info "[DRY-RUN] Tüm kontroller başarılı!"
		exit 0
	fi

	# Cleanup trap (sadece TTY modunda)
	if [[ "$GDM_MODE" == "false" ]]; then
		trap cleanup EXIT TERM INT HUP
		debug_log "Signal trap'leri ayarlandı"
	fi

	# Son kontroller
	debug_log "Son kontroller:"
	debug_log "  HYPRLAND_BINARY: $HYPRLAND_BINARY"
	debug_log "  GDM_MODE: $GDM_MODE"
	debug_log "  Environment: $XDG_CURRENT_DESKTOP"
	debug_log "  Theme: $GTK_THEME"
	debug_log "  Cursor: $XCURSOR_THEME"

	# Bilgilendirme
	info "═══════════════════════════════════════════════════════════"
	info "Hyprland başlatılıyor..."
	info "Mode: $([ "$GDM_MODE" == "true" ] && echo "GDM Session" || echo "TTY Direct")"
	info "Binary: $HYPRLAND_BINARY"
	info "Theme: $CATPPUCCIN_FLAVOR-$CATPPUCCIN_ACCENT"
	if [[ "$GDM_MODE" == "false" ]]; then
		info "Log: $HYPRLAND_LOG"
	fi
	info "═══════════════════════════════════════════════════════════"

	debug_log "exec $HYPRLAND_BINARY komutu çalıştırılıyor"

	# GDM modunda systemd journal'a yönlendir, TTY modunda log file'a
	if [[ "$GDM_MODE" == "true" ]]; then
		exec "$HYPRLAND_BINARY" 2>&1 | systemd-cat -t hyprland-gdm
	else
		exec "$HYPRLAND_BINARY" >>"$HYPRLAND_LOG" 2>&1
	fi

	# Bu satıra hiç ulaşılmamalı
	error "Hyprland exec başarısız oldu!"
}

# =============================================================================
# Yardım Mesajı
# =============================================================================

show_help() {
	cat <<EOF
╔════════════════════════════════════════════════════════════╗
║  Hyprland Universal Launcher v${SCRIPT_VERSION}            ║
║  TTY & GDM Compatible                                      ║
╚════════════════════════════════════════════════════════════╝

KULLANIM:
  $SCRIPT_NAME [SEÇENEKLER]

SEÇENEKLER:
  -h, --help       Bu yardım mesajını göster
  -d, --debug      Debug modu (detaylı log)
  --dry-run        Sadece kontroller, başlatma yapma
  --force-tty      GDM tespit edilse bile TTY modu zorla
  -v, --version    Version bilgisini göster

ÖRNEKLER:
  $SCRIPT_NAME              # Auto-detect (TTY/GDM)
  $SCRIPT_NAME -d           # Debug modu
  $SCRIPT_NAME --dry-run    # Sadece test et
  $SCRIPT_NAME --force-tty  # TTY modu zorla

GDM vs TTY MODU:
  GDM Mode (Auto-detected):
    • Minimal setup (GDM zaten hazırladı)
    • Aggressive environment sync (Waybar fix)
    • User service restart
    • systemd journal logging

  TTY Mode:
    • Full setup (environment, systemd, D-Bus)
    • Log rotation ve cleanup
    • Eski proses temizliği
    • File logging

CATPPUCCIN TEMA:
  Flavor: $CATPPUCCIN_FLAVOR (CATPPUCCIN_FLAVOR env var)
  Accent: $CATPPUCCIN_ACCENT (CATPPUCCIN_ACCENT env var)

  Flavors: latte, frappe, macchiato, mocha
  Accents: rosewater, flamingo, pink, mauve, red, maroon,
           peach, yellow, green, teal, sky, sapphire, blue, lavender

LOG DOSYALARI (TTY Mode):
  Ana log:   $HYPRLAND_LOG
  Debug log: $DEBUG_LOG

NOTLAR:
  - Intel Arc Graphics auto-detected ve optimize edilir
  - GDM session otomatik tespit edilir
  - User services (Waybar) aggressive sync ile düzeltilir

EOF
}

# =============================================================================
# Argüman İşleme
# =============================================================================

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_help
			exit 0
			;;
		-d | --debug)
			DEBUG_MODE=true
			info "Debug modu aktif"
			shift
			;;
		--dry-run)
			DRY_RUN=true
			info "Dry-run modu aktif"
			shift
			;;
		--force-tty)
			FORCE_TTY_MODE=true
			info "Force TTY mode aktif"
			shift
			;;
		-v | --version)
			echo "$SCRIPT_NAME version $SCRIPT_VERSION"
			exit 0
			;;
		*)
			error "Bilinmeyen argüman: $1 (--help ile yardım)"
			;;
		esac
	done
}

# =============================================================================
# Ana Fonksiyon
# =============================================================================

main() {
	# Argümanları işle
	parse_arguments "$@"

	# GDM detection (en başta!)
	detect_gdm_session

	# Debug başlangıç
	debug_log "════════════════════════════════════════════════════════"
	debug_log "Script başlatıldı: $(date)"
	debug_log "Version: $SCRIPT_VERSION"
	debug_log "User: $USER | TTY: $(tty 2>/dev/null || echo 'N/A')"
	debug_log "GDM_MODE: $GDM_MODE | DEBUG: $DEBUG_MODE | DRY_RUN: $DRY_RUN"
	debug_log "GDMSESSION: ${GDMSESSION:-unset}"
	debug_log "XDG_SESSION_CLASS: ${XDG_SESSION_CLASS:-unset}"
	debug_log "DBUS_SESSION_BUS_ADDRESS: ${DBUS_SESSION_BUS_ADDRESS:-unset}"
	debug_log "════════════════════════════════════════════════════════"

	# Bash debug modu
	if [[ "$DEBUG_MODE" == "true" ]]; then
		set -x
	fi

	# Başlık
	print_header "HYPRLAND UNIVERSAL LAUNCHER - ThinkPad E14 Gen 6"
	info "Version: $SCRIPT_VERSION"
	info "Launch Time: $(date '+%Y-%m-%d %H:%M:%S')"
	info "User: $USER | TTY: $(tty 2>/dev/null || echo 'N/A')"
	info "Theme: $CATPPUCCIN_FLAVOR-$CATPPUCCIN_ACCENT"
	echo

	# Mode banner
	print_mode_banner
	echo

	# Ana işlem akışı - sırayla
	setup_directories         # TTY: log setup, GDM: skip
	rotate_logs               # TTY: rotate, GDM: skip
	check_system              # Her iki mod: sistem kontrolleri
	setup_environment         # Her iki mod: environment variables
	cleanup_old_processes     # TTY: cleanup, GDM: skip
	setup_systemd_integration # TTY: standard, GDM: AGGRESSIVE
	start_hyprland            # Her iki mod: Hyprland başlat

	# Bu satıra hiç ulaşılmamalı
	error "Ana fonksiyon beklenmedik şekilde sonlandı!"
}

# =============================================================================
# Script Başlangıcı
# =============================================================================

main "$@"
    )
    ;;
  init)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-init.sh
# ------------------------------------------------------------------------------

# ==============================================================================
# hypr-init - Session bootstrap for Hyprland (monitors + audio)
# ------------------------------------------------------------------------------
# Runs early in the Hyprland session to:
#   1) Normalize monitor/workspace focus via hypr-switch
#   2) Initialize PipeWire defaults via osc-soundctl init
# Safe to run multiple times; each step is optional if the tool is missing.
# ==============================================================================

set -euo pipefail

LOG_TAG="hypr-init"
log() { printf '[%s] %s\n' "$LOG_TAG" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$LOG_TAG" "$*" >&2; }

run_if_present() {
  local cmd="$1"; shift
  if command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" "$@" && log "$cmd $*"
  else
    warn "$cmd not found; skipping"
  fi
}

# Ensure we are in a Hyprland session (best-effort)
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  warn "HYPRLAND_INSTANCE_SIGNATURE is unset; continuing anyway"
fi

# Step 1: monitor/workspace normalization
run_if_present hypr-set switch

# Step 2: audio defaults (volume + last sink/source)
run_if_present osc-soundctl init

log "hypr-init completed."
    )
    ;;
  workspace-monitor)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-workspace-monitor.sh
# ------------------------------------------------------------------------------

# hypr-workspace-monitor.sh - Hyprland workspace/monitor eşleştirici
# Çalışma alanlarını belirli monitörlere sabitleyip odak/taşıma işlemlerini yönetir.

#######################################
# HYPRFLOW - UNIFIED HYPRLAND CONTROL
#######################################
#
# Version: 2.0.0
# Date: 2025-11-04
# Original Authors: Kenan Pelit & Contributors
# Enhanced Unified Version
# Description: Complete Hyprland control suite combining workspace, monitor, and window management
#
# License: MIT
#
#######################################

# This unified script provides comprehensive control for the Hyprland window manager:
# - Monitor switching and focus control
# - Workspace navigation and management
# - Window focus and cycling
# - Browser tab navigation
# - Window movement between workspaces
# - Interactive app selection and movement
# - Quick workspace jumping
#
# Requirements:
#   - hyprctl: Hyprland control tool
#   - jq: JSON processing tool
#   - Optional: pypr, rofi/wofi/fuzzel, wtype/ydotool, notify-send
#
# Note:
#   - Script uses $HOME/.cache/hypr/toggle directory
#   - Directory will be created automatically if it doesn't exist
#   - Hyprland gestures must be turned off for some operations

# Enable strict mode
set -euo pipefail

# Ensure runtime metadata for non-login invocations (e.g., from services)
: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
	# Grab the first available Hyprland instance if none exported
	if first_sig=$(ls "$XDG_RUNTIME_DIR"/hypr 2>/dev/null | head -n1); then
		export HYPRLAND_INSTANCE_SIGNATURE="$first_sig"
	fi
fi

# Ensure common Nix profiles are in PATH so dependencies resolve when invoked from minimal services
PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER}/bin:${PATH}"

#######################################
# CONFIGURATION & CONSTANTS
#######################################

readonly VERSION="2.0.0"
readonly CACHE_DIR="$HOME/.cache/hypr/toggle"
readonly STATE_FILE="$CACHE_DIR/focus_state"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
readonly DEBUG_FILE="$CACHE_DIR/debug.log"
readonly NOTIFICATION_TIMEOUT=3000
readonly SCRIPT_NAME="HyprFlow"
readonly MAX_WORKSPACE=20

# Terminal colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Default values
debug=false
silent=false

#######################################
# INITIALIZATION
#######################################

init_environment() {
	# Create cache directory
	mkdir -p "$CACHE_DIR"

	# Create state file with default value if it doesn't exist
	if [ ! -f "$STATE_FILE" ]; then
		echo "up" >"$STATE_FILE"
	fi

	# Initialize workspace tracking files
	init_workspace_files
}

init_workspace_files() {
	local current_ws
	current_ws=$(get_current_workspace 2>/dev/null || echo "1")

	if [ ! -f "$CURRENT_WS_FILE" ]; then
		safe_write_file "$CURRENT_WS_FILE" "$current_ws"
	fi

	if [ ! -f "$PREVIOUS_WS_FILE" ]; then
		safe_write_file "$PREVIOUS_WS_FILE" "1"
	fi
}

#######################################
# LOGGING FUNCTIONS
#######################################

log() {
	local msg="$1"
	local level="${2:-INFO}"
	local color=""

	case "$level" in
	ERROR) color=$RED ;;
	SUCCESS) color=$GREEN ;;
	WARNING) color=$YELLOW ;;
	INFO) color=$BLUE ;;
	DEBUG) color=$CYAN ;;
	esac

	local timestamp
	timestamp=$(date '+%H:%M:%S')

	echo -e "${color}[${timestamp}] [$level] $msg${NC}" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >>"$DEBUG_FILE"
}

log_info() {
	log "$1" "INFO"
}

log_error() {
	log "$1" "ERROR"
}

log_success() {
	log "$1" "SUCCESS"
}

log_warning() {
	log "$1" "WARNING"
}

log_debug() {
	if $debug; then
		log "$1" "DEBUG"
	fi
}

notify() {
	local title="$1"
	local message="$2"
	local urgency="${3:-normal}"

	if [ "$silent" = false ] && command -v notify-send >/dev/null 2>&1; then
		notify-send -u "$urgency" -t "$NOTIFICATION_TIMEOUT" "$title" "$message"
	fi
}

#######################################
# VALIDATION FUNCTIONS
#######################################

validate_workspace() {
	local ws=$1
	if ! [[ "$ws" =~ ^[0-9]+$ ]]; then
		log_error "Invalid workspace number: $ws (must be a positive integer)"
		return 1
	fi
	if [ "$ws" -lt 1 ] || [ "$ws" -gt "$MAX_WORKSPACE" ]; then
		log_error "Workspace number out of range: $ws (valid range: 1-${MAX_WORKSPACE})"
		return 1
	fi
	return 0
}

validate_dependencies() {
	local required_deps=("hyprctl" "jq")
	local optional_deps=("pypr" "rofi" "wofi" "fuzzel" "wtype" "ydotool" "notify-send")
	local missing_required=()
	local missing_optional=()

	# Check required dependencies
	for dep in "${required_deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_required+=("$dep")
		fi
	done

	if [ ${#missing_required[@]} -gt 0 ]; then
		log_error "Missing required dependencies: ${missing_required[*]}"
		log_error "Please install the missing dependencies and try again"
		exit 1
	fi

	# Check optional dependencies
	for dep in "${optional_deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_optional+=("$dep")
		fi
	done

	if [ ${#missing_optional[@]} -gt 0 ]; then
		log_debug "Optional dependencies not found: ${missing_optional[*]}"
		log_debug "Some features may be limited"
	fi
}

#######################################
# SAFE FILE OPERATIONS
#######################################

safe_read_file() {
	local file=$1
	local default=${2:-"1"}

	if [ -f "$file" ] && [ -r "$file" ]; then
		local content
		content=$(cat "$file" 2>/dev/null | head -1 | tr -d '\n\r')
		if [[ "$content" =~ ^[0-9]+$ ]] && [ "$content" -ge 1 ] && [ "$content" -le "$MAX_WORKSPACE" ]; then
			echo "$content"
		else
			log_debug "Invalid content in $file: '$content', using default: $default"
			echo "$default"
		fi
	else
		log_debug "File $file not readable, using default: $default"
		echo "$default"
	fi
}

safe_write_file() {
	local file=$1
	local content=$2

	if validate_workspace "$content"; then
		echo "$content" >"$file" 2>/dev/null || log_error "Failed to write to $file"
	else
		log_error "Attempted to write invalid workspace number: $content"
	fi
}

#######################################
# WORKSPACE QUERY FUNCTIONS
#######################################

get_current_workspace() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.name'
}

get_previous_workspace() {
	safe_read_file "$PREVIOUS_WS_FILE" "1"
}

get_current_monitor() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true).name'
}

get_all_monitors() {
	hyprctl monitors -j | jq -r '.[].name'
}

get_workspaces_for_monitor() {
	local monitor=$1
	hyprctl workspaces -j | jq -r ".[] | select(.monitor==\"$monitor\") | select(.name!=\"special\") | .name" | sort -n
}

get_all_workspaces() {
	hyprctl workspaces -j | jq -r '.[] | select(.name!="special") | .name' | sort -n
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

get_focused_window() {
	hyprctl activewindow -j | jq -r '.address'
}

format_app_info() {
	local address="$1"
	hyprctl clients -j | jq -r --arg addr "$address" \
		'.[] | select(.address == $addr) | 
		"\(.class) - \(.title[0:50])"' 2>/dev/null || echo "Application"
}

#######################################
# WORKSPACE MANAGEMENT
#######################################

update_workspace_history() {
	local new_ws
	new_ws=$(get_current_workspace)

	if ! validate_workspace "$new_ws"; then
		log_error "Current workspace validation failed: $new_ws"
		return 1
	fi

	log_debug "Updating workspace history. New workspace: $new_ws"

	local old_ws
	old_ws=$(safe_read_file "$CURRENT_WS_FILE" "1")
	log_debug "Current workspace from file: $old_ws"

	if [ "$new_ws" != "$old_ws" ]; then
		safe_write_file "$PREVIOUS_WS_FILE" "$old_ws"
		log_debug "Updated previous workspace to: $old_ws"
	fi

	safe_write_file "$CURRENT_WS_FILE" "$new_ws"
	log_debug "Updated current workspace to: $new_ws"
}

switch_to_workspace() {
	local next_ws=$1

	if ! validate_workspace "$next_ws"; then
		log_error "Cannot switch to invalid workspace: $next_ws"
		return 1
	fi

	local current_ws
	current_ws=$(get_current_workspace)
	log_debug "Switching from workspace $current_ws to $next_ws"

	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"
	hyprctl dispatch workspace name:$next_ws
	safe_write_file "$CURRENT_WS_FILE" "$next_ws"

	log_debug "Switch complete. Previous workspace set to $current_ws"
}

switch_workspace_direction() {
	local direction=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Switching workspace direction: $direction from current $current_ws"
	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

	case $direction in
	"left" | "Left" | "-1")
		hyprctl dispatch workspace m-1
		;;
	"right" | "Right" | "+1")
		hyprctl dispatch workspace m+1
		;;
	esac

	local new_ws
	new_ws=$(get_current_workspace)
	safe_write_file "$CURRENT_WS_FILE" "$new_ws"

	log_debug "Switch direction complete. New workspace: $new_ws"
}

clear_workspace_history() {
	log_info "Clearing workspace history files"
	rm -f "$CURRENT_WS_FILE" "$PREVIOUS_WS_FILE"

	local current_ws
	current_ws=$(get_current_workspace 2>/dev/null || echo "1")
	safe_write_file "$CURRENT_WS_FILE" "$current_ws"
	safe_write_file "$PREVIOUS_WS_FILE" "1"

	log_info "Workspace history files reset"
}

#######################################
# WINDOW MANAGEMENT
#######################################

move_window() {
	local target_workspace="$1"
	local app_address="$2"
	local focus="${3:-false}"

	if ! hyprctl dispatch movetoworkspace "$target_workspace,address:$app_address" >/dev/null 2>&1; then
		log_error "Failed to move window: $app_address"
		return 1
	fi

	if [ "$focus" = "true" ]; then
		hyprctl dispatch focuswindow "address:$app_address" >/dev/null 2>&1
	fi

	return 0
}

move_window_to_workspace() {
	local target_ws=$1

	if ! validate_workspace "$target_ws"; then
		log_error "Cannot move window to invalid workspace: $target_ws"
		return 1
	fi

	local focused_window
	focused_window=$(get_focused_window)

	if [ "$focused_window" != "null" ] && [ -n "$focused_window" ]; then
		log_debug "Moving window $focused_window to workspace $target_ws"
		hyprctl dispatch movetoworkspace "$target_ws"
		hyprctl dispatch workspace "$target_ws"
		safe_write_file "$CURRENT_WS_FILE" "$target_ws"
	else
		log_error "No focused window to move"
		return 1
	fi
}

#######################################
# APP MOVER FUNCTIONS
#######################################

interactive_select() {
	local workspace="$1"
	local selector=""

	if command -v rofi >/dev/null 2>&1; then
		selector="rofi"
	elif command -v wofi >/dev/null 2>&1; then
		selector="wofi"
	elif command -v fuzzel >/dev/null 2>&1; then
		selector="fuzzel"
	else
		log_error "No selector found (rofi/wofi/fuzzel)"
		notify "$SCRIPT_NAME" "Install rofi, wofi, or fuzzel for interactive mode" "critical"
		return 1
	fi

	local apps
	apps=$(get_apps_in_workspace "$workspace")

	if [ -z "$apps" ]; then
		return 1
	fi

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

	while IFS='|' read -r addr class title pid; do
		local display="${class} - ${title}"
		if [ "$display" = "$selected" ]; then
			echo "$addr"
			return 0
		fi
	done <<<"$apps"

	return 1
}

move_apps_from_workspace() {
	local source_workspace="$1"
	local move_all="${2:-false}"
	local interactive="${3:-false}"
	local focus_window="${4:-false}"

	if ! validate_workspace "$source_workspace"; then
		return 1
	fi

	local current_workspace
	current_workspace=$(get_current_workspace)

	if [ "$source_workspace" -eq "$current_workspace" ]; then
		notify "$SCRIPT_NAME" "Already in workspace $source_workspace" "normal"
		return 0
	fi

	local apps
	apps=$(get_apps_in_workspace "$source_workspace")
	local app_count
	app_count=$(get_app_count "$source_workspace")

	if [ -z "$apps" ] || [ "$app_count" -eq 0 ]; then
		notify "$SCRIPT_NAME" "No applications in workspace $source_workspace" "normal"
		log_warning "No applications found in workspace $source_workspace"
		return 1
	fi

	log_debug "Found $app_count app(s) in workspace $source_workspace"

	local moved_count=0
	local moved_names=()

	if [ "$interactive" = "true" ]; then
		local selected_addr
		selected_addr=$(interactive_select "$source_workspace")

		if [ -n "$selected_addr" ]; then
			local app_info
			app_info=$(format_app_info "$selected_addr")

			if move_window "$current_workspace" "$selected_addr" "$focus_window"; then
				moved_count=1
				moved_names+=("$app_info")
				log_success "Moved: $app_info"
			fi
		fi

	elif [ "$move_all" = "true" ]; then
		while IFS='|' read -r addr class title pid; do
			local app_info="${class} - ${title:0:30}"

			if move_window "$current_workspace" "$addr" "$focus_window"; then
				moved_count=$((moved_count + 1))
				moved_names+=("$app_info")
				log_debug "Moved: $app_info"
			fi
		done <<<"$apps"

	else
		local first_addr
		first_addr=$(echo "$apps" | head -1 | cut -d'|' -f1)
		local app_info
		app_info=$(format_app_info "$first_addr")

		if move_window "$current_workspace" "$first_addr" "$focus_window"; then
			moved_count=1
			moved_names+=("$app_info")
			log_success "Moved: $app_info"
		fi
	fi

	if [ $moved_count -gt 0 ]; then
		if [ $moved_count -eq 1 ]; then
			notify "$SCRIPT_NAME" "Moved ${moved_names[0]} from WS$source_workspace → WS$current_workspace" "normal"
		else
			notify "$SCRIPT_NAME" "Moved $moved_count apps from WS$source_workspace → WS$current_workspace" "normal"
		fi
	else
		log_warning "No windows were moved"
		return 1
	fi

	log_success "Successfully moved $moved_count window(s)"
	return 0
}

#######################################
# MONITOR MANAGEMENT
#######################################

toggle_monitor_focus() {
	local current_state
	current_state=$(cat "$STATE_FILE" 2>/dev/null || echo "up")

	log_debug "Toggling monitor focus, current state: $current_state"

	if [ "$current_state" = "up" ]; then
		hyprctl dispatch movefocus d
		echo "down" >"$STATE_FILE"
		log_debug "Focus changed to: down"
	else
		hyprctl dispatch movefocus u
		echo "up" >"$STATE_FILE"
		log_debug "Focus changed to: up"
	fi
}

#######################################
# BROWSER TAB MANAGEMENT
#######################################

navigate_browser_tab() {
	local direction=$1
	local current_window
	current_window=$(hyprctl activewindow -j | jq -r '.class')

	log_debug "Navigating browser tab $direction in window class: $current_window"

	if [[ "$current_window" == *"brave"* || "$current_window" == *"Brave"* ]]; then
		if [ "$direction" = "next" ]; then
			hyprctl dispatch exec "wtype -P ctrl -p tab -r tab -R ctrl"
		else
			hyprctl dispatch exec "wtype -P ctrl -P shift -p tab -r tab -R shift -R ctrl"
		fi
	else
		if [ "$direction" = "next" ]; then
			wtype -M ctrl -k tab 2>/dev/null || ydotool key ctrl+tab 2>/dev/null
		else
			wtype -M ctrl -M shift -k tab 2>/dev/null || ydotool key ctrl+shift+tab 2>/dev/null
		fi
	fi
}

#######################################
# HELP SYSTEM
#######################################

show_help() {
	cat <<EOF
╭─────────────────────────────────────────────────────────────────╮
│              🚀 HyprFlow - Unified Hyprland Control             │
│                        Version ${VERSION}                           │
╰─────────────────────────────────────────────────────────────────╯

📋 QUICK REFERENCE (Most Used Commands):
  $0 -wt           ← Go to previous workspace (super useful!)
  $0 -wn 5         ← Jump to workspace 5
  $0 -mw 3         ← Move current window to workspace 3
  $0 -wr/-wl       ← Navigate workspaces left/right
  $0 -am 9         ← Move app FROM workspace 9 to current workspace
  $0 -am -i 9      ← Interactively select app to move from workspace 9

🖥️  MONITOR OPERATIONS:
  -ms              Shift monitors without focus
  -msf             Shift monitors with focus  
  -mt              Toggle monitor focus (up/down)
  -ml              Switch to left monitor
  -mr              Switch to right monitor
  -mn              Switch to next monitor
  -mp              Switch to previous monitor

🏠 WORKSPACE OPERATIONS:
  -wt              Switch to previous workspace ⭐
  -wr              Switch to workspace on the right
  -wl              Switch to workspace on the left  
  -wn NUM          Jump to workspace NUM (1-10)
  -mw NUM          Move focused window to workspace NUM

📦 APP MOVER OPERATIONS:
  -am NUM          Move first app FROM workspace NUM to current
  -am -a NUM       Move ALL apps FROM workspace NUM to current
  -am -i NUM       Interactive: select which app to move FROM workspace NUM
  -am -f NUM       Move app and focus it
  -am -a -f NUM    Move all apps and focus the first one

🪟 WINDOW FOCUS OPERATIONS:
  -vn              Cycle to next window
  -vp              Cycle to previous window
  -vl/-vr          Move focus left/right
  -vu/-vd          Move focus up/down

🌐 BROWSER TAB OPERATIONS:
  -tn              Next browser tab
  -tp              Previous browser tab
  
🛠️  MAINTENANCE & OPTIONS:
  -h, --help       Show this help message
  -d, --debug      Debug mode (detailed output)
  -s, --silent     Silent mode (no notifications)
  -c, --clear      Clear workspace history files
  -v, --version    Show version information

📝 EXAMPLES:
  # Workspace Navigation
  $0 -wn 5                    # Jump to workspace 5
  $0 -wt                      # Go to previous workspace
  $0 -wr                      # Move to next workspace
  
  # Window Management
  $0 -mw 3                    # Move current window to workspace 3
  $0 -vn                      # Focus next window
  
  # App Moving (NEW!)
  $0 -am 9                    # Move first app from workspace 9 here
  $0 -am -a 9                 # Move ALL apps from workspace 9 here
  $0 -am -i 9                 # Choose which app to move from workspace 9
  $0 -am -f 9                 # Move app from workspace 9 and focus it
  
  # Monitor Operations
  $0 -ms                      # Shift monitors
  $0 -mt                      # Toggle monitor focus
  
  # Debug & Maintenance
  $0 -d -wn 2                 # Jump to workspace 2 with debug output
  $0 -c                       # Reset workspace history

💡 TIPS:
  • Use -wt frequently to toggle between two workspaces
  • Combine -d with any command for troubleshooting
  • Use -am -i for interactive app selection with rofi/wofi
  • Use -am -a to quickly gather all apps from a workspace
  • Workspace numbers must be between 1-10
  • Browser tab navigation works with: Firefox, Chrome, Chromium, Brave

🔧 REQUIREMENTS:
  Required:  hyprctl, jq
  Optional:  pypr, rofi/wofi/fuzzel, wtype/ydotool, notify-send

📚 KEYBINDING EXAMPLES (add to hyprland.conf):
  # Quick workspace switching
  bind = SUPER CTRL, 1, exec, $0 -wn 1
  bind = SUPER CTRL, 2, exec, $0 -wn 2
  
  # Move current window to workspace
  bind = SUPER SHIFT, 1, exec, $0 -mw 1
  bind = SUPER SHIFT, 2, exec, $0 -mw 2
  
  # Pull apps from other workspaces
  bind = SUPER ALT, 1, exec, $0 -am 1
  bind = SUPER ALT, 2, exec, $0 -am -i 2
  
  # Navigation
  bind = SUPER, TAB, exec, $0 -wt
  bind = SUPER, left, exec, $0 -wl
  bind = SUPER, right, exec, $0 -wr

Version: ${VERSION} | License: MIT
Report issues: Check logs in ~/.cache/hypr/toggle/debug.log
EOF
}

show_version() {
	cat <<EOF
HyprFlow - Unified Hyprland Control
Version: ${VERSION}
Date: 2025-11-04
License: MIT

A comprehensive Hyprland control suite combining:
  - Workspace management
  - Monitor control
  - Window operations
  - App movement between workspaces
  - Browser tab navigation

Original Authors: Kenan Pelit & Contributors
EOF
}

#######################################
# MAIN EXECUTION
#######################################

main() {
	# Initialize environment
	init_environment

	# Show help if no arguments
	if [ $# -eq 0 ]; then
		show_help
		exit 0
	fi

	# Validate dependencies
	validate_dependencies

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --version)
			show_version
			exit 0
			;;
		-d | --debug)
			debug=true
			log_info "Debug mode enabled"
			shift
			;;
		-s | --silent)
			silent=true
			log_debug "Silent mode enabled"
			shift
			;;
		-c | --clear)
			clear_workspace_history
			exit 0
			;;
		# Monitor operations
		-ms)
			if command -v pypr &>/dev/null; then
				log_debug "Shifting monitors without focus"
				pypr shift_monitors "+1"
			else
				log_error "pypr not found - cannot shift monitors"
				exit 1
			fi
			shift
			;;
		-msf)
			if command -v pypr &>/dev/null; then
				log_debug "Shifting monitors with focus"
				pypr shift_monitors "+1"
				hyprctl dispatch focusmonitor "+1"
			else
				log_error "pypr not found - cannot shift monitors"
				exit 1
			fi
			shift
			;;
		-mt)
			log_debug "Toggling monitor focus"
			toggle_monitor_focus
			shift
			;;
		-ml)
			log_debug "Focusing left monitor"
			hyprctl dispatch focusmonitor l
			shift
			;;
		-mr)
			log_debug "Focusing right monitor"
			hyprctl dispatch focusmonitor r
			shift
			;;
		-mn)
			log_debug "Focusing next monitor"
			hyprctl dispatch focusmonitor "+1"
			shift
			;;
		-mp)
			log_debug "Focusing previous monitor"
			hyprctl dispatch focusmonitor "-1"
			shift
			;;
		# Workspace operations
		-wt)
			log_debug "Switching to previous workspace"
			prev_ws=$(get_previous_workspace)
			log_debug "Previous workspace is: $prev_ws"
			switch_to_workspace "$prev_ws"
			shift
			;;
		-wr)
			log_debug "Switching to workspace on right"
			switch_workspace_direction "right"
			shift
			;;
		-wl)
			log_debug "Switching to workspace on left"
			switch_workspace_direction "left"
			shift
			;;
		-wn)
			if [[ -z "${2:-}" ]]; then
				log_error "Workspace number is required for -wn"
				log_info "Usage: $0 -wn <workspace_number> (1-10)"
				exit 1
			fi

			if ! validate_workspace "$2"; then
				exit 1
			fi

			log_debug "Jumping to workspace $2"
			current_ws=$(get_current_workspace)
			safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"
			hyprctl dispatch workspace "$2"
			safe_write_file "$CURRENT_WS_FILE" "$2"
			log_debug "Switched from workspace $current_ws to $2"
			shift 2
			;;
		-mw)
			if [[ -z "${2:-}" ]]; then
				log_error "Workspace number is required for -mw"
				log_info "Usage: $0 -mw <workspace_number> (1-10)"
				exit 1
			fi

			if ! validate_workspace "$2"; then
				exit 1
			fi

			log_debug "Moving window to workspace $2"
			move_window_to_workspace "$2"
			shift 2
			;;
		# App mover operations
		-am)
			shift
			local move_all=false
			local interactive=false
			local focus_window=false
			local source_ws=""

			# Parse app mover sub-options
			while [[ $# -gt 0 ]]; do
				case $1 in
				-a)
					move_all=true
					shift
					;;
				-i)
					interactive=true
					shift
					;;
				-f)
					focus_window=true
					shift
					;;
				[0-9] | [0-9][0-9])
					source_ws=$1
					shift
					break
					;;
				*)
					log_error "Invalid option for -am: $1"
					exit 1
					;;
				esac
			done

			if [ -z "$source_ws" ]; then
				log_error "Workspace number required for -am"
				log_info "Usage: $0 -am [-a] [-i] [-f] <workspace_number>"
				exit 1
			fi

			log_debug "Moving apps from workspace $source_ws (all=$move_all, interactive=$interactive, focus=$focus_window)"
			move_apps_from_workspace "$source_ws" "$move_all" "$interactive" "$focus_window"
			;;
		# Window focus operations
		-vn)
			log_debug "Cycling to next window"
			hyprctl dispatch cyclenext
			shift
			;;
		-vp)
			log_debug "Cycling to previous window"
			hyprctl dispatch cyclenext prev
			shift
			;;
		-vl)
			log_debug "Moving focus left"
			hyprctl dispatch movefocus l
			shift
			;;
		-vr)
			log_debug "Moving focus right"
			hyprctl dispatch movefocus r
			shift
			;;
		-vu)
			log_debug "Moving focus up"
			hyprctl dispatch movefocus u
			shift
			;;
		-vd)
			log_debug "Moving focus down"
			hyprctl dispatch movefocus d
			shift
			;;
		# Browser tab operations
		-tn)
			log_debug "Navigating to next browser tab"
			navigate_browser_tab "next"
			shift
			;;
		-tp)
			log_debug "Navigating to previous browser tab"
			navigate_browser_tab "prev"
			shift
			;;
		*)
			log_error "Invalid option: $1"
			log_info "Use $0 -h for help"
			exit 1
			;;
		esac
	done
}

# Run main function
main "$@"
    )
    ;;
  switch)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-switch.sh
# ------------------------------------------------------------------------------

# ==============================================================================
# hypr-switch - Smart Monitor & Workspace Switcher for Hyprland
# ------------------------------------------------------------------------------
# Author  : Kenan Pelit
# Version : 1.1
# Updated : 2025-11-05
# ------------------------------------------------------------------------------
# Features:
#   • Auto-detects external monitors
#   • Switches focus and workspace intelligently
#   • Graceful fallbacks for jq / notify / hyprctl absence
#   • Colorized output and concise status messages
#   • Safe error handling and clear help text
# ==============================================================================

set -euo pipefail

# --- Configuration ------------------------------------------------------------
DEFAULT_WORKSPACE="2"
SLEEP_DURATION="0.2"
PRIMARY_MONITOR="eDP-1" # Built-in laptop display
NOTIFY_ENABLED=true
NOTIFY_TIMEOUT=3000 # milliseconds

# --- Colors -------------------------------------------------------------------
BOLD="\e[1m"
DIM="\e[2m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# --- Utility ------------------------------------------------------------------
fatal() {
	echo -e "${RED}✗${RESET} $*" >&2
	exit 1
}
info() { echo -e "${BLUE}→${RESET} $*"; }
ok() { echo -e "${GREEN}✓${RESET} $*"; }

# --- Notifications ------------------------------------------------------------
send_notification() {
	$NOTIFY_ENABLED || return 0
	local title="$1" msg="$2" urgency="${3:-normal}" icon="${4:-video-display}"
	if command -v dunstify &>/dev/null; then
		dunstify -t "$NOTIFY_TIMEOUT" -u "$urgency" -i "$icon" "$title" "$msg"
	elif command -v notify-send &>/dev/null; then
		notify-send -t "$NOTIFY_TIMEOUT" -u "$urgency" -i "$icon" "$title" "$msg"
	else
		local color="rgb(61afef)"
		[[ "$urgency" == "critical" ]] && color="rgb(e06c75)"
		hyprctl notify -1 "$NOTIFY_TIMEOUT" "$color" "$title: $msg" >/dev/null 2>&1 || true
	fi
}

# --- Hyprland connectivity check ---------------------------------------------
check_hyprland() {
	command -v hyprctl &>/dev/null || fatal "Hyprland (hyprctl) not found."
	hyprctl version &>/dev/null || fatal "Cannot connect to Hyprland socket."
}

# --- Monitor helpers ----------------------------------------------------------
list_monitors() {
	info "Available monitors:"
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -r '
      .[] |
      (
        "  " +
        .name + "\t(" +
        (.width|tostring) + "x" + (.height|tostring) +
        " @ " + (.refreshRate|tostring) + "Hz)\t" +
        (if .focused then "ACTIVE" else "" end)
      )'
	else
		hyprctl monitors | grep "^Monitor"
	fi
}

find_external_monitor() {
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -r ".[] | select(.name != \"$PRIMARY_MONITOR\") | .name" | head -1
	else
		hyprctl monitors | grep "^Monitor" | grep -v "$PRIMARY_MONITOR" | awk '{print $2}' | head -1
	fi
}

get_active_monitor() {
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
	else
		hyprctl monitors | awk '/focused: yes/{getline prev; print prev}' | awk '{print $2}'
	fi
}

get_monitor_info() {
	local mon="$1"
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -r ".[] | select(.name==\"$mon\") | \"\(.width)x\(.height)@\(.refreshRate)Hz\""
	else
		hyprctl monitors | grep -A1 "Monitor $mon" | grep -Eo '[0-9]+x[0-9]+'
	fi
}

validate_monitor() {
	local mon="$1"
	if command -v jq &>/dev/null; then
		hyprctl monitors -j | jq -e ".[] | select(.name==\"$mon\")" &>/dev/null
	else
		hyprctl monitors | grep -q "^Monitor $mon"
	fi
}

validate_workspace() {
	[[ "$1" =~ ^[0-9]+$ && "$1" -ge 1 && "$1" -le 10 ]] || fatal "Workspace must be between 1–10."
}

run_hyprctl() {
	local cmd="$1" desc="$2"
	info "$desc"
	hyprctl dispatch "$cmd" >/dev/null 2>&1 || fatal "$desc failed."
}

# --- Help ---------------------------------------------------------------------
show_help() {
	cat <<EOF
${BOLD}hypr-switch${RESET} — Smart Monitor & Workspace Switcher for Hyprland

Usage:
  hypr-switch [OPTIONS] [WORKSPACE]

Options:
  -h, --help           Show this help message
  -l, --list           List current monitors and workspaces
  -t, --timeout NUM    Delay between monitor switch (default: $SLEEP_DURATION)
  -m, --monitor NAME   Manually specify monitor (skip auto-detection)
  -n, --no-notify      Disable notifications
  -p, --primary        Force switch to primary monitor only

Examples:
  hypr-switch           # Auto-detect external monitor, switch to workspace $DEFAULT_WORKSPACE
  hypr-switch 5         # Auto-detect external monitor, switch to workspace 5
  hypr-switch -m DP-2 3 # Manually switch to DP-2, workspace 3
  hypr-switch -p        # Focus back on laptop screen
EOF
}

# --- Main ---------------------------------------------------------------------
main() {
	local monitor="" workspace="$DEFAULT_WORKSPACE" primary_only=false manual_monitor=false

	while (($#)); do
		case "$1" in
		-h | --help)
			show_help
			exit 0
			;;
		-l | --list)
			list_monitors
			hyprctl workspaces | grep workspace
			exit 0
			;;
		-t | --timeout)
			[[ "${2:-}" =~ ^[0-9]+(\.[0-9]+)?$ ]] || fatal "--timeout expects a number"
			SLEEP_DURATION="$2"
			shift 2
			;;
		-m | --monitor)
			monitor="${2:-}"
			[[ -n "$monitor" ]] || fatal "--monitor requires a name"
			manual_monitor=true
			shift 2
			;;
		-n | --no-notify)
			NOTIFY_ENABLED=false
			shift
			;;
		-p | --primary)
			primary_only=true
			shift
			;;
		-*) fatal "Unknown option: $1" ;;
		*)
			workspace="$1"
			shift
			;;
		esac
	done

	check_hyprland
	validate_workspace "$workspace"

	if $primary_only; then
		monitor="$PRIMARY_MONITOR"
		send_notification "Monitor Switch" "Returning to primary monitor ($monitor)"
	elif ! $manual_monitor; then
		info "Detecting external monitor..."
		monitor=$(find_external_monitor)
		if [[ -z "$monitor" ]]; then
			warn="No external monitor found, falling back to $PRIMARY_MONITOR"
			echo -e "${YELLOW}!${RESET} $warn"
			send_notification "No External Monitor" "$warn"
			monitor="$PRIMARY_MONITOR"
		else
			send_notification "External Monitor Detected" "$monitor ($(get_monitor_info "$monitor"))"
		fi
	fi

	validate_monitor "$monitor" || fatal "Monitor '$monitor' not found."

	local current_monitor
	current_monitor=$(get_active_monitor)

	echo -e "\n${BOLD}Hyprland Workspace Manager${RESET}"
	echo "Current:  $current_monitor"
	echo "Target:   $monitor"
	echo "Workspace:$workspace"
	echo "Delay:    ${SLEEP_DURATION}s"
	echo

	if [[ "$current_monitor" == "$monitor" ]]; then
		info "Already on $monitor, switching workspace only."
		run_hyprctl "workspace $workspace" "Switching to workspace $workspace"
	else
		run_hyprctl "focusmonitor $monitor" "Focusing monitor $monitor"
		sleep "$SLEEP_DURATION"
		run_hyprctl "workspace $workspace" "Switching to workspace $workspace"
	fi

	ok "Done."
	send_notification "hypr-switch" "$monitor ($(get_monitor_info "$monitor")) → Workspace $workspace" "normal" "emblem-success"
}

main "$@"
    )
    ;;
  layout-toggle)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-layout_toggle.sh
# ------------------------------------------------------------------------------

# hypr-layout_toggle.sh - Hyprland layout anahtarlayıcı
# Tiling/float düzenleri veya belirli layout’lar arasında hızlı geçiş yapar.

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
    )
    ;;
  vlc-toggle)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-vlc_toggle.sh
# ------------------------------------------------------------------------------

########################################
#
# Version: 1.1.0
# Date: 2025-03-10
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - VLC Medya Kontrolü
#
# License: MIT
#
########################################

# Renkler ve semboller
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
INFO='\033[0;34m'
NC='\033[0m'
MUSIC_EMOJI="🎵"
PAUSE_EMOJI="⏸️"
PLAY_EMOJI="▶️"
ERROR_EMOJI="❌"

# Yapılandırma
NOTIFICATION_TIMEOUT=3000
NOTIFICATION_ICON="vlc"
PLAYER="vlc"
MAX_TITLE_LENGTH=40

# Debug modu (1=aktif, 0=pasif)
DEBUG=0

# Debug mesajlarını yazdır
debug() {
	if [ "$DEBUG" -eq 1 ]; then
		echo -e "${INFO}[DEBUG] $1${NC}" >&2
	fi
}

# Hata kontrolü - geliştirilmiş versiyon
check_vlc_running() {
	# Daha geniş bir arama yap
	if ! ps aux | grep -v grep | grep -i "vlc" >/dev/null; then
		debug "VLC işlemi bulunamadı"
		notify-send -i $NOTIFICATION_ICON -t $NOTIFICATION_TIMEOUT \
			"$ERROR_EMOJI VLC Hatası" "VLC çalışmıyor. Oynatıcıyı başlatın."
		exit 1
	else
		debug "VLC işlemi bulundu"
		# Playerctl'ın VLC'yi tanıyıp tanımadığını kontrol et
		if ! playerctl -l 2>/dev/null | grep -i "$PLAYER" >/dev/null; then
			debug "Playerctl VLC oynatıcısını bulamadı, genel kontrol kullanılıyor"
			PLAYER="" # Eğer playerctl özel olarak VLC'yi bulamazsa, tüm oynatıcılar için komut göndeririz
		fi
	fi
}

# Metni kısalt (çok uzunsa)
truncate_text() {
	local text=$1
	local max_length=$2
	if [ ${#text} -gt $max_length ]; then
		echo "${text:0:$max_length}..."
	else
		echo "$text"
	fi
}

# Medya bilgilerini al
get_media_info() {
	local player_param=""
	if [ -n "$PLAYER" ]; then
		player_param="--player=$PLAYER"
	fi

	debug "Playerctl parametresi: $player_param"

	local title=$(playerctl $player_param metadata title 2>/dev/null)
	local artist=$(playerctl $player_param metadata artist 2>/dev/null)
	local album=$(playerctl $player_param metadata album 2>/dev/null)

	debug "Ham başlık: $title"
	debug "Ham sanatçı: $artist"

	# Bazı medya dosyaları sadece başlık içerir, sanatçı veya albüm olmayabilir
	if [ -z "$title" ]; then
		# Başlık bilgisi yoksa dosya adını almaya çalış
		title=$(playerctl $player_param metadata xesam:url 2>/dev/null | awk -F/ '{print $NF}' | sed 's/%20/ /g')

		# Hala boşsa, hyprctl ile aktif pencere başlığını almayı dene
		if [ -z "$title" ]; then
			debug "Metadata bulunamadı, pencere başlığından almayı deneyeceğim"
			title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title' 2>/dev/null | grep -i "vlc" | sed 's/ - VLC media player//')
		fi

		# Son çare olarak varsayılan değer kullan
		if [ -z "$title" ]; then
			debug "Başlık bilgisi bulunamadı, varsayılan değer kullanılıyor"
			title="Bilinmeyen Parça"
		fi
	fi

	# Metinleri kısalt
	title=$(truncate_text "$title" $MAX_TITLE_LENGTH)
	artist=$(truncate_text "$artist" $MAX_TITLE_LENGTH)

	# Sonuçları döndür (global değişkenlere atama)
	TITLE="$title"
	ARTIST="$artist"
	ALBUM="$album"

	debug "İşlenmiş başlık: $TITLE"
	debug "İşlenmiş sanatçı: $ARTIST"
}

# Oynatma durumunu değiştir
toggle_playback() {
	local player_param=""
	if [ -n "$PLAYER" ]; then
		player_param="--player=$PLAYER"
	fi

	# Önce durumu kontrol et
	local prev_state=$(playerctl $player_param status 2>/dev/null)
	debug "Önceki durum: $prev_state"

	# Oynat/Duraklat komutunu gönder
	playerctl $player_param play-pause 2>/dev/null || {
		debug "Playerctl komutu başarısız, alternatif metot deneniyor"
		# Alternatif: VLC için dbus-send kullanma
		if dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause >/dev/null 2>&1; then
			debug "dbus-send başarılı"
		else
			debug "dbus-send başarısız, XF86AudioPlay simülasyonu deneniyor"
			# Son çare: XF86AudioPlay tuşunu simüle et
			DISPLAY=:0 xdotool key XF86AudioPlay 2>/dev/null
		fi
	}

	# Kısa bir gecikme (durumun güncellenmesi için)
	sleep 0.2
}

# Ana işlev
main() {
	# VLC çalışıyor mu kontrol et
	check_vlc_running

	# Medya bilgilerini al
	get_media_info

	# Oynatma durumunu değiştir
	toggle_playback

	# Güncel durumu al
	local player_param=""
	if [ -n "$PLAYER" ]; then
		player_param="--player=$PLAYER"
	fi
	local current_state=$(playerctl $player_param status 2>/dev/null)
	debug "Güncel durum: $current_state"

	# Durum alınamazsa, önceki durumun tersini tahmin et
	if [ -z "$current_state" ]; then
		debug "Durum alınamadı, durum tahmini yapılıyor"
		if [ -n "$(ps aux | grep -v grep | grep -i 'vlc' | grep -v 'paused')" ]; then
			current_state="Playing"
			debug "Tahmin edilen durum: $current_state"
		else
			current_state="Paused"
			debug "Tahmin edilen durum: $current_state"
		fi
	fi

	# Bildirim mesajını hazırla
	local notification_title
	local notification_body

	if [ "$current_state" = "Playing" ]; then
		notification_title="$PLAY_EMOJI Oynatılıyor"
		if [ -n "$ARTIST" ]; then
			notification_body="$TITLE - $ARTIST"
		else
			notification_body="$TITLE"
		fi

		if [ -n "$ALBUM" ]; then
			notification_body="$notification_body\nAlbüm: $ALBUM"
		fi
	elif [ "$current_state" = "Paused" ]; then
		notification_title="$PAUSE_EMOJI Duraklatıldı"
		if [ -n "$ARTIST" ]; then
			notification_body="$TITLE - $ARTIST"
		else
			notification_body="$TITLE"
		fi
	else
		notification_title="$MUSIC_EMOJI VLC Medya"
		notification_body="$TITLE"
	fi

	# Bildirimi göster
	notify-send -i $NOTIFICATION_ICON -t $NOTIFICATION_TIMEOUT "$notification_title" "$notification_body"

	# Konsolda da göster (isteğe bağlı)
	echo -e "${INFO}$notification_title${NC}"
	echo -e "${SUCCESS}$notification_body${NC}"
}

# Programı çalıştır
main
    )
    ;;
  wifi-power-save)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-wifi-power-save.sh
# ------------------------------------------------------------------------------

#######################################
#
# Version: 3.0.0
# Date: 2025-11-05
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - WiFi Power Management Toggle
#
# License: MIT
#
#######################################

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# İkon değişkenleri
ICON_WIFI="󰖩"
ICON_ERROR="󰅚"
ICON_INFO="󰋼"
ICON_SUCCESS="󰄬"

# Kullanım bilgisi
usage() {
	cat <<EOF
WiFi Power Save Manager - v3.0.0

KULLANIM:
    $(basename "$0") [KOMUT]

KOMUTLAR:
    on          Güç tasarrufunu aç
    off         Güç tasarrufunu kapat (varsayılan)
    toggle      Durumu tersine çevir (açsa kapat, kapalıysa aç)
    status      Mevcut durumu göster
    -h, --help  Bu yardım mesajını göster

ÖRNEKLER:
    $(basename "$0")         # Güç tasarrufunu kapat (varsayılan)
    $(basename "$0") off     # Güç tasarrufunu kapat
    $(basename "$0") on      # Güç tasarrufunu aç
    $(basename "$0") toggle  # Durumu tersine çevir
    $(basename "$0") status  # Sadece durumu göster

EOF
}

# Bildirim gönder
send_notification() {
	local title="$1"
	local message="$2"
	local icon="$3"
	local urgency="${4:-normal}"

	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 5000 -u "$urgency" "$icon $title" "$message"
	fi
	echo -e "${BLUE}$icon${NC} $title: $message"
}

# Mevcut durumu kontrol et
check_current_status() {
	local interface="$1"
	local status=$(iw "$interface" get power_save 2>/dev/null | grep "Power save" | awk '{print $NF}')
	echo "$status"
}

# Güç tasarrufunu ayarla
set_power_save() {
	local interface="$1"
	local mode="$2" # on veya off

	if sudo iw "$interface" set power_save "$mode" >/dev/null 2>&1; then
		sleep 0.5
		local new_status=$(check_current_status "$interface")

		if [ "$new_status" = "$mode" ]; then
			local mode_tr=$([ "$mode" = "on" ] && echo "AÇILDI" || echo "KAPATILDI")
			send_notification "Başarılı" "$interface için güç tasarrufu $mode_tr" "$ICON_SUCCESS"
			return 0
		else
			send_notification "Uyarı" "Değişiklik teyit edilemedi." "$ICON_ERROR" "normal"
			return 1
		fi
	else
		send_notification "Hata" "Güç tasarrufu değiştirilemedi." "$ICON_ERROR" "critical"
		return 1
	fi
}

# Ana işlem
main() {
	local command="${1:-off}" # Varsayılan: off

	# Bağlı Wi-Fi arayüzünü bul
	local interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)

	# Eğer arayüz bulunamazsa hata mesajı göster
	if [ -z "$interface" ]; then
		send_notification "Hata" "Wi-Fi arayüzü bulunamadı." "$ICON_ERROR" "critical"
		exit 1
	fi

	# Mevcut durumu kontrol et
	local current_status=$(check_current_status "$interface")

	if [ -z "$current_status" ]; then
		send_notification "Hata" "Güç tasarrufu durumu okunamadı." "$ICON_ERROR" "critical"
		exit 1
	fi

	# Komuta göre işlem yap
	case "$command" in
	on)
		if [ "$current_status" = "on" ]; then
			send_notification "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu zaten AÇIK" "$ICON_INFO"
		else
			send_notification "Wi-Fi Güç Tasarrufu" "Mevcut: KAPALI, açılıyor..." "$ICON_INFO"
			set_power_save "$interface" "on"
		fi
		;;

	off)
		if [ "$current_status" = "off" ]; then
			send_notification "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu zaten KAPALI" "$ICON_SUCCESS"
		else
			send_notification "Wi-Fi Güç Tasarrufu" "Mevcut: AÇIK, kapatılıyor..." "$ICON_INFO"
			set_power_save "$interface" "off"
		fi
		;;

	toggle)
		if [ "$current_status" = "on" ]; then
			send_notification "Wi-Fi Güç Tasarrufu" "AÇIK durumundan KAPALI durumuna geçiliyor..." "$ICON_INFO"
			set_power_save "$interface" "off"
		else
			send_notification "Wi-Fi Güç Tasarrufu" "KAPALI durumundan AÇIK durumuna geçiliyor..." "$ICON_INFO"
			set_power_save "$interface" "on"
		fi
		;;

	status)
		local status_tr=$([ "$current_status" = "on" ] && echo "AÇIK" || echo "KAPALI")
		send_notification "Wi-Fi Güç Tasarrufu" "$interface durumu: $status_tr" "$ICON_INFO"
		;;

	-h | --help)
		usage
		exit 0
		;;

	*)
		echo -e "${RED}${ICON_ERROR}${NC} Geçersiz komut: $command"
		echo ""
		usage
		exit 1
		;;
	esac
}

# Scripti çalıştır
main "$@"
    )
    ;;
  airplane-mode)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-airplane_mode.sh
# ------------------------------------------------------------------------------

# hypr-airplane_mode.sh - Hyprland kablosuz/kablolu güç yönetimi toggle’ı
# rfkill/Wi‑Fi/Bluetooth durumunu değiştirip oturum bildirimleriyle haber verir.

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

# Wi-Fi durumu kontrol ediliyor
wifi_status=$(nmcli -t -f WIFI g)

if [[ "$wifi_status" == "enabled" ]]; then
  rfkill block all &
  notify-send -t 1000 "Airplane Mode: Active" "All wireless devices are disabled."
elif [[ "$wifi_status" == "disabled" ]]; then
  rfkill unblock all &
  notify-send -t 1000 "Airplane Mode: Inactive" "All wireless devices are enabled."
else
  notify-send -u critical -t 3000 "Error" "Failed to retrieve Wi-Fi status."
  exit 1
fi
    )
    ;;
  colorpicker)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-colorpicker.sh
# ------------------------------------------------------------------------------

# hypr-colorpicker.sh - Hyprland renk seçici entegrasyonu
# Hyprpicker/wayland-rgb ile renk alır, klavye/bildirimle geri bildirir.

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

## Simple Script To Pick Color Quickly.

pick_color() {
  local geometry
  geometry=$(slurp -b 1B1F2800 -p) || return 1

  # Check if geometry is not empty
  if [ -z "$geometry" ]; then
    notify-send "Error" "No area selected"
    return 1
  fi # Buradaki kapanış parantezini düzelttim

  local color
  color=$(grim -g "$geometry" -t ppm - |
    magick - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null |
    tail -n1 | cut -d' ' -f4)

  # Check if color was successfully captured
  if [ -n "$color" ]; then
    # Copy to clipboard
    echo -n "$color" | wl-copy

    # Create temporary image for preview
    local image="/tmp/color_preview_${color//[#\/\\]/}.png"
    magick -size 48x48 xc:"$color" "$image" 2>/dev/null

    # Show notification
    if [ -f "$image" ]; then
      notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$image" "$color, copied to clipboard."
    else
      notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "$color, copied to clipboard."
    fi

    # Clean up
    rm -f "$image"
  else
    notify-send "Error" "Failed to capture color"
    return 1
  fi
}

# Run the script
pick_color
    )
    ;;
  start-batteryd)
    (
set -euo pipefail

# ------------------------------------------------------------------------------
# Embedded: hypr-start-batteryd.sh
# ------------------------------------------------------------------------------

# hypr-start-batteryd.sh - Hyprland oturumunda batteryd başlatıcı
# Güç izleme daemon’unu tek seferlik başlatır; log ve pid kontrolü içerir.

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

# Battery Daemon
# Get battery status and send notification when battery is low
# Requires: dunst, notify-send, acpi

# Önceki durumlar için bayrak değişkenleri
NOTIFIED_FULL=false
NOTIFIED_CRITICAL=false
NOTIFIED_LOW=false

while true; do
  # Batarya yüzdesini hesapla
  battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

  # Şarj durumu ve doluluk kontrolü
  charging=$(acpi -b | grep -o 'Charging')
  full=$(acpi -b | grep -o 'Full')

  # Şarj doluysa ve daha önce bildirilmemişse
  if [[ $full == "Full" && $charging == "Charging" && $NOTIFIED_FULL == false ]]; then
    notify-send -u low "  Battery is full." "Please unplug the AC adapter."
    NOTIFIED_FULL=true
    NOTIFIED_CRITICAL=false
    NOTIFIED_LOW=false
  fi

  # Batarya kritik seviyedeyse ve daha önce bildirilmemişse
  if [[ $battery_level -le 15 && $charging != "Charging" && $NOTIFIED_CRITICAL == false ]]; then
    notify-send -u critical "  Battery is critically low." "Please plug in the AC adapter."
    NOTIFIED_CRITICAL=true
    NOTIFIED_LOW=false
    NOTIFIED_FULL=false
  fi

  # Batarya düşük seviyedeyse ve daha önce bildirilmemişse
  if [[ $battery_level -le 30 && $battery_level -gt 15 && $charging != "Charging" && $NOTIFIED_LOW == false ]]; then
    notify-send -u normal "  Battery is low." "Please plug in the AC adapter."
    NOTIFIED_LOW=true
    NOTIFIED_CRITICAL=false
    NOTIFIED_FULL=false
  fi

  # Şarj durumu değişirse bayrakları sıfırla
  if [[ $charging == "Charging" ]]; then
    NOTIFIED_CRITICAL=false
    NOTIFIED_LOW=false
  fi

  # 1 dakika bekle ve döngüyü tekrarla
  sleep 60
done
    )
    ;;
  *)
    echo "Unknown command: ${cmd}" >&2
    usage >&2
    exit 2
    ;;
esac
