#!/usr/bin/env bash

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

# Yapılandırma Değişkenleri
readonly STARTALL="$HOME/.config/gnome/scripts"
readonly ZEN_DIR="$HOME/.zen"
readonly WORKSPACE_SLEEP=1
readonly VPN_INTERFACE_TUN="/proc/sys/net/ipv4/conf/tun0"
readonly VPN_INTERFACE_WG="/proc/sys/net/ipv4/conf/wg0-mullvad"

# Monitör Tanımlamaları
readonly MONITOR_DELL="DP-5"    # ID 1
readonly MONITOR_LAPTOP="eDP-1" # ID 0

# Hata yakalama
set -euo pipefail
trap 'echo "Hata oluştu. Satır: $LINENO, Komut: $BASH_COMMAND"' ERR

# Uygulama Yapılandırması
declare -A BROWSER_PROFILES=(
  ["Kenp"]="1:yes:no:3" # workspace:maximize:group:sleep
  ["CompecTA"]="4:yes:no:3"
  ["NoVpn"]="3:yes:no:3"
  ["Discord"]="5:no:yes:4"
  ["Whats"]="9:no:yes:5"
)

declare -A SCRIPT_APPS=(
  ["Discord"]="5:no:no:4"
  ["Spotify"]="8:no:yes:4" # workspace:maximize:group:sleep
)

# Uygulama Başlatma Fonksiyonları
launch_spotify() {
  if ! command -v spotify &>/dev/null; then
    log "ERROR" "Spotify uygulaması bulunamadı."
    return 1
  fi

  GDK_BACKEND=wayland /usr/bin/spotify >>/dev/null 2>&1 &
  disown
  log "Spotify" "Spotify uygulaması başlatılıyor..."
}

launch_discord() {
  GDK_BACKEND=wayland /usr/bin/webcord -m >>/dev/null 2>&1 &
  disown
}

# Monitör Kurulum Fonksiyonu
setup_dual_monitors() {
  log "MONITOR" "Setting up dual monitors..."
  local workspaces=(1 2 3 4 5 6 7 8 9)

  for ws in "${workspaces[@]}"; do
    # GNOME Wayland'da workspace'leri yapılandır
    dbus-send --session --dest=org.gnome.Shell --type=method_call \
      /org/gnome/Shell org.gnome.Shell.Eval string:"global.workspace_manager.get_workspace_by_index($((ws - 1))).activate(0)"
    sleep 0.1
  done
  log "MONITOR" "Dual monitor setup completed"
}

# Tmux Session Yönetimi
launch_tmux_session() {
  local session_name=$1
  local terminal=${2:-"kitty"} # Varsayılan terminal kitty
  local vpn_cmd=""

  # VPN kontrolü
  [[ -e "$VPN_INTERFACE_TUN" || -e "$VPN_INTERFACE_WG" ]] && vpn_cmd="mullvad-exclude"

  # Terminal komutlarını eksiksiz belirle
  if [[ "$terminal" == "kitty" ]]; then
    if [[ -n "$vpn_cmd" ]]; then
      $vpn_cmd /usr/bin/kitty --class Tmux -T Tmux -e tmux new-session -A -s "$session_name" >>/dev/null 2>&1 &
    else
      /usr/bin/kitty --class Tmux -T Tmux -e tmux new-session -A -s "$session_name" >>/dev/null 2>&1 &
    fi
  else
    if [[ -n "$vpn_cmd" ]]; then
      $vpn_cmd /usr/bin/alacritty --class Tmux --title Tmux -e tmux new-session -A -s "$session_name" >>/dev/null 2>&1 &
    else
      /usr/bin/alacritty --class Tmux --title Tmux -e tmux new-session -A -s "$session_name" >>/dev/null 2>&1 &
    fi
  fi
  disown
}

# Yardımcı Fonksiyonlar
log() {
  local app=$1
  local message=$2
  local duration=${3:-5000}
  notify-send -t "$duration" -a "$app" "$message"
}

set_cpu_frequency() {
  local mode=$1
  case $mode in
  "high")
    # Turbo aktif, yüksek performans modu
    echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
    sudo cpupower frequency-set -g performance
    sudo cpupower frequency-set -d 1900MHz -u 2800MHz >/dev/null 2>&1
    log "CPU" "Performance mode: 1900-2800MHz (Turbo ON) 🔥"
    ;;
  "low")
    # Turbo deaktif, düşük güç modu
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
    sudo cpupower frequency-set -g powersave
    sudo cpupower frequency-set -d 1200MHz -u 1900MHz >/dev/null 2>&1
    log "CPU" "Power save mode: 1200-1900MHz (Turbo OFF) 🌱"
    ;;
  esac
}

configure_session_restore() {
  local profile_dir="$ZEN_DIR/$1"
  local prefs_file="$profile_dir/prefs.js"

  [[ ! -f "$prefs_file" ]] && touch "$prefs_file"

  local -a settings=(
    'user_pref("browser.startup.page", 3);'
    'user_pref("browser.sessionstore.resume_session_once", false);'
    'user_pref("browser.sessionstore.resume_from_crash", true);'
    'user_pref("browser.startup.couldRestoreSession.count", 1);'
  )

  for setting in "${settings[@]}"; do
    grep -q "$setting" "$prefs_file" || echo "$setting" >>"$prefs_file"
  done
}

