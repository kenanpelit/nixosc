#!/usr/bin/env bash
# =============================================================================
# Hyprland TTY Başlatma Script'i - Production Ready
# =============================================================================
# ThinkPad E14 Gen 6 + Intel Arc Graphics + NixOS
# Dinamik Catppuccin tema desteği ile
# =============================================================================
# KULLANIM:
#   hyprland_tty              - Normal başlatma
#   hyprland_tty -d           - Debug modu
#   hyprland_tty --dry-run    - Sadece kontroller, başlatma
# =============================================================================

set -euo pipefail

# =============================================================================
# Sabit Değişkenler
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.0.1"
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
readonly C_RESET='\033[0m'

# Catppuccin flavor ve accent - Environment'tan oku veya varsayılan (READONLY DEĞİL!)
CATPPUCCIN_FLAVOR="${CATPPUCCIN_FLAVOR:-mocha}"
CATPPUCCIN_ACCENT="${CATPPUCCIN_ACCENT:-mauve}"

# Debug modu flag
DEBUG_MODE=false
DRY_RUN=false

# =============================================================================
# Logging Fonksiyonları
# =============================================================================

# Debug log - hem dosyaya hem systemd journal'a yazar
debug_log() {
	local message="$1"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local full_msg="[${timestamp}] [DEBUG] ${message}"

	# Debug modu kapalıysa sadece dosyaya yaz
	if [[ "$DEBUG_MODE" != "true" ]]; then
		echo "$full_msg" >>"$DEBUG_LOG" 2>/dev/null || true
		return
	fi

	# Debug modu açıksa ekrana da bas
	echo -e "${C_CYAN}[DEBUG]${C_RESET} $message" >&2

	# Dosyaya yaz
	echo "$full_msg" >>"$DEBUG_LOG" 2>/dev/null || true

	# TTY'de systemd journal'a da gönder
	if [[ "$(tty 2>/dev/null)" =~ ^/dev/tty[0-9]+$ ]]; then
		logger -t "$SCRIPT_NAME" "DEBUG: $message" 2>/dev/null || true
	fi
}

# Ana log fonksiyonu
log() {
	local level="$1"
	local message="$2"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local log_entry="[${timestamp}] [${level}] ${message}"

	# Log dosyasına yaz
	if [[ -d "$(dirname "$HYPRLAND_LOG")" ]]; then
		echo "$log_entry" >>"$HYPRLAND_LOG" 2>/dev/null || {
			debug_log "Ana log dosyasına yazılamadı: $HYPRLAND_LOG"
		}
	fi

	# Debug log'a da yaz
	debug_log "$message"
}

# Info mesajı
info() {
	local message="$1"
	echo -e "${C_GREEN}[INFO]${C_RESET} $message"
	log "INFO" "$message"
}

# Warning mesajı
warn() {
	local message="$1"
	echo -e "${C_YELLOW}[WARN]${C_RESET} $message" >&2
	log "WARN" "$message"
}

# Error mesajı ve çıkış
error() {
	local message="$1"
	echo -e "${C_RED}[ERROR]${C_RESET} $message" >&2
	log "ERROR" "$message"
	debug_log "FATAL ERROR - Script sonlandırılıyor: $message"
	exit 1
}

# Başlık yazdırma
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
	debug_log "LOG_DIR: $LOG_DIR | HYPRLAND_LOG: $HYPRLAND_LOG"

	# Log dizinini oluştur
	if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
		# Fallback: /tmp kullan
		warn "Log dizini oluşturulamadı: $LOG_DIR, /tmp kullanılıyor"
		LOG_DIR="/tmp/hyprland-logs-$USER"
		HYPRLAND_LOG="$LOG_DIR/hyprland.log"
		DEBUG_LOG="$LOG_DIR/hyprland_debug.log"
		mkdir -p "$LOG_DIR" || error "Hiçbir log dizini oluşturulamadı"
	fi

	# Yazma izni kontrolü
	if [[ ! -w "$LOG_DIR" ]]; then
		error "Log dizinine yazma izni yok: $LOG_DIR"
	fi

	# Log dosyasını oluştur
	touch "$HYPRLAND_LOG" "$DEBUG_LOG" 2>/dev/null || {
		error "Log dosyaları oluşturulamadı"
	}

	debug_log "Log dizini hazır: $LOG_DIR"
}

