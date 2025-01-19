#!/usr/bin/env bash
# =================================================================
# Çoklu Masaüstü Oturumu Başlatma Yöneticisi
# =================================================================
# Amaç:
# Farklı TTY'lerde farklı masaüstü ortamlarını yönetmek
#
# Oturum Dağılımı:
# TTY1: Hyprland
# TTY2: QEMU Sanal Makine
# TTY5: GNOME masaüstü ortamı
# TTY6: Cosmic masaüstü ortamı
# =================================================================
# Sabit değişkenler
readonly LOG_DIR="$HOME/.log"
readonly CONFIG_DIR="$HOME/.config"
readonly STARTUP_LOG="$LOG_DIR/startup-manager.log"
# Vconsole yapılandırması
readonly VCONSOLE_CONFIG="# Written by systemd-localed(8) or systemd-firstboot(1)
FONT=ter-v20b
KEYMAP=trf
XKBLAYOUT=tr
XKBVARIANT=f
XKBOPTIONS=ctrl:nocaps"
# Renk kodları
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color
# Helper fonksiyonlar
log() {
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${timestamp} [${level}] ${message}" >>"$STARTUP_LOG"
}
info() {
  echo -e "${GREEN}[INFO]${NC} $1"
  log "INFO" "$1"
}
warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  log "WARN" "$1"
}
error() {
  echo -e "${RED}[ERROR]${NC} $1"
  log "ERROR" "$1"
  exit 1
}
# Sistem hazırlık fonksiyonları
setup_directories() {
  mkdir -p "$LOG_DIR" || error "Log dizini oluşturulamadı"
}
# Oturum başlatma fonksiyonları
start_hyprland() {
  info "Hyprland başlatılıyor (TTY1)..."
  exec "$CONFIG_DIR/hypr/start/hyprland_tty.sh" >>"$LOG_DIR/hyprland_tty.log" 2>&1
}
start_qemu() {
  info "QEMU başlatılıyor (TTY2)..."
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  exec sway -c "$CONFIG_DIR/sway/qemu-config" >>"$LOG_DIR/qemu-session.log" 2>&1
}
start_gnome() {
  info "GNOME başlatılıyor (TTY5)..."
  # GNOME için gerekli ortam değişkenleri
  export XDG_SESSION_TYPE=wayland
  export XDG_SESSION_DESKTOP=gnome
  export XDG_CURRENT_DESKTOP=GNOME
  export DESKTOP_SESSION=gnome
  # DBus ve systemd entegrasyonu
  dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP
  systemctl --user import-environment XDG_CURRENT_DESKTOP
  # GNOME oturumunu başlat
  exec gnome-session >>"$LOG_DIR/gnome-session.log" 2>&1
}
start_cosmic() {
  info "Cosmic başlatılıyor (TTY6)..."
  exec cosmic-session >>"$LOG_DIR/cosmic-session.log" 2>&1 &
  echo "$VCONSOLE_CONFIG" | sudo tee /etc/vconsole.conf >/dev/null
}
# Ana fonksiyon
main() {
  setup_directories
  # TTY kontrolü
  case "${XDG_VTNR}" in
  1) start_hyprland ;;
  2) start_qemu ;;
  5) start_gnome ;;
  6) start_cosmic ;;
  *)
    error "TTY${XDG_VTNR} için yapılandırılmış masaüstü oturumu bulunmuyor"
    ;;
  esac
}
# Scripti çalıştır
main "$@"
