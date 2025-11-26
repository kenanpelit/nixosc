#!/usr/bin/env bash
# =============================================================================
# COSMIC TTY Başlatma Script'i - Production Ready
# =============================================================================
# ThinkPad E14 Gen 6 + Intel Arc Graphics + NixOS
# Dinamik Catppuccin tema desteği ile
# =============================================================================
# KULLANIM:
#   cosmic_tty              - Normal başlatma
#   cosmic_tty -d           - Debug modu
#   cosmic_tty --dry-run    - Sadece kontroller, başlatma
# =============================================================================

set -euo pipefail

# =============================================================================
# Sabit Değişkenler
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_DIR="$HOME/.logs"
readonly COSMIC_LOG="$LOG_DIR/cosmic.log"
readonly DEBUG_LOG="$LOG_DIR/cosmic_debug.log"
readonly MAX_LOG_SIZE=10485760 # 10MB
readonly MAX_LOG_BACKUPS=3

# Terminal renk kodları
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[1;33m'
readonly C_RED='\033[0;31m'
readonly C_CYAN='\033[0;36m'
readonly C_RESET='\033[0m'

# Catppuccin flavor ve accent
CATPPUCCIN_FLAVOR="${CATPPUCCIN_FLAVOR:-mocha}"
CATPPUCCIN_ACCENT="${CATPPUCCIN_ACCENT:-mauve}"

# Debug modu flag
DEBUG_MODE=false
DRY_RUN=false

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

	if [[ -d "$(dirname "$COSMIC_LOG")" ]]; then
		echo "$log_entry" >>"$COSMIC_LOG" 2>/dev/null || {
			debug_log "Ana log dosyasına yazılamadı: $COSMIC_LOG"
		}
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

# =============================================================================
# Dizin ve Log Yönetimi
# =============================================================================

setup_directories() {
	debug_log "setup_directories başlatılıyor"
	debug_log "LOG_DIR: $LOG_DIR | COSMIC_LOG: $COSMIC_LOG"

	if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
		warn "Log dizini oluşturulamadı: $LOG_DIR, /tmp kullanılıyor"
		LOG_DIR="/tmp/cosmic-logs-$USER"
		COSMIC_LOG="$LOG_DIR/cosmic.log"
		DEBUG_LOG="$LOG_DIR/cosmic_debug.log"
		mkdir -p "$LOG_DIR" || error "Hiçbir log dizini oluşturulamadı"
	fi

	if [[ ! -w "$LOG_DIR" ]]; then
		error "Log dizinine yazma izni yok: $LOG_DIR"
	fi

	touch "$COSMIC_LOG" "$DEBUG_LOG" 2>/dev/null || {
		error "Log dosyaları oluşturulamadı"
	}

	debug_log "Log dizini hazır: $LOG_DIR"
}

rotate_logs() {
	debug_log "Log rotasyonu kontrol ediliyor"

	if [[ ! -f "$COSMIC_LOG" ]]; then
		debug_log "Ana log dosyası yok, rotasyon gerekmiyor"
		return 0
	fi

	local file_size=$(stat -c%s "$COSMIC_LOG" 2>/dev/null || echo 0)
	debug_log "Ana log dosyası boyutu: $file_size bytes"

	if [[ $file_size -gt $MAX_LOG_SIZE ]]; then
		info "Log dosyası ${MAX_LOG_SIZE} byte'ı aştı, rotasyon yapılıyor"

		for ((i = $MAX_LOG_BACKUPS; i > 0; i--)); do
			local old_backup="${COSMIC_LOG}.old.$((i - 1))"
			local new_backup="${COSMIC_LOG}.old.$i"

			if [[ -f "$old_backup" ]]; then
				if [[ $i -eq $MAX_LOG_BACKUPS ]]; then
					rm -f "$old_backup"
					debug_log "En eski yedek silindi: $old_backup"
				else
					mv "$old_backup" "$new_backup"
					debug_log "Yedek kaydırıldı: $old_backup -> $new_backup"
				fi
			fi
		done

		mv "$COSMIC_LOG" "${COSMIC_LOG}.old.0"
		touch "$COSMIC_LOG"
		debug_log "Log rotasyonu tamamlandı"
	fi
}

# =============================================================================
# Sistem Kontrolleri
# =============================================================================

check_system() {
	debug_log "Sistem kontrolleri başlıyor"

	# XDG_RUNTIME_DIR kontrolü
	if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
		warn "XDG_RUNTIME_DIR ayarlandı: $XDG_RUNTIME_DIR"
	else
		debug_log "XDG_RUNTIME_DIR mevcut: $XDG_RUNTIME_DIR"
	fi

	if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
		error "XDG_RUNTIME_DIR dizini mevcut değil: $XDG_RUNTIME_DIR"
	fi

	if [[ ! -w "$XDG_RUNTIME_DIR" ]]; then
		error "XDG_RUNTIME_DIR yazılabilir değil: $XDG_RUNTIME_DIR"
	fi

	# TTY kontrolü
	if [[ -z "${XDG_VTNR:-}" ]]; then
		export XDG_VTNR=4
		warn "XDG_VTNR varsayılan değere ayarlandı: 4 (COSMIC için)"
	else
		debug_log "XDG_VTNR: $XDG_VTNR"
	fi

	# COSMIC binary kontrolü
	if ! command -v cosmic-session &>/dev/null; then
		error "cosmic-session binary bulunamadı! PATH: $PATH"
	fi

	# COSMIC component kontrolü
	local cosmic_components=(
		"cosmic-comp"
		"cosmic-panel"
		"cosmic-launcher"
		"cosmic-settings"
	)

	for component in "${cosmic_components[@]}"; do
		if command -v "$component" &>/dev/null; then
			debug_log "✓ $component mevcut"
		else
			warn "✗ $component bulunamadı (bazı özellikler çalışmayabilir)"
		fi
	done

	# COSMIC version bilgisi
	if command -v cosmic-comp &>/dev/null; then
		local cosmic_version=$(cosmic-comp --version 2>&1 | head -n1 || echo "Unknown")
		info "COSMIC version: $cosmic_version"
	fi

	info "Sistem kontrolleri tamamlandı"
}

# =============================================================================
# Environment Temizliği - Diğer Desktop'lardan Kalıntıları Sil
# =============================================================================

cleanup_environment() {
	debug_log "Environment temizliği yapılıyor"

	# Hyprland kalıntıları
	unset HYPRLAND_INSTANCE_SIGNATURE
	unset WLR_NO_HARDWARE_CURSORS
	unset WLR_DRM_NO_ATOMIC
	unset WLR_RENDERER
	unset HYPRLAND_LOG_WLR
	unset HYPRLAND_NO_RT
	unset HYPRLAND_NO_SD_NOTIFY

	# GNOME kalıntıları
	unset GNOME_SHELL_SESSION_MODE
	unset MUTTER_DEBUG_DUMMY_MODE_SPECS
	unset MUTTER_DEBUG_ENABLE_ATOMIC_KMS
	unset GNOME_KEYRING_CONTROL

	# Genel temizlik
	unset XDG_CURRENT_DESKTOP
	unset XDG_SESSION_DESKTOP
	unset DESKTOP_SESSION
	unset DBUS_SESSION_BUS_ADDRESS
	unset DBUS_SESSION_BUS_PID

	debug_log "Environment temizliği tamamlandı"
}

# =============================================================================
# Environment Değişkenleri - COSMIC Özel
# =============================================================================

setup_environment() {
	print_header "COSMIC ENVIRONMENT AYARLARI - CATPPUCCIN ${CATPPUCCIN_FLAVOR^^}"
	debug_log "Environment değişkenleri ayarlanıyor"

	# Environment temizliği
	cleanup_environment

	# -------------------------------------------------------------------------
	# Temel Wayland ve COSMIC Ayarları
	# -------------------------------------------------------------------------
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="cosmic"
	export XDG_CURRENT_DESKTOP="COSMIC"
	export DESKTOP_SESSION="cosmic"
	debug_log "Temel COSMIC değişkenleri: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP / $DESKTOP_SESSION"

	# -------------------------------------------------------------------------
	# Wayland Backend Tercihleri
	# -------------------------------------------------------------------------
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM="wayland;xcb"
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export CLUTTER_BACKEND=wayland
	export _JAVA_AWT_WM_NONREPARENTING=1
	debug_log "Wayland backend tercihleri ayarlandı"

	# -------------------------------------------------------------------------
	# COSMIC Özel Ayarlar
	# -------------------------------------------------------------------------
	export COSMIC_DATA_CONTROL_ENABLED=1
	export NIXOS_OZONE_WL=1
	debug_log "COSMIC özel özellikler aktif"

	# -------------------------------------------------------------------------
	# Intel Arc Graphics Optimizasyonları (COSMIC için)
	# -------------------------------------------------------------------------
	if lspci 2>/dev/null | grep -qi "arc\|meteor\|alchemist"; then
		info "Intel Arc Graphics tespit edildi"
		export COSMIC_RENDERER=gles2
		export COSMIC_NO_ATOMIC=1
		debug_log "Intel Arc optimizasyonları aktif"
	fi

	# -------------------------------------------------------------------------
	# Catppuccin Dinamik Tema - GTK (COSMIC GTK uygulamaları için)
	# -------------------------------------------------------------------------
	local gtk_theme="catppuccin-${CATPPUCCIN_FLAVOR}-${CATPPUCCIN_ACCENT}-standard+normal"
	export GTK_THEME="$gtk_theme"

	if [[ "$CATPPUCCIN_FLAVOR" == "latte" ]]; then
		export GTK_APPLICATION_PREFER_DARK_THEME=0
		debug_log "GTK light theme modu aktif (latte)"
	else
		export GTK_APPLICATION_PREFER_DARK_THEME=1
		debug_log "GTK dark theme modu aktif ($CATPPUCCIN_FLAVOR)"
	fi

	info "GTK Theme: $gtk_theme"

	# -------------------------------------------------------------------------
	# Catppuccin Dinamik Tema - Cursor
	# -------------------------------------------------------------------------
	local cursor_theme="catppuccin-${CATPPUCCIN_FLAVOR}-dark-cursors"
	export XCURSOR_THEME="$cursor_theme"
	export XCURSOR_SIZE=24
	info "Cursor Theme: $cursor_theme (size: 24)"

	# -------------------------------------------------------------------------
	# Qt Tema Ayarları
	# -------------------------------------------------------------------------
	export QT_QPA_PLATFORMTHEME=qt6ct
	export QT_STYLE_OVERRIDE=kvantum
	export QT_AUTO_SCREEN_SCALE_FACTOR=1
	debug_log "Qt tema ayarları: qt6ct + kvantum"

	# -------------------------------------------------------------------------
	# Türkçe F-Klavye
	# -------------------------------------------------------------------------
	export XKB_DEFAULT_LAYOUT=tr
	export XKB_DEFAULT_VARIANT=f
	export XKB_DEFAULT_OPTIONS=ctrl:nocaps
	debug_log "Klavye: Türkçe F (ctrl:nocaps)"

	# -------------------------------------------------------------------------
	# Varsayılan Uygulamalar
	# -------------------------------------------------------------------------
	export EDITOR=nvim
	export VISUAL=nvim
	export TERMINAL=cosmic-term
	export TERM=xterm-256color
	export BROWSER=brave
	debug_log "Varsayılan uygulamalar ayarlandı"

	# -------------------------------------------------------------------------
	# Font Rendering
	# -------------------------------------------------------------------------
	export FREETYPE_PROPERTIES="truetype:interpreter-version=40"
	if [[ -f /etc/fonts/fonts.conf ]]; then
		export FONTCONFIG_FILE=/etc/fonts/fonts.conf
	fi
	debug_log "Font rendering ayarları yapıldı"

	# -------------------------------------------------------------------------
	# Catppuccin flavor bilgisini ortama kaydet
	# -------------------------------------------------------------------------
	export CATPPUCCIN_FLAVOR="$CATPPUCCIN_FLAVOR"
	export CATPPUCCIN_ACCENT="$CATPPUCCIN_ACCENT"

	info "Environment ayarları tamamlandı"
	debug_log "Aktif flavor: $CATPPUCCIN_FLAVOR | Accent: $CATPPUCCIN_ACCENT"
	warn "NOT: COSMIC Beta aşamasında - kararsızlık beklenebilir"
}

# =============================================================================
# Eski COSMIC Proseslerini Temizleme
# =============================================================================

cleanup_old_processes() {
	debug_log "Eski COSMIC prosesleri kontrol ediliyor"

	local old_pids=$(pgrep -f "cosmic-session\|cosmic-comp" 2>/dev/null || true)

	if [[ -z "$old_pids" ]]; then
		debug_log "Eski COSMIC prosesi bulunamadı"
		return 0
	fi

	warn "Eski COSMIC prosesleri tespit edildi: $old_pids"

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Eski prosesler sonlandırılmayacak"
		return 0
	fi

	info "Eski prosesler zarif şekilde sonlandırılıyor (SIGTERM)..."
	echo "$old_pids" | xargs -r kill -TERM 2>/dev/null || true
	sleep 2

	local remaining_pids=$(pgrep -f "cosmic-session\|cosmic-comp" 2>/dev/null || true)
	if [[ -n "$remaining_pids" ]]; then
		warn "Bazı prosesler hala aktif, zorla sonlandırılıyor (SIGKILL)..."
		echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
		sleep 1
	fi

	debug_log "Eski prosesler temizlendi"
}

# =============================================================================
# D-Bus Session Başlatma
# =============================================================================

setup_dbus() {
	print_header "D-BUS SESSION BAŞLATMA"
	debug_log "D-Bus kontrolü başlatılıyor"

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] D-Bus başlatma atlanıyor"
		return 0
	fi

	# Mevcut D-Bus session kontrolü
	if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
		debug_log "D-Bus session zaten mevcut: $DBUS_SESSION_BUS_ADDRESS"
		return 0
	fi

	# D-Bus user session kontrolü
	if pgrep -u "$(id -u)" dbus-daemon >/dev/null 2>&1; then
		debug_log "D-Bus daemon zaten çalışıyor"

		# Mevcut session'ı al
		local dbus_addr=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "dbus-*" -type s 2>/dev/null | head -n1)
		if [[ -n "$dbus_addr" ]]; then
			export DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_addr"
			debug_log "Mevcut D-Bus session bulundu: $DBUS_SESSION_BUS_ADDRESS"
			return 0
		fi
	fi

	info "D-Bus session başlatılıyor..."

	# dbus-launch kullanarak başlat
	if command -v dbus-launch &>/dev/null; then
		debug_log "dbus-launch kullanılacak"
		eval $(dbus-launch --sh-syntax --exit-with-session)
		export DBUS_SESSION_BUS_ADDRESS
		export DBUS_SESSION_BUS_PID
		info "D-Bus session başlatıldı (PID: $DBUS_SESSION_BUS_PID)"
	else
		warn "dbus-launch bulunamadı, COSMIC otomatik başlatmayı deneyecek"
	fi
}