rotate_logs() {
	debug_log "Log rotasyonu kontrol ediliyor"

	if [[ ! -f "$HYPRLAND_LOG" ]]; then
		debug_log "Ana log dosyası yok, rotasyon gerekmiyor"
		return 0
	fi

	local file_size=$(stat -c%s "$HYPRLAND_LOG" 2>/dev/null || echo 0)
	debug_log "Ana log dosyası boyutu: $file_size bytes"

	# 10MB'den büyükse rotasyon yap
	if [[ $file_size -gt $MAX_LOG_SIZE ]]; then
		info "Log dosyası ${MAX_LOG_SIZE} byte'ı aştı, rotasyon yapılıyor"

		# Eski yedekleri kaydır
		for ((i = $MAX_LOG_BACKUPS; i > 0; i--)); do
			local old_backup="${HYPRLAND_LOG}.old.$((i - 1))"
			local new_backup="${HYPRLAND_LOG}.old.$i"

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

		# Mevcut log'u yedekle
		mv "$HYPRLAND_LOG" "${HYPRLAND_LOG}.old.0"
		debug_log "Mevcut log yedeklendi: ${HYPRLAND_LOG}.old.0"

		# Yeni log dosyası oluştur
		touch "$HYPRLAND_LOG"
		debug_log "Yeni log dosyası oluşturuldu"
	fi
}

# =============================================================================
# Sistem Kontrolleri
# =============================================================================

check_system() {
	debug_log "Sistem kontrolleri başlıyor"

	# XDG_RUNTIME_DIR kontrolü ve ayarı
	if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
		warn "XDG_RUNTIME_DIR ayarlandı: $XDG_RUNTIME_DIR"
	else
		debug_log "XDG_RUNTIME_DIR mevcut: $XDG_RUNTIME_DIR"
	fi

	# XDG_RUNTIME_DIR erişim kontrolü
	if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
		error "XDG_RUNTIME_DIR dizini mevcut değil: $XDG_RUNTIME_DIR"
	fi

	if [[ ! -w "$XDG_RUNTIME_DIR" ]]; then
		error "XDG_RUNTIME_DIR yazılabilir değil: $XDG_RUNTIME_DIR"
	fi

	# TTY kontrolü
	if [[ -z "${XDG_VTNR:-}" ]]; then
		export XDG_VTNR=1
		warn "XDG_VTNR varsayılan değere ayarlandı: 1"
	else
		debug_log "XDG_VTNR: $XDG_VTNR"
	fi

	# Intel Arc Graphics kontrolü ve optimizasyonları
	if lspci 2>/dev/null | grep -qi "arc\|meteor\|alchemist"; then
		info "Intel Arc Graphics tespit edildi"
		debug_log "Intel Arc uyumluluk modları aktifleştiriliyor"

		# Intel Arc için kritik ayarlar
		export WLR_DRM_NO_ATOMIC=1
		export WLR_RENDERER=gles2
		export INTEL_DEBUG=norbc

		info "Intel Arc optimizasyonları aktif"
	else
		debug_log "Intel Arc Graphics tespit edilmedi"
	fi

	# Hyprland binary kontrolü
	if command -v Hyprland &>/dev/null; then
		HYPRLAND_BINARY="Hyprland"
		debug_log "Hyprland binary: Hyprland"
	elif command -v hyprland &>/dev/null; then
		HYPRLAND_BINARY="hyprland"
		debug_log "Hyprland binary: hyprland"
	else
		error "Hyprland binary bulunamadı! PATH: $PATH"
	fi

	# Hyprland version bilgisi
	local hypr_version=$("$HYPRLAND_BINARY" --version 2>&1 | head -n1 || echo "Unknown")
	info "Hyprland version: $hypr_version"

	info "Sistem kontrolleri tamamlandı"
}

