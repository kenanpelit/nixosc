#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"

# Zen profilleri ve özellikleri
declare -A ZEN_PROFILES=(
  ["🌐 Kenp Browser"]="1|Kenp||yes|no|5"
  ["🏢 CompecTA"]="3|CompecTA||yes|no|5"
  ["💬 WhatsApp"]="7|Whats||no|yes|5"
  ["🌍 NoVpn"]="5|NoVpn||yes|no|5"
  ["🎵 Spotify"]="6|Spotify||no|yes|5"
  ["📱 Discord"]="4|Discord||no|yes|5"
)

# Script uygulamaları ve özellikleri
declare -A SCRIPT_APPS=(
  ["🎵 Spotify App"]="6|SpotifyS|start-spotify.sh||no|yes|5"
  ["💬 WhatsApp App"]="7|WhatsAppS|start-whats-zapzap.sh||no|no|6"
  ["📱 Discord App"]="4|DiscordS|start-discord.sh||no|no|7"
)

# Özel komutlar
declare -A SPECIAL_COMMANDS=(
  ["⚡ Start All"]="start_all"
  ["🖥️ Setup Dual Monitors"]="setup_monitors"
  ["🎮 Start Tmux Session"]="start_tmux"
  ["🦷 Toggle Bluetooth"]="toggle_bluetooth"
  ["🔋 Set CPU 4000"]="cpu_high"
  ["🔌 Set CPU 2000"]="cpu_low"
)

generate_menu() {
  echo ">>> 🚀 Quick Actions"
  for cmd in "${!SPECIAL_COMMANDS[@]}"; do
    echo "$cmd"
  done
  echo ""

  echo ">>> 🌐 Zen Browser Profiles"
  for profile in "${!ZEN_PROFILES[@]}"; do
    echo "$profile"
  done
  echo ""

  echo ">>> 📱 Applications"
  for app in "${!SCRIPT_APPS[@]}"; do
    echo "$app"
  done
}

show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/zen" \
    --cache-file=/dev/null \
    --prompt "Zen Launcher:" \
    --insensitive
}

launch_browser_profile() {
  local workspace="$1"
  local profile="$2"
  local icon="$3"
  local fullscreen="$4"
  local togglegroup="$5"
  local launch_sleep="$6"

  notify-send "Launching" "Starting $profile on workspace $workspace"

  hyprctl dispatch workspace "$workspace"
  sleep 2

  GDK_BACKEND=wayland MOZ_CRASHREPORTER_DISABLE=1 /usr/bin/zen-browser -P "$profile" &
  sleep "$launch_sleep"

  hyprctl dispatch movetoworkspacesilent "$workspace"
  sleep 1

  [[ "$fullscreen" == "yes" ]] && hyprctl dispatch fullscreen 0
  [[ "$togglegroup" == "yes" ]] && hyprctl dispatch togglegroup
}

launch_script_app() {
  local workspace="$1"
  local app_name="$2"
  local script="$3"
  local icon="$4"
  local fullscreen="$5"
  local togglegroup="$6"
  local launch_sleep="$7"

  notify-send "Launching" "Starting $app_name on workspace $workspace"

  hyprctl dispatch workspace "$workspace"
  sleep 2

  "$SCRIPTS_DIR/$script" &
  sleep "$launch_sleep"

  hyprctl dispatch movetoworkspacesilent "$workspace"
  sleep 1

  [[ "$fullscreen" == "yes" ]] && hyprctl dispatch fullscreen 0
  [[ "$togglegroup" == "yes" ]] && hyprctl dispatch togglegroup
}

handle_special_command() {
  case "$1" in
  "start_all")
    "$SCRIPTS_DIR/rofi-bang-bangbang.sh" &
    ;;
  "setup_monitors")
    "$SCRIPTS_DIR/hyprctl_setup_dual_monitors.sh"
    ;;
  "start_tmux")
    "$SCRIPTS_DIR/sem.sh" start kenp01
    ;;
  "toggle_bluetooth")
    "$SCRIPTS_DIR/_bluetooth_toggle.sh"
    ;;
  "cpu_high")
    "$SCRIPTS_DIR/_set_cpu_frequency.sh" 4000
    notify-send "CPU" "Set to 4000MHz"
    ;;
  "cpu_low")
    "$SCRIPTS_DIR/_set_cpu_frequency.sh" 2000
    notify-send "CPU" "Set to 2000MHz"
    ;;
  esac
}

main() {
  local choice
  if ! choice=$(show_menu); then
    exit 0
  fi

  if [[ "$choice" == ">>> "* ]]; then
    exit 0
  fi

  # Özel komutları işle
  for cmd in "${!SPECIAL_COMMANDS[@]}"; do
    if [[ "$choice" == "$cmd" ]]; then
      handle_special_command "${SPECIAL_COMMANDS[$cmd]}"
      exit 0
    fi
  done

  # Zen profillerini işle
  for profile in "${!ZEN_PROFILES[@]}"; do
    if [[ "$choice" == "$profile" ]]; then
      IFS='|' read -r workspace name icon fullscreen togglegroup sleep <<<"${ZEN_PROFILES[$profile]}"
      launch_browser_profile "$workspace" "$name" "$icon" "$fullscreen" "$togglegroup" "$sleep"
      exit 0
    fi
  done

  # Script uygulamalarını işle
  for app in "${!SCRIPT_APPS[@]}"; do
    if [[ "$choice" == "$app" ]]; then
      IFS='|' read -r workspace name script icon fullscreen togglegroup sleep <<<"${SCRIPT_APPS[$app]}"
      launch_script_app "$workspace" "$name" "$script" "$icon" "$fullscreen" "$togglegroup" "$sleep"
      exit 0
    fi
  done
}

main