# =============================================================================
# Systemd Entegrasyonu
# =============================================================================

setup_systemd_integration() {
	print_header "SYSTEMD ENTEGRASYONU"
	debug_log "Systemd entegrasyonu başlatılıyor"

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Systemd entegrasyonu atlanıyor"
		return 0
	fi

	local systemd_vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP DBUS_SESSION_BUS_ADDRESS"

	if systemctl --user import-environment $systemd_vars 2>/dev/null; then
		debug_log "Systemd environment import başarılı"
	else
		warn "Systemd environment import başarısız"
	fi

	if dbus-update-activation-environment --systemd $systemd_vars 2>/dev/null; then
		debug_log "DBus activation environment güncellendi"
	else
		warn "DBus activation environment güncellenemedi"
	fi

	info "Systemd entegrasyonu tamamlandı"
}

# =============================================================================
# Cleanup Fonksiyonu
# =============================================================================

cleanup() {
	debug_log "Cleanup fonksiyonu tetiklendi"
	info "COSMIC oturumu sonlandırılıyor..."

	local cosmic_pids=$(pgrep -f "cosmic-session\|cosmic-comp" 2>/dev/null || true)

	if [[ -n "$cosmic_pids" ]]; then
		debug_log "COSMIC prosesleri bulundu: $cosmic_pids"
		echo "$cosmic_pids" | xargs -r kill -TERM 2>/dev/null || true
		sleep 2

		local remaining=$(pgrep -f "cosmic-session\|cosmic-comp" 2>/dev/null || true)
		if [[ -n "$remaining" ]]; then
			warn "Bazı prosesler hala aktif, zorla sonlandırılıyor"
			echo "$remaining" | xargs -r kill -KILL 2>/dev/null || true
		fi
	fi

	debug_log "Cleanup tamamlandı"
}