launch_browser_profile() {
  local profile=$1
  local config=${BROWSER_PROFILES[$profile]}
  local workspace=$(echo "$config" | cut -d: -f1)
  local maximize=$(echo "$config" | cut -d: -f2)
  local group=$(echo "$config" | cut -d: -f3)
  local sleep_time=$(echo "$config" | cut -d: -f4)

  [[ -d "$ZEN_DIR/$profile" ]] && configure_session_restore "$profile"

  # GNOME Wayland'da workspace değiştirme
  dbus-send --session --dest=org.gnome.Shell --type=method_call \
    /org/gnome/Shell org.gnome.Shell.Eval string:"global.workspace_manager.get_workspace_by_index($((workspace - 1))).activate(0)"
  sleep "$WORKSPACE_SLEEP"
  log "$profile" "Starting $profile on workspace $workspace..."

  GDK_BACKEND=wayland MOZ_CRASHREPORTER_DISABLE=1 /usr/bin/zen-browser -P "$profile" --restore-session >>/dev/null 2>&1 &
  disown
  sleep "$sleep_time"

  # GNOME Wayland'da pencere yönetimi
  local window_id=$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval "global.get_window_actors().filter(w => w.meta_window.get_title().includes('$profile')).map(w => w.meta_window.get_stable_sequence())[0]")

  if [[ "$window_id" != "null" ]]; then
    # Maximize
    if [[ "$maximize" == "yes" ]]; then
      dbus-send --session --dest=org.gnome.Shell --type=method_call \
        /org/gnome/Shell org.gnome.Shell.Eval string:"global.get_window_actors().find(w => w.meta_window.get_stable_sequence() == $window_id).meta_window.maximize()"
    fi
    sleep 0.5
  fi
}

launch_script_app() {
  local app=$1
  local config=${SCRIPT_APPS[$app]}
  local workspace=$(echo "$config" | cut -d: -f1)
  local maximize=$(echo "$config" | cut -d: -f2)
  local group=$(echo "$config" | cut -d: -f3)
  local sleep_time=$(echo "$config" | cut -d: -f4)

  # GNOME Wayland'da workspace değiştirme
  dbus-send --session --dest=org.gnome.Shell --type=method_call \
    /org/gnome/Shell org.gnome.Shell.Eval string:"global.workspace_manager.get_workspace_by_index($((workspace - 1))).activate(0)"
  sleep "$WORKSPACE_SLEEP"
  log "${app}" "Starting $app on workspace $workspace..."

  case "$app" in
  "Spotify")
    launch_spotify
    ;;
  "Discord")
    launch_discord
    ;;
  *)
    log "ERROR" "Unknown app: $app"
    return 1
    ;;
  esac

  sleep "$sleep_time"

  # GNOME Wayland'da pencere yönetimi
  local window_id=$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval "global.get_window_actors().filter(w => w.meta_window.get_title().toLowerCase().includes('${app}'.toLowerCase())).map(w => w.meta_window.get_stable_sequence())[0]")

  if [[ "$window_id" != "null" ]]; then
    if [[ "$maximize" == "yes" ]]; then
      dbus-send --session --dest=org.gnome.Shell --type=method_call \
        /org/gnome/Shell org.gnome.Shell.Eval string:"global.get_window_actors().find(w => w.meta_window.get_stable_sequence() == $window_id).meta_window.maximize()"
    fi
    sleep 0.5
  fi
}

# Workspace bazında sıralama fonksiyonları
launch_profiles_by_workspace() {
  local -a workspaces=()
  local -A workspace_profiles=()

  # Workspace numaralarını ve profilleri eşleştir
  for profile in "${!BROWSER_PROFILES[@]}"; do
    local workspace=$(echo "${BROWSER_PROFILES[$profile]}" | cut -d: -f1)
    workspaces+=("$workspace")
    workspace_profiles[$workspace]=$profile
  done

  # Workspace numaralarını sırala
  IFS=$'\n' sorted_workspaces=($(sort -n <<<"${workspaces[*]}"))
  unset IFS

  # Sıralı workspace'lere göre profilleri başlat
  for ws in "${sorted_workspaces[@]}"; do
    local profile="${workspace_profiles[$ws]}"
    launch_browser_profile "$profile"
  done
}

launch_apps_by_workspace() {
  local -a workspaces=()
  local -A workspace_apps=()

  # Workspace numaralarını ve uygulamaları eşleştir
  for app in "${!SCRIPT_APPS[@]}"; do
    local workspace=$(echo "${SCRIPT_APPS[$app]}" | cut -d: -f1)
    workspaces+=("$workspace")
    workspace_apps[$workspace]=$app
  done

  # Workspace numaralarını sırala
  IFS=$'\n' sorted_workspaces=($(sort -n <<<"${workspaces[*]}"))
  unset IFS

  # Sıralı workspace'lere göre uygulamaları başlat
  for ws in "${sorted_workspaces[@]}"; do
    local app="${workspace_apps[$ws]}"
    launch_script_app "$app"
  done
}

main() {
  local start_time=$(date +%s)

  log "START" "All apps starting! 🔥"

  # CPU yüksek performans modu
  set_cpu_frequency "high"
  sleep 0.5

  # Browser profillerini workspace sırasına göre başlat
  launch_profiles_by_workspace

  # Script uygulamalarını workspace sırasına göre başlat
  launch_apps_by_workspace

  # Tmux oturumu
  dbus-send --session --dest=org.gnome.Shell --type=method_call \
    /org/gnome/Shell org.gnome.Shell.Eval string:"global.workspace_manager.get_workspace_by_index(1).activate(0)"
  sleep 0.5
  log "TMUX" "Starting Tmux on workspace 2..."
  launch_tmux_session "KENP" "alacritty"
  sleep 0.5

  log "All apps" "All apps completed! 🔥"

  # CPU düşük güç modu
  sleep 1
  set_cpu_frequency "low"

  # Süre hesaplama
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  log "Duration" "Total time taken: $duration seconds." 20000
}

main "$@"