# =============================================================================
# Environment Değişkenleri - Catppuccin Dinamik Tema Desteği
# =============================================================================

setup_environment() {
	print_header "ENVIRONMENT AYARLARI - CATPPUCCIN ${CATPPUCCIN_FLAVOR^^}"
	debug_log "Environment değişkenleri ayarlanıyor"

	# -------------------------------------------------------------------------
	# Temel Wayland Ayarları
	# -------------------------------------------------------------------------
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"
	export DESKTOP_SESSION="Hyprland"
	debug_log "Temel Wayland değişkenleri: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP / $DESKTOP_SESSION"

	# -------------------------------------------------------------------------
	# Wayland Backend Tercihleri
	# -------------------------------------------------------------------------
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM="wayland;xcb"
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export CLUTTER_BACKEND=wayland
	export OZONE_PLATFORM=wayland
	export _JAVA_AWT_WM_NONREPARENTING=1
	debug_log "Wayland backend tercihleri ayarlandı"

	# -------------------------------------------------------------------------
	# Catppuccin Dinamik Tema - GTK
	# -------------------------------------------------------------------------
	local gtk_theme="catppuccin-${CATPPUCCIN_FLAVOR}-${CATPPUCCIN_ACCENT}-standard+normal"
	export GTK_THEME="$gtk_theme"
	export GTK_USE_PORTAL=1

	# Light theme kontrolü (latte flavor)
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
	export QT_QPA_PLATFORMTHEME=gtk3
	export QT_STYLE_OVERRIDE=kvantum
	export QT_AUTO_SCREEN_SCALE_FACTOR=1
	debug_log "Qt tema ayarları: gtk3 + kvantum"

	# -------------------------------------------------------------------------
	# Türkçe F-Klavye
	# -------------------------------------------------------------------------
	export XKB_DEFAULT_LAYOUT=tr
	export XKB_DEFAULT_VARIANT=f
	export XKB_DEFAULT_OPTIONS=ctrl:nocaps
	debug_log "Klavye: Türkçe F (ctrl:nocaps)"

	# -------------------------------------------------------------------------
	# Hyprland Özel Ayarları
	# -------------------------------------------------------------------------
	export HYPRLAND_LOG_WLR=1
	export HYPRLAND_NO_RT=1
	export HYPRLAND_NO_SD_NOTIFY=1
	export WLR_LOG=INFO # Log spam önleme
	debug_log "Hyprland daemon ayarları yapıldı"

	# -------------------------------------------------------------------------
	# Varsayılan Uygulamalar
	# -------------------------------------------------------------------------
	export EDITOR=nvim
	export VISUAL=nvim
	export TERMINAL=kitty
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
	# Catppuccin flavor bilgisini ortama kaydet (tekrar export)
	# -------------------------------------------------------------------------
	export CATPPUCCIN_FLAVOR="$CATPPUCCIN_FLAVOR"
	export CATPPUCCIN_ACCENT="$CATPPUCCIN_ACCENT"

	info "Environment ayarları tamamlandı"
	debug_log "Aktif flavor: $CATPPUCCIN_FLAVOR | Accent: $CATPPUCCIN_ACCENT"
}

# =============================================================================
# Eski Hyprland Proseslerini Temizleme
# =============================================================================

