#!/usr/bin/env bash
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

	# Hyprland binary kontrolü
	if command -v Hyprland &>/dev/null; then
		HYPRLAND_BINARY="Hyprland"
	elif command -v hyprland &>/dev/null; then
		HYPRLAND_BINARY="hyprland"
	else
		error "Hyprland binary bulunamadı! PATH: $PATH"
	fi

	local hypr_version=$("$HYPRLAND_BINARY" --version 2>&1 | head -n1 || echo "Unknown")
	info "Hyprland version: $hypr_version"

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
