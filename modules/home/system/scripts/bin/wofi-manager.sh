#!/usr/bin/env bash

# Directory definitions
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"

# Constants
divider="---------"
goback="Back"

# Common wofi command configuration
wofi_command() {
  local prompt="$1"
  local config="${2:-default}"
  local style="${3:-style}"

  wofi --dmenu \
    --style "$WOFI_DIR/styles/$style.css" \
    --conf "$WOFI_DIR/configs/$config" \
    --cache-file=/dev/null \
    --prompt "$prompt:" \
    --insensitive
}

# Main menu generation
generate_main_menu() {
  echo "🌐 All Zen Profiles"
  echo "🔷 Bluetooth Manager"
  echo "🌐 Browser Launcher"
  echo "📋 Clipboard Manager"
  echo "🦊 Firefox Profiles"
  echo "📏 Font Manager"
  echo "🎨 Hyprland Theme"
  echo "⌨️ Keybindings"
  echo "🌐 Launch Zen Profile"
  echo "🎵 Media Controls"
  echo "⚡ Power Menu"
  echo "🔋 Power Profiles"
  echo "🚀 Run Applications"
  echo "🔍 Search"
  echo "⚙️ System Menu"
  echo "🔍 System Search"
  echo "🛠️ Tools Menu"
  echo "🪟 Window Switcher"
  echo "📶 WiFi Manager"
  echo "🎨 Wofi Theme"
  echo "🌐Zen Manager"
}

# Bluetooth menu handler
handle_bluetooth() {
  "$SCRIPTS_DIR/wofi-bluetooth.sh"
}

# Clipboard manager handler
handle_clipboard() {
  "$SCRIPTS_DIR/wofi-cliphist.sh"
}

# Firefox profiles handler
handle_firefox() {
  "$SCRIPTS_DIR/wofi-firefox.sh"
}

# Browser launcher handler
handle_browser() {
  "$SCRIPTS_DIR/wofi-browser.sh"
}

# Font manager handler
handle_font() {
  "$SCRIPTS_DIR/wofi-font-manager.sh"
}

# Main menu handler
show_main_menu() {
  local choice
  choice=$(generate_main_menu | wofi_command "Wofi Menu" "main" "style")

  case "$choice" in
  # System Controls
  "⚡ Power Menu")
    "$SCRIPTS_DIR/wofi-power.sh"
    ;;
  "🔋 Power Profiles")
    "$SCRIPTS_DIR/wofi-powerprofiles.sh"
    ;;
  "🔷 Bluetooth Manager")
    handle_bluetooth
    ;;
  "📶 WiFi Manager")
    "$SCRIPTS_DIR/wofi-wifi.sh"
    ;;
  "🎵 Media Controls")
    "$SCRIPTS_DIR/wofi-media.sh"
    ;;

  # Applications
  "🚀 Run Applications")
    "$SCRIPTS_DIR/wofi-run.sh"
    ;;
  "🪟 Window Switcher")
    "$SCRIPTS_DIR/wofi-window-switcher.sh"
    ;;
  "🔍 Search")
    "$SCRIPTS_DIR/wofi-search.sh"
    ;;
  "🛠️ Tools Menu")
    "$SCRIPTS_DIR/wofi-tools.sh"
    ;;

  # Browsers & Profiles
  "🦊 Firefox Profiles")
    handle_firefox
    ;;
  "🌐 Browser Launcher")
    handle_browser
    ;;
  "🌐 Launch Zen Profile")
    "$SCRIPTS_DIR/wofi-launch-zen.sh"
    ;;
  "🌐 Zen Manager")
    "$SCRIPTS_DIR/wofi-zen.sh"
    ;;
  "🌐 All Zen Profiles")
    "$SCRIPTS_DIR/wofi-zenall.sh"
    ;;

  # Customization
  "🎨 Wofi Theme")
    "$SCRIPTS_DIR/wofi-themewofi.sh"
    ;;
  "🎨 Hyprland Theme")
    "$SCRIPTS_DIR/wofi-themehypr.sh"
    ;;
  "📏 Font Manager")
    handle_font
    ;;
  "⌨️  Keybindings")
    "$SCRIPTS_DIR/wofi-keybinds.sh"
    ;;

  # Utilities
  "📋 Clipboard Manager")
    handle_clipboard
    ;;
  "🔍 System Search")
    "$SCRIPTS_DIR/wofi-search.sh"
    ;;
  "⚙️  System Menu")
    "$SCRIPTS_DIR/wofi-system.sh"
    ;;
  esac
}