cleanup_old_processes() {
	debug_log "Eski Hyprland prosesleri kontrol ediliyor"

	local old_pids=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)

	if [[ -z "$old_pids" ]]; then
		debug_log "Eski Hyprland prosesi bulunamadı"
		return 0
	fi

	warn "Eski Hyprland prosesleri tespit edildi: $old_pids"

	# Dry-run modunda sadece bilgi ver
	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Eski prosesler sonlandırılmayacak"
		return 0
	fi

	# Önce TERM sinyali gönder (zarif sonlandırma)
	info "Eski prosesler zarif şekilde sonlandırılıyor (SIGTERM)..."
	echo "$old_pids" | xargs -r kill -TERM 2>/dev/null || true

	# 2 saniye bekle
	sleep 2

	# Hala çalışıyorlarsa KILL gönder
	local remaining_pids=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)
	if [[ -n "$remaining_pids" ]]; then
		warn "Bazı prosesler hala aktif, zorla sonlandırılıyor (SIGKILL)..."
		echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
		sleep 1
	fi

	debug_log "Eski prosesler temizlendi"
}

# =============================================================================
# Systemd ve DBus Entegrasyonu
# =============================================================================

setup_systemd_integration() {
	print_header "SYSTEMD VE DBUS ENTEGRASYONU"
	debug_log "Systemd entegrasyonu başlatılıyor"

	# Dry-run modunda sadece bilgi ver
	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Systemd entegrasyonu atlanıyor"
		return 0
	fi

	# Systemd user session'a environment değişkenlerini aktar
	local systemd_vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"

	if systemctl --user import-environment $systemd_vars 2>/dev/null; then
		debug_log "Systemd environment import başarılı"
	else
		warn "Systemd environment import başarısız (systemd user session yok olabilir)"
	fi

	# DBus activation environment güncelleme
	local dbus_vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"

	if dbus-update-activation-environment --systemd $dbus_vars 2>/dev/null; then
		debug_log "DBus activation environment güncellendi"
	else
		warn "DBus activation environment güncellenemedi"
	fi

	info "Systemd ve DBus entegrasyonu tamamlandı"
}

# =============================================================================
# Cleanup Fonksiyonu - Script sonlandığında çalışır
# =============================================================================

cleanup() {
	debug_log "Cleanup fonksiyonu tetiklendi"

	info "Hyprland oturumu sonlandırılıyor..."

	# Hyprland proseslerini zarif şekilde sonlandır
	local hypr_pids=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)

	if [[ -n "$hypr_pids" ]]; then
		debug_log "Hyprland prosesleri bulundu: $hypr_pids"

		# SIGTERM gönder
		echo "$hypr_pids" | xargs -r kill -TERM 2>/dev/null || true
		debug_log "SIGTERM gönderildi"

		# 2 saniye bekle
		sleep 2

		# Hala çalışıyorsa SIGKILL
		local remaining=$(pgrep -f "Hyprland\|hyprland" 2>/dev/null || true)
		if [[ -n "$remaining" ]]; then
			warn "Bazı prosesler hala aktif, zorla sonlandırılıyor"
			echo "$remaining" | xargs -r kill -KILL 2>/dev/null || true
		fi
	else
		debug_log "Sonlandırılacak Hyprland prosesi bulunamadı"
	fi

	debug_log "Cleanup tamamlandı"
}

# =============================================================================
# Hyprland Başlatma
# =============================================================================

start_hyprland() {
	print_header "HYPRLAND BAŞLATILIYOR"
	debug_log "Hyprland başlatma fonksiyonu çağrıldı"

	# Dry-run modunda çıkış yap
	if [[ "$DRY_RUN" == "true" ]]; then
		info "[DRY-RUN] Hyprland başlatılmayacak"
		info "[DRY-RUN] Tüm kontroller başarılı, normal modda çalıştırabilirsiniz"
		exit 0
	fi

	# Cleanup trap'i ayarla
	trap cleanup EXIT TERM INT HUP
	debug_log "Signal trap'leri ayarlandı (EXIT TERM INT HUP)"

	# Son kontroller
	debug_log "Son kontroller yapılıyor"
	debug_log "HYPRLAND_BINARY: $HYPRLAND_BINARY"
	debug_log "Log dosyası: $HYPRLAND_LOG"
	debug_log "Log dosyası yazılabilir: $(test -w "$HYPRLAND_LOG" && echo 'EVET' || echo 'HAYIR')"
	debug_log "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"
	debug_log "Tema: GTK=$GTK_THEME | Cursor=$XCURSOR_THEME"

	# Bilgilendirme
	info "═══════════════════════════════════════════════════════════"
	info "Hyprland başlatılıyor..."
	info "Binary: $HYPRLAND_BINARY"
	info "Flavor: $CATPPUCCIN_FLAVOR | Accent: $CATPPUCCIN_ACCENT"
	info "Log: $HYPRLAND_LOG"
	info "═══════════════════════════════════════════════════════════"

	# Hyprland'i başlat - stdout ve stderr'i log dosyasına yönlendir
	debug_log "exec $HYPRLAND_BINARY komutu çalıştırılıyor"

	# exec ile script'i tamamen Hyprland ile değiştir
	exec "$HYPRLAND_BINARY" >>"$HYPRLAND_LOG" 2>&1

	# Bu satıra hiç ulaşılmamalı (exec başarılıysa)
	error "Hyprland exec başarısız oldu!"
}