# =============================================================================
# COSMIC Başlatma
# =============================================================================

start_cosmic() {
	print_header "COSMIC BAŞLATILIYOR"
	debug_log "COSMIC başlatma fonksiyonu çağrıldı"

	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] COSMIC başlatılmayacak"
		info "[DRY-RUN] Tüm kontroller başarılı, normal modda çalıştırabilirsiniz"
		exit 0
	fi

	trap cleanup EXIT TERM INT HUP
	debug_log "Signal trap'leri ayarlandı"

	info "═══════════════════════════════════════════════════════════"
	info "COSMIC başlatılıyor..."
	info "Session: cosmic (Beta)"
	info "Flavor: $CATPPUCCIN_FLAVOR | Accent: $CATPPUCCIN_ACCENT"
	info "Log: $COSMIC_LOG"
	info "═══════════════════════════════════════════════════════════"
	warn "UYARI: COSMIC Beta aşamasında - hatalar beklenebilir"

	debug_log "COSMIC session başlatılıyor"

	# CRITICAL FIX: COSMIC needs working systemd user session
	# Do NOT set SYSTEMD_OFFLINE - let systemd manage the session properly
	if ! systemctl --user is-active --quiet default.target 2>/dev/null; then
		error "Systemd user session not active! COSMIC requires systemd user services to be running."
	fi

	# Ensure SYSTEMD_OFFLINE is NOT set (this breaks session services!)
	unset SYSTEMD_OFFLINE

	# COSMIC session'ı başlat
	debug_log "Executing: cosmic-session"
	exec cosmic-session >>"$COSMIC_LOG" 2>&1

	error "COSMIC exec başarısız oldu!"
}

