#!/usr/bin/env bash

#===============================================================================
#
#   Version: 1.1.0
#   Date: 2024-12-20
#   Author: Kenan Pelit
#   Description: HyprFlow Start Manager - Enhanced Terminal Support
#
#   License: MIT
#
#===============================================================================

VERSION="1.1.0"
SCRIPT_NAME=$(basename "$0")

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Terminal emülatör yapılandırmaları
declare -A TERMINAL_CONFIGS=(
  [foot]="--class {class} --title {title}"
  [kitty]="--class {class} --title {title}"
  [alacritty]="--class {class} --title {title}"
)

# Hata durumunda çıkış yapacak fonksiyon
exit_with_error() {
  notify-send -u critical -t 5000 "Hata" "$1"
  echo -e "${RED}Hata: $1${NC}"
  exit 1
}

# Başarı mesajı gösteren fonksiyon
show_success() {
  echo -e "${GREEN}$1${NC}"
  notify-send -t 2000 "Başarılı" "$1"
}

# Uygulama kontrolü yapan fonksiyon
check_application() {
  if ! command -v "$1" &>/dev/null; then
    exit_with_error "$1 uygulaması bulunamadı."
  fi
}

# Hyprland pencere kontrolü yapan fonksiyon
check_window() {
  local target_class="$1"
  local window_info

  window_info=$(hyprctl -j clients | jq -r ".[] | select(.class == \"$target_class\")")

  if [[ -n "$window_info" ]]; then
    hyprctl dispatch focuswindow "class:$target_class"
    notify-send "$target_class" "$target_class penceresine odaklanıldı."
    return 0
  fi
  return 1
}

# Süreç kontrolü yapan fonksiyon
check_process() {
  if pgrep -x "$1" >/dev/null; then
    return 0
  fi
  return 1
}

# Terminal uygulamaları başlatma fonksiyonları
start_foot() {
  check_application "foot"
  notify-send -t 1000 "Foot Terminal" "Foot terminal başlatılıyor..."
  foot >>/dev/null 2>&1 &
  disown
}

start_kitty() {
  check_application "kitty"
  notify-send -t 1000 "Kitty Terminal" "Kitty terminal başlatılıyor..."
  kitty >>/dev/null 2>&1 &
  disown
}

start_alacritty() {
  check_application "alacritty"
  notify-send -t 1000 "Alacritty Terminal" "Alacritty terminal başlatılıyor..."
  alacritty >>/dev/null 2>&1 &
  disown
}

start_yazi() {
  check_application "yazi"
  local terminal="${1:-foot}"
  local TMP_FILE
  TMP_FILE="$(mktemp -t yazi-cwd.XXXXX)"

  if ! command -v "$terminal" &>/dev/null; then
    exit_with_error "$terminal terminal bulunamadı."
  fi

  if ! command -v zoxide &>/dev/null; then
    exit_with_error "Zoxide bulunamadı. Lütfen yükleyin."
  fi

  notify-send -t 1000 "Yazi" "Yazi dosya yöneticisi $terminal ile başlatılıyor..."

  # Cleanup function for temporary file
  cleanup() {
    rm -f "$TMP_FILE"
  }
  trap cleanup EXIT

  # Get zoxide initialization
  ZOXIDE_INIT="$(zoxide init zsh)"

  case "$terminal" in
  foot)
    foot -a yazi --title "yazi" -e zsh -c "
      export EDITOR=\"nvim\";
      $ZOXIDE_INIT;
      yazi --cwd-file=\"$TMP_FILE\";
      cwd=\$(cat \"$TMP_FILE\");
      if [ -n \"\$cwd\" ] && [ \"\$cwd\" != \"\$PWD\" ]; then
        z \"\$cwd\";
      fi;
      zsh" >>/dev/null 2>&1 &
    ;;
  kitty)
    kitty --class yazi --title "yazi" -e zsh -c "
      export EDITOR=\"nvim\";
      $ZOXIDE_INIT;
      yazi --cwd-file=\"$TMP_FILE\";
      cwd=\$(cat \"$TMP_FILE\");
      if [ -n \"\$cwd\" ] && [ \"\$cwd\" != \"\$PWD\" ]; then
        z \"\$cwd\";
      fi;
      zsh" >>/dev/null 2>&1 &
    ;;
  alacritty)
    alacritty --class yazi --title "yazi" -e zsh -c "
      export EDITOR=\"nvim\";
      $ZOXIDE_INIT;
      yazi --cwd-file=\"$TMP_FILE\";
      cwd=\$(cat \"$TMP_FILE\");
      if [ -n \"\$cwd\" ] && [ \"\$cwd\" != \"\$PWD\" ]; then
        z \"\$cwd\";
      fi;
      zsh" >>/dev/null 2>&1 &
    ;;
  *)
    exit_with_error "Desteklenmeyen terminal: $terminal"
    ;;
  esac
  disown
}

start_ranger() {
  check_application "ranger"
  local terminal="${1:-foot}"

  if ! command -v "$terminal" &>/dev/null; then
    exit_with_error "$terminal terminal bulunamadı."
  fi

  notify-send -t 1000 "Ranger" "Ranger dosya yöneticisi $terminal ile başlatılıyor..."

  case "$terminal" in
  foot)
    foot -a Ranger --title "Ranger File Manager" -e ranger >>/dev/null 2>&1 &
    ;;
  kitty)
    kitty --class Ranger --title "Ranger File Manager" -e ranger >>/dev/null 2>&1 &
    ;;
  alacritty)
    alacritty --class Ranger --title "Ranger File Manager" -e ranger >>/dev/null 2>&1 &
    ;;
  *)
    exit_with_error "Desteklenmeyen terminal: $terminal"
    ;;
  esac
  disown
}

