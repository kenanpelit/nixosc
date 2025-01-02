#!/bin/bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: AlacrittyThemeManager - Alacritty Terminal Renk Teması Yöneticisi
#
# Bu script Alacritty terminal için tema yönetimini sağlayan bir araçtır.
# Temel özellikleri:
#
# - 4 Farklı Tema Desteği:
#   - Kenp (Özel tema)
#   - Tokyo Night
#   - Catppuccin Mocha
#   - Dracula
#
# - Tema Yönetimi:
#   - TOML formatında tema tanımları
#   - Tema değiştirme ve geçiş
#   - Otomatik yedekleme
#   - Kolay tema ekleme
#
# - Renk Özellikleri:
#   - İndeksli renkler
#   - Birincil renkler (arka plan/ön plan)
#   - Normal ve parlak renkler
#   - İmleç ve seçim renkleri
#
# - Sistem Entegrasyonu:
#   - Bildirim sistemi
#   - Renkli terminal çıktıları
#   - Kolay kullanım için CLI
#
# Dizin: ~/.config/alacritty/
# Dosya: colors.toml
#
# License: MIT
#
#######################################
ALACRITTY_DIR="/home/kenan/.config/alacritty"
THEME_FILE="$ALACRITTY_DIR/colors.toml"
THEME_MARKER="# Current theme: "

# Kenp Theme (Current)
read -r -d '' KENP <<'EOF'
# Current theme: kenp

[[colors.indexed_colors]]
color = "#ffb86c"
index = 16

[[colors.indexed_colors]]
color = "#ffb3c1"
index = 17

[colors.primary]
background = "#282a36"
foreground = "#d8dae9"
dim_foreground = "#6272a4"
bright_foreground = "#ffffff"

[colors.normal]
black = "#44475a"
red = "#ffb3c1"
green = "#50fa7b"
yellow = "#f1fa8c"
blue = "#bd93f9"
magenta = "#ff79c6"
cyan = "#8be9fd"
white = "#f8f8f2"

[colors.bright]
black = "#565b70"
red = "#ffc1d0"
green = "#69ff94"
yellow = "#ffffa5"
blue = "#d6acff"
magenta = "#ff92df"
cyan = "#a4ffff"
white = "#ffffff"

[colors.cursor]
cursor = "CellForeground"
text = "CellBackground"

[colors.selection]
background = "#44475a"
text = "CellForeground"
[[colors.indexed_colors]]
color = "#d18616"
index = 16
EOF

# Tokyo Night Theme
read -r -d '' TOKYO <<'EOF'
# Current theme: tokyo

[[colors.indexed_colors]]
color = "#ff9e64"
index = 16

[[colors.indexed_colors]]
color = "#db4b4b"
index = 17