# =============================================================================
# Yardım Mesajı
# =============================================================================

show_help() {
	cat <<EOF
╔════════════════════════════════════════════════════════════╗
║  COSMIC TTY Launcher v${SCRIPT_VERSION}                          ║
╚════════════════════════════════════════════════════════════╝

KULLANIM:
  $SCRIPT_NAME [SEÇENEKLER]

SEÇENEKLER:
  -h, --help       Bu yardım mesajını göster
  -d, --debug      Debug modu (detaylı log)
  --dry-run        Sadece kontroller, başlatma yapma
  -v, --version    Version bilgisini göster

ÖRNEKLER:
  $SCRIPT_NAME              # Normal başlatma
  $SCRIPT_NAME -d           # Debug modu ile
  $SCRIPT_NAME --dry-run    # Sadece test et

CATPPUCCIN TEMA:
  Flavor: $CATPPUCCIN_FLAVOR (CATPPUCCIN_FLAVOR env var ile değiştir)
  Accent: $CATPPUCCIN_ACCENT (CATPPUCCIN_ACCENT env var ile değiştir)

LOG DOSYALARI:
  Ana log:   $COSMIC_LOG
  Debug log: $DEBUG_LOG

NOTLAR:
  - COSMIC Beta aşamasındadır, kararsızlık beklenebilir
  - Wayland backend varsayılan olarak kullanılır
  - Intel Arc Graphics tespit edilirse otomatik optimizasyonlar aktif olur
  - Log dosyaları ${MAX_LOG_SIZE} byte üzerinde ise otomatik rotate edilir

EOF
}