# Diğer uygulamalar için start fonksiyonları
start_anote() {
  if hyprctl clients -j | jq -e '.[] | select(.class == "anotes")' >/dev/null; then
    window_address=$(hyprctl clients -j | jq -r '
        [.[] | select(.class == "anotes")] | 
        sort_by(.focusHistoryID) | 
        last | 
        .address
    ')
    current_workspace=$(hyprctl activewindow -j | jq -r '.workspace.id')
    hyprctl dispatch movetoworkspace "$current_workspace,address:$window_address"
    hyprctl dispatch focuswindow "address:$window_address"
    notify-send -t 1000 "Anote" "Mevcut Anote penceresine odaklanıldı."
  else
    #foot -a anotes --title anotes -e anote >>/dev/null 2>&1 &
    wezterm start --class anotes -e anote >>/dev/null 2>&1 &
    disown
    notify-send -t 1000 "Anote" "Anote başlatılıyor..."
  fi
}

start_anotes() {
  if hyprctl clients -j | jq -e '.[] | select(.class == "anotes")' >/dev/null; then
    window_address=$(hyprctl clients -j | jq -r '
      [.[] | select(.class == "anotes")] | 
      sort_by(.focusHistoryID) | 
      last | 
      .address
    ')
    current_workspace=$(hyprctl activewindow -j | jq -r '.workspace.id')
    hyprctl dispatch movetoworkspace "$current_workspace,address:$window_address"
    hyprctl dispatch focuswindow "address:$window_address"
    notify-send -t 1000 "Anotes" "Mevcut Anotes penceresine odaklanıldı."
  else
    #alacritty --class anotes --title anotes -e anotes >>/dev/null 2>&1 &
    foot -a anotes --title anotes -e anotes >>/dev/null 2>&1 &
    disown
    notify-send -t 1000 "Anotes" "Anotes başlatılıyor..."
  fi
}

start_clock() {
  notify-send -t 1000 "Clock..." "Başlatılıyor..."
  GDK_BACKEND=wayland kitty --class clock --title clock tty-clock -c -C7 >>/dev/null 2>&1 &
  disown
}

start_discord() {
  check_application "discord"
  notify-send -t 1000 "Discord Başlıyor..." "Uygulama başlatılıyor..."
  GDK_BACKEND=wayland discord -m >>/dev/null 2>&1 &
  disown
}

start_gsconnect() {
  if gapplication launch org.gnome.Shell.Extensions.GSConnect >>/dev/null 2>&1; then
    notify-send -t 1000 "GSConnect Başlatıldı" "GSConnect uygulaması başarıyla başlatıldı."
  else
    exit_with_error "GSConnect başlatılamadı."
  fi
}

start_keepassxc() {
  if ! check_window "org.keepassxc.KeePassXC"; then
    notify-send -t 1000 "KeePassXC" "KeePassXC başlatılıyor..."
    GDK_BACKEND=wayland keepassxc >>/dev/null 2>&1 &
    disown
  fi
}

start_mpv() {
  if check_process "mpv"; then
    echo -e "${CYAN}MPV zaten çalışıyor.${NC} Pencere aktif hale getiriliyor."
    notify-send -i mpv -t 1000 "MPV Zaten Çalışıyor" "MPV aktif durumda, pencere öne getiriliyor."
    hyprctl dispatch focuswindow "class:mpv"
  else
    mpv --player-operation-mode=pseudo-gui --input-ipc-server=/tmp/mpvsocket -- >>/dev/null 2>&1 &
    disown
    notify-send -i mpv -t 1000 "MPV Başlatılıyor" "MPV oynatıcı başlatıldı ve hazır."
  fi
}

start_ncmpcpp() {
  # MPD durumunu kontrol et
  if ! pgrep -x mpd >/dev/null; then
    systemctl --user start mpd
    sleep 1
  fi

  # Hyprctl ile mevcut pencereyi kontrol et
  if ! hyprctl clients | grep -q "class: ncmpcpp"; then
    notify-send -t 1000 "Ncmpcpp" "Ncmpcpp başlatılıyor..."
    kitty \
      --class="ncmpcpp" \
      --title="ncmpcpp" \
      --override "initial_window_width=1000" \
      --override "initial_window_height=600" \
      --override "background_opacity=0.95" \
      --override "window_padding_width=15" \
      --override "hide_window_decorations=yes" \
      --override "font_size=13" \
      --override "confirm_os_window_close=0" \
      --config "$HOME/.config/kitty/kitty.conf" \
      -e ncmpcpp >>/dev/null 2>&1 &
    disown
  else
    hyprctl dispatch focuswindow "^(ncmpcpp)$"
    notify-send -t 1000 "Ncmpcpp" "Mevcut pencereye odaklanıldı."
  fi
}

start_netflix() {
  check_application "netflix"
  notify-send -t 1000 "Netflix Başlıyor..." "Uygulama başlatılıyor..."
  GDK_BACKEND=wayland netflix >>/dev/null 2>&1 &
  disown
}

start_otpclient() {
  if check_process "otpclient"; then
    notify-send -u normal -t 1000 "OTPClient Zaten Çalışıyor" "OTPClient uygulaması zaten çalışıyor."
    return
  fi
  notify-send -t 1000 "OTPClient Başlatılıyor..." "OTPClient uygulaması başlatılıyor."
  GDK_BACKEND=wayland otpclient >>/dev/null 2>&1 &
  disown
}

start_pavucontrol() {
  check_application "pavucontrol"
  notify-send -t 1000 "Pavucontrol..." "Uygulama başlatılıyor..."
  GDK_BACKEND=wayland pavucontrol >>/dev/null 2>&1 &
  disown
}

start_spotify() {
  check_application "spotify"
  GDK_BACKEND=wayland spotify >>/dev/null 2>&1 &
  disown
  notify-send -t 1000 "Spotify" "Spotify uygulaması başlatılıyor..."
}

start_tcopyb() {
  notify-send -t 1000 "Copy Manager" "Copy Manager (b) başlatılıyor..."
  kitty --class clipb --title clipb tmux-copy -b >>/dev/null 2>&1 &
  disown
}

start_tcopyc() {
  notify-send -t 1000 "Copy Manager" "Copy Manager (c) başlatılıyor..."
  kitty --class clipb --title clipb tmux-copy -c >>/dev/null 2>&1 &
  disown
}

start_thunar() {
  check_application "thunar"
  GDK_BACKEND=wayland thunar >>/dev/null 2>&1 &
  disown
  notify-send -t 1000 "Thunar Başlatılıyor..." "Dosya yöneticisi başlatıldı."
}

start_todo() {
  check_application "todo"
  GDK_BACKEND=wayland kitty --title todo --hold -e vim ~/.todo >>/dev/null 2>&1 &
  disown
  notify-send -t 1000 "Todo" "Todo uygulaması başlatılıyor..."
}

start_ulauncher() {
  check_application "ulauncher"
  GDK_BACKEND=wayland ulauncher-toggle >>/dev/null 2>&1 &
  disown
}

start_webcord() {
  check_application "webcord"
  notify-send -t 1000 "WebCord Başlıyor..." "Uygulama başlatılıyor..."
  GDK_BACKEND=wayland webcord -m >>/dev/null 2>&1 &
  disown
}

start_whatsapp() {
  check_application "zapzap"
  GDK_BACKEND=wayland zapzap >>/dev/null 2>&1 &
  disown
  notify-send -t 1000 "WhatsApp" "ZapZap uygulaması başlatılıyor..."
}

# Yardım mesajını göster
show_help() {
  echo -e "${CYAN}HyprFlow Start Manager v$VERSION${NC}"
  echo "Kullanım: $SCRIPT_NAME [SEÇENEK]"
  echo ""
  echo -e "${YELLOW}Terminal Emülatörler:${NC}"
  echo "  foot        - Foot terminal başlat"
  echo "  kitty       - Kitty terminal başlat"
  echo "  alacritty   - Alacritty terminal başlat"
  echo ""
  echo -e "${YELLOW}Dosya Yöneticileri:${NC}"
  echo "  yazi        - Yazi dosya yöneticisi başlat"
  echo "  yazi-foot   - Yazi'yi Foot ile başlat"
  echo "  yazi-kitty  - Yazi'yi Kitty ile başlat"
  echo "  yazi-alac   - Yazi'yi Alacritty ile başlat"
  echo "  ranger      - Ranger dosya yöneticisi başlat"
  echo "  ranger-foot - Ranger'ı Foot ile başlat"
  echo "  ranger-kitty- Ranger'ı Kitty ile başlat"
  echo "  ranger-alac - Ranger'ı Alacritty ile başlat"
  echo ""
  echo -e "${YELLOW}Temel Uygulamalar:${NC}"
  echo "  anote       - Anote başlat"
  echo "  anotes      - Anotes başlat"
  echo "  clock       - Terminal saati başlat"
  echo "  tcopyb      - Copy Manager (-b) başlat"
  echo "  tcopyc      - Copy Manager (-c) başlat"
  echo "  todo        - Todo uygulaması başlat"
  echo ""
  echo -e "${YELLOW}Internet Uygulamaları:${NC}"
  echo "  discord     - Discord başlat"
  echo "  webcord     - WebCord başlat"
  echo "  whatsapp    - WhatsApp (ZapZap) başlat"
  echo "  netflix     - Netflix başlat"
  echo ""
  echo -e "${YELLOW}Sistem Uygulamaları:${NC}"
  echo "  gsconnect   - GSConnect başlat"
  echo "  keepassxc   - KeePassXC başlat"
  echo "  otpclient   - OTPClient başlat"
  echo "  pavucontrol - Ses kontrol panelini başlat"
  echo "  thunar      - Thunar dosya yöneticisi başlat"
  echo "  ulauncher   - Ulauncher başlat"
  echo ""
  echo -e "${YELLOW}Medya Uygulamaları:${NC}"
  echo "  mpv         - MPV medya oynatıcı başlat"
  echo "  ncmpcpp     - Ncmpcpp müzik oynatıcı başlat"
  echo "  spotify     - Spotify başlat"
  echo ""
  echo -e "${YELLOW}Genel Seçenekler:${NC}"
  echo "  all         - Tüm uygulamaları başlat"
  echo "  --help, -h  - Bu yardım mesajını göster"
  echo "  --menu, -m  - Menü modunda çalıştır"
  echo ""
}

# Ana menü
show_menu() {
  echo -e "${CYAN}HyprFlow Start Manager v$VERSION${NC}"
  echo "================================"
  echo -e "${YELLOW}Terminal Emülatörler:${NC}"
  echo "1) Foot"
  echo "2) Kitty"
  echo "3) Alacritty"
  echo ""
  echo -e "${YELLOW}Dosya Yöneticileri:${NC}"
  echo "4) Yazi (Foot)"
  echo "5) Yazi (Kitty)"
  echo "6) Yazi (Alacritty)"
  echo "7) Ranger (Foot)"
  echo "8) Ranger (Kitty)"
  echo "9) Ranger (Alacritty)"
  echo ""
  echo -e "${YELLOW}Temel Uygulamalar:${NC}"
  echo "10) Anote"
  echo "11) Anotes"
  echo "12) Clock"
  echo "13) Copy Manager (-b)"
  echo "14) Copy Manager (-c)"
  echo "15) Todo"
  echo ""
  echo -e "${YELLOW}Internet Uygulamaları:${NC}"
  echo "16) Discord"
  echo "17) WebCord"
  echo "18) WhatsApp"
  echo "19) Netflix"
  echo ""
  echo -e "${YELLOW}Sistem Uygulamaları:${NC}"
  echo "20) GSConnect"
  echo "21) KeePassXC"
  echo "22) OTPClient"
  echo "23) Pavucontrol"
  echo "24) Thunar"
  echo "25) Ulauncher"
  echo ""
  echo -e "${YELLOW}Medya Uygulamaları:${NC}"
  echo "26) MPV"
  echo "27) Ncmpcpp"
  echo "28) Spotify"
  echo ""
  echo -e "${YELLOW}Genel Seçenekler:${NC}"
  echo "29) Tüm uygulamaları başlat"
  echo "0) Çıkış"
  echo "================================"
  echo -n "Seçiminiz (0-29): "
}

# Tüm uygulamaları başlat
start_all() {
  echo -e "${CYAN}Tüm uygulamalar başlatılıyor...${NC}"

  # Terminal emülatörler
  start_foot
  start_kitty
  start_alacritty

  # Dosya yöneticileri
  start_yazi "foot"
  start_ranger "foot"

  # Temel uygulamalar
  start_anote
  start_anotes
  start_clock
  start_tcopyb
  start_tcopyc
  start_todo

  # Internet uygulamaları
  start_discord
  start_webcord
  start_whatsapp
  start_netflix

  # Sistem uygulamaları
  start_gsconnect
  start_keepassxc
  start_otpclient
  start_pavucontrol
  start_thunar
  start_ulauncher

  # Medya uygulamaları
  start_mpv
  start_ncmpcpp
  start_spotify

  show_success "Tüm uygulamalar başlatıldı!"
}

# Menü modu
menu_mode() {
  while true; do
    clear
    show_menu
    read -r choice

    case $choice in
    0)
      echo "Çıkış yapılıyor..."
      break
      ;;
    # Terminal emülatörler
    1) start_foot ;;
    2) start_kitty ;;
    3) start_alacritty ;;
    # Dosya yöneticileri
    4) start_yazi "foot" ;;
    5) start_yazi "kitty" ;;
    6) start_yazi "alacritty" ;;
    7) start_ranger "foot" ;;
    8) start_ranger "kitty" ;;
    9) start_ranger "alacritty" ;;
    # Temel uygulamalar
    10) start_anote ;;
    11) start_anotes ;;
    12) start_clock ;;
    13) start_tcopyb ;;
    14) start_tcopyc ;;
    15) start_todo ;;
    # Internet uygulamaları
    16) start_discord ;;
    17) start_webcord ;;
    18) start_whatsapp ;;
    19) start_netflix ;;
    # Sistem uygulamaları
    20) start_gsconnect ;;
    21) start_keepassxc ;;
    22) start_otpclient ;;
    23) start_pavucontrol ;;
    24) start_thunar ;;
    25) start_ulauncher ;;
    # Medya uygulamaları
    26) start_mpv ;;
    27) start_ncmpcpp ;;
    28) start_spotify ;;
    # Genel seçenekler
    29) start_all ;;
    *)
      echo "Geçersiz seçim! Lütfen 0-29 arası bir sayı girin."
      sleep 2
      ;;
    esac
  done
}