# =============================================================================
# Yardım Mesajı
# =============================================================================

show_help() {
	cat <<EOF
╔════════════════════════════════════════════════════════════╗
║  Hyprland TTY Launcher v${SCRIPT_VERSION}                        ║
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

  Kullanılabilir flavor'lar: latte, frappe, macchiato, mocha
  Kullanılabilir accent'ler: rosewater, flamingo, pink, mauve, red,
                             maroon, peach, yellow, green, teal,
                             sky, sapphire, blue, lavender

LOG DOSYALARI:
  Ana log:   $HYPRLAND_LOG
  Debug log: $DEBUG_LOG

NOTLAR:
  - Intel Arc Graphics tespit edilirse otomatik optimizasyonlar aktif olur
  - Log dosyaları ${MAX_LOG_SIZE} byte üzerinde ise otomatik rotate edilir
  - Son ${MAX_LOG_BACKUPS} log yedeklenir

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
			info "Dry-run modu aktif (sadece kontroller)"
			shift
			;;
		-v | --version)
			echo "$SCRIPT_NAME version $SCRIPT_VERSION"
			exit 0
			;;
		*)
			error "Bilinmeyen argüman: $1 (yardım için --help kullanın)"
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

	# Debug başlangıç mesajları
	debug_log "════════════════════════════════════════════════════════"
	debug_log "Script başlatıldı: $(date)"
	debug_log "Script version: $SCRIPT_VERSION"
	debug_log "Kullanıcı: $USER"
	debug_log "Home: $HOME"
	debug_log "PWD: $(pwd)"
	debug_log "TTY: $(tty 2>/dev/null || echo 'unknown')"
	debug_log "Args: $*"
	debug_log "Debug mode: $DEBUG_MODE | Dry-run: $DRY_RUN"
	debug_log "════════════════════════════════════════════════════════"

	# Bash debug modu (sadece --debug ile)
	if [[ "$DEBUG_MODE" == "true" ]]; then
		set -x
	fi

	# Başlık
	print_header "HYPRLAND TTY LAUNCHER - ThinkPad E14 Gen 6"
	info "Version: $SCRIPT_VERSION"
	info "Başlatma zamanı: $(date '+%Y-%m-%d %H:%M:%S')"
	info "Kullanıcı: $USER | TTY: $(tty 2>/dev/null || echo 'bilinmiyor')"
	info "Catppuccin: $CATPPUCCIN_FLAVOR-$CATPPUCCIN_ACCENT"
	echo

	# Ana işlem adımları - sırayla
	setup_directories
	rotate_logs
	check_system
	setup_environment
	cleanup_old_processes
	setup_systemd_integration
	start_hyprland

	# Bu satıra hiç ulaşılmamalı (start_hyprland exec kullanıyor)
	error "Ana fonksiyon beklenmedik şekilde sonlandı!"
}

# =============================================================================
# Script Başlangıcı
# =============================================================================

# Script'i çalıştır
main "$@"