# =============================================================================
# Komut Satırı Argüman İşleme
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
		-v | --version)
			echo "$SCRIPT_NAME version $SCRIPT_VERSION"
			exit 0
			;;
		*)
			error "Bilinmeyen argüman: $1"
			;;
		esac
	done
}

# =============================================================================
# Ana Fonksiyon
# =============================================================================

main() {
	parse_arguments "$@"

	debug_log "════════════════════════════════════════════════════════"
	debug_log "Script başlatıldı: $(date)"
	debug_log "Script version: $SCRIPT_VERSION"
	debug_log "Kullanıcı: $USER"
	debug_log "TTY: $(tty 2>/dev/null || echo 'unknown')"
	debug_log "════════════════════════════════════════════════════════"

	if [[ "$DEBUG_MODE" == "true" ]]; then
		set -x
	fi

	print_header "COSMIC TTY LAUNCHER - ThinkPad E14 Gen 6"
	info "Version: $SCRIPT_VERSION"
	info "Başlatma zamanı: $(date '+%Y-%m-%d %H:%M:%S')"
	info "Kullanıcı: $USER | TTY: $(tty 2>/dev/null || echo 'bilinmiyor')"
	info "Catppuccin: $CATPPUCCIN_FLAVOR-$CATPPUCCIN_ACCENT"
	echo

	setup_directories
	rotate_logs
	check_system
	setup_environment
	cleanup_old_processes
	setup_dbus
	setup_systemd_integration
	start_cosmic

	error "Ana fonksiyon beklenmedik şekilde sonlandı!"
}

# =============================================================================
# Script Başlangıcı
# =============================================================================

main "$@"