# Configuration check and setup
setup_config() {
  # Create config directories if they don't exist
  mkdir -p "$WOFI_DIR/configs"
  mkdir -p "$WOFI_DIR/styles"

  # Create main configuration file
  cat >"$WOFI_DIR/configs/main" <<EOF
width=400
height=500
location=center
show=dmenu
prompt=Menu:
filter_rate=100
allow_markup=true
no_actions=true
line_wrap=word
insensitive=true
matching=contains
sort_order=default
gtk_dark=true
EOF

  # Create default style file if it doesn't exist
  [[ ! -f "$WOFI_DIR/styles/style.css" ]] && cat >"$WOFI_DIR/styles/style.css" <<EOF
window {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 16px;
}

#entry {
    padding: 0.5rem;
}

#input {
    border: 2px solid #1e1e2e;
    background-color: #313244;
    padding: 0.5rem;
}

#inner-box {
    background-color: #1e1e2e;
}

#outer-box {
    margin: 0.5rem;
    padding: 0.5rem;
    background-color: #1e1e2e;
}

#scroll {
    margin: 0.5rem;
}

#text {
    margin: 0.5rem;
    color: #cdd6f4;
}

#text:selected {
    color: #1e1e2e;
}

#entry:selected {
    background-color: #89b4fa;
}
EOF
}

# Script initialization
init() {
  # Check if required directories exist
  if [[ ! -d "$SCRIPTS_DIR" ]]; then
    echo "Error: Scripts directory not found at $SCRIPTS_DIR"
    exit 1
  fi

  # Check if required scripts exist and are executable
  local required_scripts=(
    "wofi-bluetooth.sh"
    "wofi-browser.sh"
    "wofi-cliphist.sh"
    "wofi-firefox.sh"
    "wofi-font-manager.sh"
    "wofi-keybinds.sh"
    "wofi-launch-zen.sh"
    "wofi-media.sh"
    "wofi-powerprofiles.sh"
    "wofi-power.sh"
    "wofi-run.sh"
    "wofi-search.sh"
    "wofi-system.sh"
    "wofi-themehypr.sh"
    "wofi-themewofi.sh"
    "wofi-tools.sh"
    "wofi-wifi.sh"
    "wofi-window-switcher.sh"
    "wofi-zenall.sh"
    "wofi-zen.sh"
  )

  for script in "${required_scripts[@]}"; do
    if [[ ! -x "$SCRIPTS_DIR/$script" ]]; then
      echo "Error: Required script $script not found or not executable"
      exit 1
    fi
  done

  # Setup configuration
  setup_config
}

# Parse command line arguments
parse_args() {
  case "$1" in
  # System Controls
  --power)
    "$SCRIPTS_DIR/wofi-power.sh"
    ;;
  --power-profiles)
    "$SCRIPTS_DIR/wofi-powerprofiles.sh"
    ;;
  --bluetooth)
    handle_bluetooth
    ;;
  --wifi)
    "$SCRIPTS_DIR/wofi-wifi.sh"
    ;;
  --media)
    "$SCRIPTS_DIR/wofi-media.sh"
    ;;

  # Applications
  --run)
    "$SCRIPTS_DIR/wofi-run.sh"
    ;;
  --window)
    "$SCRIPTS_DIR/wofi-window-switcher.sh"
    ;;
  --search)
    "$SCRIPTS_DIR/wofi-search.sh"
    ;;
  --tools)
    "$SCRIPTS_DIR/wofi-tools.sh"
    ;;

  # Browsers & Profiles
  --firefox)
    handle_firefox
    ;;
  --browser)
    handle_browser
    ;;
  --zen)
    "$SCRIPTS_DIR/wofi-launch-zen.sh"
    ;;
  --zen-manager)
    "$SCRIPTS_DIR/wofi-zen.sh"
    ;;
  --zen-all)
    "$SCRIPTS_DIR/wofi-zenall.sh"
    ;;

  # Customization
  --theme-wofi)
    "$SCRIPTS_DIR/wofi-themewofi.sh"
    ;;
  --theme-hypr)
    "$SCRIPTS_DIR/wofi-themehypr.sh"
    ;;
  --font)
    handle_font
    ;;
  --keybinds)
    "$SCRIPTS_DIR/wofi-keybinds.sh"
    ;;

  # Utilities
  --clipboard)
    handle_clipboard
    ;;
  --system-search)
    "$SCRIPTS_DIR/wofi-search.sh"
    ;;
  --system)
    "$SCRIPTS_DIR/wofi-system.sh"
    ;;

  # Default
  *)
    show_main_menu
    ;;
  esac
}

# Main execution
init
parse_args "$@"