[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"
dim_foreground = "#a9b1d6"
bright_foreground = "#c0caf5"

[colors.normal]
black = "#15161e"
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
white = "#a9b1d6"

[colors.bright]
black = "#414868"
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
white = "#c0caf5"

[colors.cursor]
cursor = "CellForeground"
text = "CellBackground"

[colors.selection]
background = "#283457"
text = "CellForeground"
EOF

# Catppuccin Mocha Theme
read -r -d '' MOCHA <<'EOF'
# Current theme: mocha

[[colors.indexed_colors]]
color = "#fab387"
index = 16

[[colors.indexed_colors]]
color = "#f5e0dc"
index = 17

[colors.primary]
background = "#1e1e2e"
#foreground = "#cdd6f4"
foreground = "#c0caf5"
dim_foreground = "#bac2de"
bright_foreground = "#cdd6f4"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#bac2de"

[colors.bright]
black = "#585b70"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#a6adc8"

[colors.cursor]
cursor = "CellForeground"
text = "CellBackground"

[colors.selection]
background = "#45475a"
text = "CellForeground"
EOF

# Dracula Theme
read -r -d '' DRACULA <<'EOF'
# Current theme: dracula
[[colors.indexed_colors]]
color = "#ffb86c"
index = 16

[[colors.indexed_colors]]
color = "#ffb3c1"
index = 17

[colors.primary]
background = "#21222C"
foreground = "#c0caf5"
dim_foreground = "#6272a4"
bright_foreground = "#ffffff"

[colors.normal]
black = "#44475a"
red = "#ffb3c1"
green = "#50fa7b"
yellow = "#f1fa8c"
blue = "#bd93f9"
magenta = "#ff79c6"
cyan = "#8be9fd"
white = "#f8f8f2"

[colors.bright]
black = "#565b70"
red = "#ffc1d0"
green = "#69ff94"
yellow = "#ffffa5"
blue = "#d6acff"
magenta = "#ff92df"
cyan = "#a4ffff"
white = "#ffffff"

[colors.cursor]
cursor = "CellForeground"
text = "CellBackground"

[colors.selection]
background = "#44475a"
text = "CellForeground"
EOF

# Available themes array
declare -A THEMES=(
  ["kenp"]="$KENP"
  ["tokyo"]="$TOKYO"
  ["mocha"]="$MOCHA"
  ["dracula"]="$DRACULA"
)

# Function to list available themes
list_themes() {
  echo -e "\033[1;34mAvailable themes:\033[0m"
  current=$(get_current_theme)
  for theme in "${!THEMES[@]}"; do
    if [ "$theme" = "$current" ]; then
      echo -e "  \033[1;32m* $theme \033[1;33m(current)\033[0m"
    else
      echo "    $theme"
    fi
  done
}

# Function to show notifications
notify() {
  local theme=$1
  local message="Alacritty theme switched to ${theme}"
  local formatted_theme=$(echo "$theme" | tr '_' ' ' | sed 's/.*/\u&/')

  echo -e "\033[1;32m$message\033[0m"
  notify-send "Alacritty Theme" "$formatted_theme" --icon=terminal
}

# Get current theme from file
get_current_theme() {
  grep "^# Current theme: " "$THEME_FILE" | cut -d' ' -f4 || echo "kenp"
}

# Apply theme to alacritty config
apply_theme() {
  local theme_name=$1
  local theme_content="${THEMES[$theme_name]}"

  # Create backup
  cp "$THEME_FILE" "${THEME_FILE}.bak"

  # Write the theme content
  echo "$theme_content" >"$THEME_FILE"

  # Show notifications
  notify "$theme_name"
}

# Toggle between themes
toggle_theme() {
  current_theme=$(get_current_theme)
  local next_theme=""
  local found=0

  for theme in "${!THEMES[@]}"; do
    if [ $found -eq 1 ]; then
      next_theme=$theme
      break
    fi
    if [ "$theme" = "$current_theme" ]; then
      found=1
    fi
  done

  # If we're at the last theme or theme not found, go back to first
  if [ -z "$next_theme" ]; then
    next_theme=$(echo "${!THEMES[@]}" | cut -d' ' -f1)
  fi

  apply_theme "$next_theme"
}

# Show help
show_help() {
  echo "Usage: $0 [OPTION] [THEME]"
  echo
  echo "Options:"
  echo "  -l, --list     List available themes"
  echo "  -t, --toggle   Toggle to next theme"
  echo "  -h, --help     Show this help message"
  echo "  -c, --current  Show current theme"
  echo
  echo "Available themes:"
  for theme in "${!THEMES[@]}"; do
    echo "  - $theme"
  done
  echo
  echo "Examples:"
  echo "  $0 -t                  # Toggle to next theme"
  echo "  $0 tokyo              # Switch to Tokyo Night theme"
  echo "  $0 -l                  # List all themes"
}

# Main script logic
case "$1" in
"" | "-t" | "--toggle")
  toggle_theme
  ;;
"-l" | "--list")
  list_themes
  ;;
"-h" | "--help")
  show_help
  ;;
"-c" | "--current")
  current_theme=$(get_current_theme)
  echo -e "Current theme: \033[1;32m$current_theme\033[0m"
  ;;
*)
  if [ -n "${THEMES[$1]}" ]; then
    apply_theme "$1"
  else
    echo -e "\033[1;31mError: Theme '$1' not found\033[0m"
    echo "Available themes:"
    list_themes
    exit 1
  fi
  ;;
esac
