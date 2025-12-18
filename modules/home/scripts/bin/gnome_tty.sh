#!/usr/bin/env bash
# =============================================================================
# GNOME TTY Başlatma Script'i - Production Ready v2.0
# =============================================================================
# ThinkPad E14 Gen 6 + Intel Arc Graphics + NixOS
# Dinamik Catppuccin tema desteği ile
# Hem GDM hem TTY başlatmayı destekler
# =============================================================================
# KULLANIM:
#   gnome_tty              - Normal başlatma
#   gnome_tty -d           - Debug modu
#   gnome_tty --dry-run    - Sadece kontroller, başlatma yok
#   gnome_tty --systemd    - Systemd kullanarak başlat (önerilen)
# =============================================================================

set -euo pipefail

# =============================================================================
# Sabit Değişkenler
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.1.0-gdm-aware"
readonly LOG_DIR="$HOME/.logs"
readonly GNOME_LOG="$LOG_DIR/gnome.log"
readonly DEBUG_LOG="$LOG_DIR/gnome_debug.log"
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

# Script modları
DEBUG_MODE=false
DRY_RUN=false
USE_SYSTEMD=false
GDM_MODE=false
FORCE_TTY_MODE=false

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

  if [[ -d "$(dirname "$GNOME_LOG")" ]]; then
    echo "$log_entry" >>"$GNOME_LOG" 2>/dev/null || {
      debug_log "Ana log dosyasına yazılamadı: $GNOME_LOG"
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

print_box() {
  local text="$1"
  local color="${2:-$C_MAGENTA}"
  echo -e "${color}┌────────────────────────────────────────────────────────────┐${C_RESET}"
  echo -e "${color}│  ${text}${C_RESET}"
  echo -e "${color}└────────────────────────────────────────────────────────────┘${C_RESET}"
}

# =============================================================================
# Dizin ve Log Yönetimi
# =============================================================================

setup_directories() {
  debug_log "setup_directories başlatılıyor"
  debug_log "LOG_DIR: $LOG_DIR | GNOME_LOG: $GNOME_LOG"

  if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    warn "Log dizini oluşturulamadı: $LOG_DIR, /tmp kullanılıyor"
    LOG_DIR="/tmp/gnome-logs-$USER"
    GNOME_LOG="$LOG_DIR/gnome.log"
    DEBUG_LOG="$LOG_DIR/gnome_debug.log"
    mkdir -p "$LOG_DIR" || error "Hiçbir log dizini oluşturulamadı"
  fi

  if [[ ! -w "$LOG_DIR" ]]; then
    error "Log dizinine yazma izni yok: $LOG_DIR"
  fi

  touch "$GNOME_LOG" "$DEBUG_LOG" 2>/dev/null || {
    error "Log dosyaları oluşturulamadı"
  }

  debug_log "Log dizini hazır: $LOG_DIR"
}

rotate_logs() {
  debug_log "Log rotasyonu kontrol ediliyor"

  if [[ ! -f "$GNOME_LOG" ]]; then
    debug_log "Ana log dosyası yok, rotasyon gerekmiyor"
    return 0
  fi

  local file_size=$(stat -c%s "$GNOME_LOG" 2>/dev/null || echo 0)
  debug_log "Ana log dosyası boyutu: $file_size bytes"

  if [[ $file_size -gt $MAX_LOG_SIZE ]]; then
    info "Log dosyası ${MAX_LOG_SIZE} byte'ı aştı, rotasyon yapılıyor"

    for ((i = $MAX_LOG_BACKUPS; i > 0; i--)); do
      local old_backup="${GNOME_LOG}.old.$((i - 1))"
      local new_backup="${GNOME_LOG}.old.$i"

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

    mv "$GNOME_LOG" "${GNOME_LOG}.old.0"
    touch "$GNOME_LOG"
    debug_log "Log rotasyonu tamamlandı"
  fi
}

# =============================================================================
# Sistem Kontrolleri
# =============================================================================

check_system() {
  debug_log "Sistem kontrolleri başlıyor"

  # CRITICAL: Ensure systemd isn't forced into offline mode.
  # If SYSTEMD_OFFLINE=1, `systemctl --user` calls can fail and TTY auto-start
  # (this script is exec'd from .zprofile) will bounce back to the login prompt.
  export SYSTEMD_OFFLINE=0

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
  local current_tty=$(tty 2>/dev/null || echo "unknown")
  debug_log "Current TTY: $current_tty"

  if [[ -z "${XDG_VTNR:-}" ]]; then
    # TTY numarasını otomatik tespit et
    if [[ "$current_tty" =~ /dev/tty([0-9]+) ]]; then
      export XDG_VTNR="${BASH_REMATCH[1]}"
      info "XDG_VTNR otomatik tespit edildi: $XDG_VTNR"
    else
      export XDG_VTNR=3
      warn "XDG_VTNR varsayılan değere ayarlandı: 3"
    fi
  else
    debug_log "XDG_VTNR: $XDG_VTNR"
  fi

  # GNOME binary kontrolü
  if ! command -v gnome-session &>/dev/null; then
    error "gnome-session binary bulunamadı! PATH: $PATH"
  fi

  if ! command -v gnome-shell &>/dev/null; then
    error "gnome-shell binary bulunamadı! PATH: $PATH"
  fi

  # GNOME version bilgisi
  local gnome_version=$(gnome-shell --version 2>/dev/null || echo "Unknown")
  info "GNOME Shell: $gnome_version"

  # Systemd user instance kontrolü
  if ! systemctl --user is-system-running &>/dev/null; then
    warn "Systemd user session çalışmıyor, başlatılıyor..."
    if systemctl --user start default.target 2>/dev/null; then
      info "✓ Systemd user session başlatıldı"
      sleep 2
    else
      error "Systemd user session başlatılamadı"
    fi
  fi

  info "Sistem kontrolleri tamamlandı"
}

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
# Session Detection - GDM vs TTY (Legacy, deprecated)
# =============================================================================

detect_session_type() {
  local session_type="tty"

  # 1. GDMSESSION environment variable
  if [[ -n "${GDMSESSION:-}" ]]; then
    debug_log "GDMSESSION bulundu: $GDMSESSION"
    session_type="gdm"
  # 2. Parent process check
  elif pstree -s $$ 2>/dev/null | grep -q "gdm-wayland-session\|gdm-x-session"; then
    debug_log "Parent process GDM (pstree check)"
    session_type="gdm"
  # 3. XDG_SESSION_CLASS check (GDM sets this to 'user')
  elif [[ "${XDG_SESSION_CLASS:-}" == "user" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    debug_log "XDG_SESSION_CLASS=user ve display var, GDM olabilir"
    session_type="gdm"
  fi

  echo "$session_type"
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
  unset HYPRLAND_CMD

  # Sway kalıntıları
  unset SWAYSOCK
  unset I3SOCK

  # Genel temizlik
  unset XDG_CURRENT_DESKTOP
  unset XDG_SESSION_DESKTOP
  unset DESKTOP_SESSION

  debug_log "Environment temizliği tamamlandı"
}

# =============================================================================
# Environment Değişkenleri - GNOME Özel
# =============================================================================

setup_environment() {
  print_header "GNOME ENVIRONMENT AYARLARI - CATPPUCCIN ${CATPPUCCIN_FLAVOR^^}"
  debug_log "Environment değişkenleri ayarlanıyor"

  # Environment temizliği
  cleanup_environment

  # -------------------------------------------------------------------------
  # Temel Wayland ve GNOME Ayarları
  # -------------------------------------------------------------------------
  export XDG_SESSION_TYPE="wayland"
  export XDG_SESSION_DESKTOP="gnome"
  export XDG_CURRENT_DESKTOP="GNOME"
  export DESKTOP_SESSION="gnome"
  export XDG_SESSION_CLASS="user"
  export XDG_SEAT="seat0"
  debug_log "Temel GNOME değişkenleri: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"

  # -------------------------------------------------------------------------
  # Wayland Backend Tercihleri
  # -------------------------------------------------------------------------
  # export WAYLAND_DISPLAY=wayland-0  <-- REMOVED: Compositor sets this!
  export MOZ_ENABLE_WAYLAND=1
  export QT_QPA_PLATFORM="wayland;xcb"
  export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
  export GDK_BACKEND=wayland
  export SDL_VIDEODRIVER=wayland
  export CLUTTER_BACKEND=wayland
  export _JAVA_AWT_WM_NONREPARENTING=1
  debug_log "Wayland backend tercihleri ayarlandı"

  # -------------------------------------------------------------------------
  # GNOME Shell Ayarları
  # -------------------------------------------------------------------------
  export GNOME_SHELL_SESSION_MODE=user

  # Intel Arc uyumluluğu için atomic modesetting kapalı
  export MUTTER_DEBUG_ENABLE_ATOMIC_KMS=0

  # GNOME debug/verbose ayarları kapalı (crash'i önlemek için)
  unset G_DEBUG
  unset G_MESSAGES_DEBUG

  debug_log "GNOME Shell ayarları yapıldı (G_DEBUG temizlendi)"

  # -------------------------------------------------------------------------
  # Catppuccin Dinamik Tema - GTK
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
  export QT_QPA_PLATFORMTHEME=gnome
  export QT_STYLE_OVERRIDE=adwaita
  export QT_AUTO_SCREEN_SCALE_FACTOR=1
  debug_log "Qt tema ayarları: gnome + adwaita"

  # -------------------------------------------------------------------------
  # Türkçe F-Klavye
  # -------------------------------------------------------------------------
  export XKB_DEFAULT_LAYOUT=tr
  export XKB_DEFAULT_VARIANT=f
  export XKB_DEFAULT_OPTIONS=ctrl:nocaps
  debug_log "Klavye: Türkçe F (ctrl:nocaps)"

  # -------------------------------------------------------------------------
  # GNOME Keyring
  # -------------------------------------------------------------------------
  export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
  debug_log "GNOME Keyring ayarları yapıldı"

  # -------------------------------------------------------------------------
  # Varsayılan Uygulamalar
  # -------------------------------------------------------------------------
  export EDITOR=nvim
  export VISUAL=nvim
  export TERMINAL=gnome-terminal
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
}

# =============================================================================
# Eski GNOME Proseslerini Temizleme
# =============================================================================

cleanup_old_processes() {
  debug_log "Eski GNOME prosesleri kontrol ediliyor"

  local old_pids=$(pgrep -u "$(id -u)" -f "gnome-session|gnome-shell" 2>/dev/null || true)

  if [[ -z "$old_pids" ]]; then
    debug_log "Eski GNOME prosesi bulunamadı"
    return 0
  fi

  warn "Eski GNOME prosesleri tespit edildi: $old_pids"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Eski prosesler sonlandırılmayacak"
    return 0
  fi

  info "Eski prosesler zarif şekilde sonlandırılıyor (SIGTERM)..."
  echo "$old_pids" | xargs -r kill -TERM 2>/dev/null || true
  sleep 2

  local remaining_pids=$(pgrep -u "$(id -u)" -f "gnome-session|gnome-shell" 2>/dev/null || true)
  if [[ -n "$remaining_pids" ]]; then
    warn "Bazı prosesler hala aktif, zorla sonlandırılıyor (SIGKILL)..."
    echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
    sleep 1
  fi

  debug_log "Eski prosesler temizlendi"
}

# =============================================================================
# D-Bus Session Başlatma - GDM-Aware
# =============================================================================

setup_dbus() {
  print_header "D-BUS SESSION BAŞLATMA"
  debug_log "D-Bus kontrolü başlatılıyor"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] D-Bus başlatma atlanıyor"
    return 0
  fi

  local session_type=$(detect_session_type)
  info "Session type: $session_type"

  # -------------------------------------------------------------------------
  # GDM Session - Mevcut D-Bus'ı kullan
  # -------------------------------------------------------------------------
  if [[ "$session_type" == "gdm" ]]; then
    debug_log "GDM tarafından başlatıldık, mevcut D-Bus kullanılacak"

    # Zaten set edilmiş mi?
    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
      info "GDM D-Bus zaten ayarlı: $DBUS_SESSION_BUS_ADDRESS"
      return 0
    fi

    # systemd environment'dan al
    local systemd_dbus=$(systemctl --user show-environment 2>/dev/null | grep ^DBUS_SESSION_BUS_ADDRESS= | cut -d= -f2-)
    if [[ -n "$systemd_dbus" ]]; then
      export DBUS_SESSION_BUS_ADDRESS="$systemd_dbus"
      info "GDM D-Bus session bulundu: $DBUS_SESSION_BUS_ADDRESS"
      return 0
    fi

    # Systemd user bus socket
    local user_bus="$XDG_RUNTIME_DIR/bus"
    if [[ -S "$user_bus" ]]; then
      export DBUS_SESSION_BUS_ADDRESS="unix:path=$user_bus"
      info "GDM D-Bus socket bulundu: $user_bus"
      return 0
    fi

    warn "GDM session algılandı ama D-Bus bulunamadı, GNOME kendi başlatacak"
    return 0
  fi

  # -------------------------------------------------------------------------
  # TTY Session - D-Bus Setup
  # -------------------------------------------------------------------------
  debug_log "TTY'den manuel başlatma tespit edildi"

  # CRITICAL: Always use systemd user bus for proper systemd integration
  # GNOME requires access to org.freedesktop.systemd1 over D-Bus
  local user_bus="$XDG_RUNTIME_DIR/bus"

  if [[ -S "$user_bus" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$user_bus"
    info "Systemd user bus kullanılıyor: $user_bus"

    # Verify systemd is accessible via D-Bus
    if dbus-send --session --print-reply --dest=org.freedesktop.systemd1 \
      /org/freedesktop/systemd1 org.freedesktop.DBus.Peer.Ping &>/dev/null; then
      info "✓ Systemd user manager D-Bus üzerinden erişilebilir"
    else
      warn "⚠ Systemd user manager D-Bus üzerinden erişilemiyor"
    fi
    return 0
  else
    error "Systemd user bus socket bulunamadı: $user_bus\nGNOME systemd user session gerektirir!"
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

  # Önemli environment variable'lar
  local systemd_vars=(
    "WAYLAND_DISPLAY"
    "DISPLAY"
    "XDG_CURRENT_DESKTOP"
    "XDG_SESSION_TYPE"
    "XDG_SESSION_DESKTOP"
    "DBUS_SESSION_BUS_ADDRESS"
    "GNOME_KEYRING_CONTROL"
    "SSH_AUTH_SOCK"
  )

  # Systemd user environment'a import et
  if systemctl --user import-environment "${systemd_vars[@]}" 2>/dev/null; then
    debug_log "Systemd environment import başarılı"
  else
    warn "Systemd environment import başarısız"
  fi

  # D-Bus activation environment güncelle
  if dbus-update-activation-environment --systemd "${systemd_vars[@]}" 2>/dev/null; then
    debug_log "D-Bus activation environment güncellendi"
  else
    warn "D-Bus activation environment güncellenemedi"
  fi

  info "Systemd entegrasyonu tamamlandı"
}

# =============================================================================
# GNOME Keyring Başlatma
# =============================================================================

start_gnome_keyring() {
  debug_log "GNOME Keyring başlatılıyor"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Keyring başlatma atlanıyor"
    return 0
  fi

  local session_type=$(detect_session_type)

  # GDM zaten keyring başlatmış olabilir
  if [[ "$session_type" == "gdm" ]]; then
    debug_log "GDM session - keyring kontrol ediliyor"
    if pgrep -u "$(id -u)" gnome-keyring-daemon >/dev/null 2>&1; then
      info "GNOME Keyring zaten çalışıyor (GDM tarafından)"
      return 0
    fi
  fi

  # Keyring binary kontrolü
  if ! command -v gnome-keyring-daemon &>/dev/null; then
    warn "gnome-keyring-daemon bulunamadı, atlanıyor"
    return 0
  fi

  info "GNOME Keyring başlatılıyor..."

  # Keyring başlat
  eval $(gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 2>/dev/null || true)

  export GNOME_KEYRING_CONTROL
  export SSH_AUTH_SOCK

  if [[ -n "${GNOME_KEYRING_CONTROL:-}" ]]; then
    info "Keyring başarıyla başlatıldı: $GNOME_KEYRING_CONTROL"
  else
    warn "Keyring başlatılamadı"
  fi
}

# =============================================================================
# Cleanup Fonksiyonu
# =============================================================================

cleanup() {
  debug_log "Cleanup fonksiyonu tetiklendi"
  info "GNOME oturumu sonlandırılıyor..."

  local gnome_pids=$(pgrep -u "$(id -u)" -f "gnome-session|gnome-shell" 2>/dev/null || true)

  if [[ -n "$gnome_pids" ]]; then
    debug_log "GNOME prosesleri bulundu: $gnome_pids"
    echo "$gnome_pids" | xargs -r kill -TERM 2>/dev/null || true
    sleep 2

    local remaining=$(pgrep -u "$(id -u)" -f "gnome-session|gnome-shell" 2>/dev/null || true)
    if [[ -n "$remaining" ]]; then
      warn "Bazı prosesler hala aktif, zorla sonlandırılıyor"
      echo "$remaining" | xargs -r kill -KILL 2>/dev/null || true
    fi
  fi

  debug_log "Cleanup tamamlandı"
}

# =============================================================================
# GNOME Başlatma - Systemd ile
# =============================================================================

start_gnome_with_systemd() {
  print_header "GNOME BAŞLATILIYOR (SYSTEMD)"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] GNOME başlatılmayacak"
    return 0
  fi

  info "═══════════════════════════════════════════════════════════"
  info "GNOME başlatılıyor (systemd mode)..."
  info "Session: gnome"
  info "Flavor: $CATPPUCCIN_FLAVOR | Accent: $CATPPUCCIN_ACCENT"
  info "Log: $GNOME_LOG"
  info "═══════════════════════════════════════════════════════════"

  # CRITICAL FIX: Don't use gnome-session-wayland@gnome.target
  # This template unit is for systemd user session integration, not direct launch
  # Instead, exec gnome-session directly like in direct mode

  # Wait for systemd user session to be ready
  local max_wait=10
  local wait_count=0
  while ! systemctl --user is-active --quiet default.target 2>/dev/null; do
    if [[ $wait_count -ge $max_wait ]]; then
      error "Systemd user session not active after ${max_wait}s!"
    fi
    debug_log "Waiting for systemd user session... ($wait_count/$max_wait)"
    sleep 1
    ((wait_count++))
  done

  info "✓ Systemd user session is active"

  # Export environment to systemd before starting GNOME
  systemctl --user import-environment \
    GNOME_KEYRING_CONTROL SSH_AUTH_SOCK \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
    XDG_SESSION_DESKTOP DBUS_SESSION_BUS_ADDRESS 2>/dev/null || true

  # Start GNOME session directly (let it manage systemd targets)
  info "Starting gnome-session..."
  exec gnome-session --session=gnome --no-reexec 2>&1 | tee -a "$GNOME_LOG"
}

# =============================================================================
# GNOME Başlatma - Direct (exec)
# =============================================================================

start_gnome_direct() {
  print_header "GNOME BAŞLATILIYOR (DIRECT)"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] GNOME başlatılmayacak"
    exit 0
  fi

  trap cleanup EXIT TERM INT HUP
  : >"$GNOME_LOG"

  info "═══════════════════════════════════════════════════════════"
  info "GNOME başlatılıyor (direct mode)..."
  info "Session: gnome"
  info "Flavor: $CATPPUCCIN_FLAVOR | Accent: $CATPPUCCIN_ACCENT"
  info "Log: $GNOME_LOG"
  info "═══════════════════════════════════════════════════════════"

  # CRITICAL FIX: Enforce SYSTEMD_OFFLINE=0 globally
  # Explicitly enabled for both GDM and TTY modes to ensure the script
  # can reliably interact with the systemd user session without conflicts.
  export SYSTEMD_OFFLINE=0
  debug_log "✓ SYSTEMD_OFFLINE=0 her zaman ayarlı (GDM veya TTY modu)"

  # Wait for systemd user session to be ready
  local max_wait=10
  local wait_count=0
  while ! systemctl --user is-active --quiet default.target 2>/dev/null; do
    if [[ $wait_count -ge $max_wait ]]; then
      error "Systemd user session not active after ${max_wait}s! GNOME requires systemd user services to be running."
    fi
    debug_log "Waiting for systemd user session... ($wait_count/$max_wait)"
    sleep 1
    ((wait_count++))
  done

  info "✓ Systemd user session is active"

  # Son environment export
  systemctl --user import-environment \
    GNOME_KEYRING_CONTROL SSH_AUTH_SOCK \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE \
    XDG_SESSION_DESKTOP 2>/dev/null || true

  # GNOME komutunu hazırla
  # NOTE: Use systemd user bus instead of dbus-run-session
  # dbus-run-session creates an isolated D-Bus session, preventing systemd integration
  # IMPORTANT:
  # By default gnome-session may "re-exec into a login shell" during startup.
  # When GNOME is launched from TTY via `.zprofile`, that re-exec can re-trigger
  # the TTY auto-start logic and cause an immediate bounce back to the login prompt.
  # `--no-reexec` disables that behavior and avoids recursion.
  local cmd="gnome-session --session=gnome --no-reexec"

  if [[ "$DEBUG_MODE" == "true" ]]; then
    # Shell tracing'i kapat (temiz çıktı için)
    set +x

    cmd="$cmd --debug"

    info "DEBUG MODE: Çıktılar hem ekrana hem log dosyasına yazılıyor..."
    info "Komut: $cmd"

    # Output redirect (unbuffered tee ile)
    # stdbuf -o0 -e0 ile anlık yazmayı garantiye alıyoruz
    exec > >(stdbuf -o0 -e0 tee -a "$GNOME_LOG") 2>&1
  else
    info "GNOME session exec ediliyor..."
    exec >>"$GNOME_LOG" 2>&1
  fi

  # GNOME başlat
  exec $cmd
}

# =============================================================================
# Yardım Mesajı
# =============================================================================

show_help() {
  cat <<EOF
╔════════════════════════════════════════════════════════════╗
║  GNOME TTY Launcher v${SCRIPT_VERSION}                           ║
╚════════════════════════════════════════════════════════════╝

KULLANIM:
  $SCRIPT_NAME [SEÇENEKLER]

SEÇENEKLER:
  -h, --help       Bu yardımı göster
  -d, --debug      Debug modu (detaylı log)
  --dry-run        Sadece kontroller, başlatma yapma
  --systemd        Systemd ile başlat (önerilen)
  -v, --version    Version bilgisini göster

ÖRNEKLER:
  $SCRIPT_NAME                # Normal başlatma (direct)
  $SCRIPT_NAME --systemd      # Systemd ile başlatma (önerilen)
  $SCRIPT_NAME -d             # Debug modu ile
  $SCRIPT_NAME --dry-run      # Sadece test et

CATPPUCCIN TEMA:
  Flavor: $CATPPUCCIN_FLAVOR (CATPPUCCIN_FLAVOR env var ile değiştir)
  Accent: $CATPPUCCIN_ACCENT (CATPPUCCIN_ACCENT env var ile değiştir)

SESSION DETECTION:
  - GDM'den başlatılırsa: Mevcut D-Bus kullanılır
  - TTY'den başlatılırsa: Yeni D-Bus session oluşturulur

LOG DOSYALARI:
  Ana log:   $GNOME_LOG
  Debug log: $DEBUG_LOG

NOTLAR:
  - Wayland backend varsayılan olarak kullanılır
  - G_DEBUG otomatik temizlenir (crash'i önlemek için)
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
      info "Dry-run modu aktif"
      shift
      ;;
    --systemd)
      USE_SYSTEMD=true
      info "Systemd modu aktif"
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

  # Ensure we can talk to systemd user manager in all cases.
  export SYSTEMD_OFFLINE=0

  # GDM detection (en başta!)
  detect_gdm_session

  debug_log "════════════════════════════════════════════════════════"
  debug_log "Script başlatıldı: $(date)"
  debug_log "Script version: $SCRIPT_VERSION"
  debug_log "Kullanıcı: $USER"
  debug_log "TTY: $(tty 2>/dev/null || echo 'unknown')"
  debug_log "PID: $$"
  debug_log "GDM_MODE: $GDM_MODE | DEBUG: $DEBUG_MODE | DRY_RUN: $DRY_RUN"
  debug_log "GDMSESSION: ${GDMSESSION:-unset}"
  debug_log "XDG_SESSION_CLASS: ${XDG_SESSION_CLASS:-unset}"
  debug_log "DBUS_SESSION_BUS_ADDRESS: ${DBUS_SESSION_BUS_ADDRESS:-unset}"
  debug_log "════════════════════════════════════════════════════════"

  if [[ "$DEBUG_MODE" == "true" ]]; then
    set -x
  fi

  print_header "GNOME TTY LAUNCHER - ThinkPad E14 Gen 6"
  info "Version: $SCRIPT_VERSION"
  info "Başlatma zamanı: $(date '+%Y-%m-%d %H:%M:%S')"
  info "Kullanıcı: $USER | TTY: $(tty 2>/dev/null || echo 'bilinmiyor')"
  info "Catppuccin: $CATPPUCCIN_FLAVOR-$CATPPUCCIN_ACCENT"
  info "Mode: $([ "$GDM_MODE" == "true" ] && echo "GDM Session" || echo "TTY Direct")"

  local session_type=$(detect_session_type)
  print_box "Session Type: ${session_type^^} (GDM_MODE=$GDM_MODE)" "$C_MAGENTA"
  echo

  setup_directories
  rotate_logs
  check_system
  setup_environment
  cleanup_old_processes
  setup_dbus
  start_gnome_keyring
  setup_systemd_integration

  # Başlatma modu seçimi
  # CRITICAL FIX: Always use direct mode regardless of flag
  # The "systemd mode" was broken because gnome-session-wayland@gnome.target
  # is a template unit that expects to be started by GDM, not manually
  # Direct mode properly integrates with systemd user session
  start_gnome_direct

  error "Ana fonksiyon beklenmedik şekilde sonlandı!"
}

# =============================================================================
# Script Başlangıcı
# =============================================================================

main "$@"