# Ana program
if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

case "$1" in
# Terminal emülatörler
"foot") start_foot ;;
"kitty") start_kitty ;;
"alacritty") start_alacritty ;;

# Dosya yöneticileri
"yazi") start_yazi "foot" ;;
"yazi-foot") start_yazi "foot" ;;
"yazi-kitty") start_yazi "kitty" ;;
"yazi-alac") start_yazi "alacritty" ;;
"ranger") start_ranger "foot" ;;
"ranger-foot") start_ranger "foot" ;;
"ranger-kitty") start_ranger "kitty" ;;
"ranger-alac") start_ranger "alacritty" ;;

# Temel uygulamalar
"anote") start_anote ;;
"anotes") start_anotes ;;
"clock") start_clock ;;
"tcopyb") start_tcopyb ;;
"tcopyc") start_tcopyc ;;
"todo") start_todo ;;

# Internet uygulamaları
"discord") start_discord ;;
"webcord") start_webcord ;;
"whatsapp") start_whatsapp ;;
"netflix") start_netflix ;;

# Sistem uygulamaları
"gsconnect") start_gsconnect ;;
"keepassxc") start_keepassxc ;;
"otpclient") start_otpclient ;;
"pavucontrol") start_pavucontrol ;;
"thunar") start_thunar ;;
"ulauncher") start_ulauncher ;;

# Medya uygulamaları
"mpv") start_mpv ;;
"ncmpcpp") start_ncmpcpp ;;
"spotify") start_spotify ;;

# Genel seçenekler
"all") start_all ;;
"--help" | "-h") show_help ;;
"--menu" | "-m") menu_mode ;;

*)
  echo "Geçersiz parametre: $1"
  show_help
  exit 1
  ;;
esac

exit 0
