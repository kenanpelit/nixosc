#!/usr/bin/env bash

# Hata ayıklama
set -euo pipefail

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
WOFI_SCRIPTS="$HOME/.bin"
CACHE_DIR="$HOME/.cache/wofi"

# Menu entries with icons (alfabetik sıralı)
declare -A MENU_ENTRIES=(
  [">>> Applications"]="📱"
  [">>> Bluetooth"]="📶"
  [">>> Browser"]="🌐"
  [">>> Semsumo"]="🔒"
  [">>> Cliphist"]="📋"
  [">>> Font"]="📝"
  [">>> Keybinds"]="⌨️"
  [">>> Media"]="🎵"
  [">>> Power"]="⚡"
  [">>> Run"]="📱"
  [">>> Search"]="🔍"
  [">>> Ssh"]="🔒"
  [">>> System"]="⚙️"
  [">>> ThemeHypr"]="🎨"
  [">>> ThemeWofi"]="🎨"
  [">>> Tools"]="🛠️"
  [">>> Window"]="🪟"
  [">>> Zen"]="🧘"
  [">>> Firefox"]="🦊"
  [">>> ZenAll"]="⚡"
)

generate_menu() {
  for entry in "${!MENU_ENTRIES[@]}"; do
    echo "${MENU_ENTRIES[$entry]} $entry"
  done
}

show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/main.css" \
    --conf "$WOFI_DIR/configs/main" \
    --cache-file=/dev/null \
    --prompt "Launch:" \
    --insensitive
}

launch_applications() {
  exec wofi --show drun \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/drun" \
    --cache-file "$CACHE_DIR/wofi-drun.cache" \
    --sort-order frequency \
    --prompt "Applications:"
}

handle_selection() {
  local choice="$1"
  # İkonu kaldır
  local menu_item=$(echo "$choice" | sed 's/^[^ ]* //')

  case "$menu_item" in
  ">>> Applications")
    launch_applications
    ;;
  ">>> Bluetooth")
    exec "$WOFI_SCRIPTS/wofi-bluetooth.sh"
    ;;
  ">>> Font")
    exec "$WOFI_SCRIPTS/wofi-font-manager.sh"
    ;;
  ">>> Semsumo")
    exec "$WOFI_SCRIPTS/semsumo-wofi-start.sh"
    ;;
  ">>> Ssh")
    exec "$WOFI_SCRIPTS/wofi-ssh.sh"
    ;;
  ">>> Window")
    exec "$WOFI_SCRIPTS/wofi-window-switcher.sh"
    ;;
  ">>> Browser" | ">>> Run" | ">>> Cliphist" | ">>> Keybinds" | ">>> Media" | ">>> Power" | ">>> Search" | \
    ">>> System" | ">>> ThemeHypr" | ">>> ThemeWofi" | ">>> Tools" | ">>> Zen" | \
    ">>> Firefox" | ">>> ZenAll")
    local script_name="wofi-${menu_item#'>>> '}"
    script_name=$(echo "$script_name" | tr '[:upper:]' '[:lower:]').sh
    if [[ -x "$WOFI_SCRIPTS/$script_name" ]]; then
      exec "$WOFI_SCRIPTS/$script_name"
    else
      notify-send "Error" "Script not found: $script_name"
      exit 1
    fi
    ;;
  *)
    notify-send "Error" "Invalid selection: $menu_item"
    exit 1
    ;;
  esac
}

check_requirements() {
  local missing_deps=()

  # Gerekli dizinleri kontrol et
  [[ ! -d "$WOFI_DIR" ]] && missing_deps+=("$WOFI_DIR directory")
  [[ ! -d "$WOFI_SCRIPTS" ]] && missing_deps+=("$WOFI_SCRIPTS directory")
  [[ ! -d "$WOFI_DIR/styles" ]] && missing_deps+=("$WOFI_DIR/styles directory")
  [[ ! -d "$WOFI_DIR/configs" ]] && missing_deps+=("$WOFI_DIR/configs directory")

  # Gerekli programları kontrol et
  for cmd in wofi notify-send; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  # Eksik bağımlılıklar varsa bildir ve çık
  if [ ${#missing_deps[@]} -ne 0 ]; then
    echo "Error: Missing dependencies:"
    printf '%s\n' "${missing_deps[@]}"
    exit 1
  fi
}

create_cache_dir() {
  mkdir -p "$CACHE_DIR"
}

main() {
  # Gereksinimleri kontrol et
  check_requirements

  # Cache dizinini oluştur
  create_cache_dir

  # Menüyü göster ve seçimi işle
  if choice=$(show_menu); then
    if [[ -n "$choice" ]]; then
      handle_selection "$choice"
    fi
  fi
}

# Programı çalıştır
main
