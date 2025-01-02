#!/bin/bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TmuxThemeManager - Tmux Renk Teması Yönetim Aracı
#
# Bu script tmux için renk tema yönetimini sağlayan kapsamlı bir araçtır.
# Temel özellikleri:
#
# - Tema Yönetimi:
#   - 6 farklı özel tema (kenp, tokyo_night, dracula, kanagawa, nord, catppuccin)
#   - Tek komutla tema değiştirme
#   - Temalar arası geçiş yapma
#   - Mevcut tema sorgulama
#
# - Tema Yapılandırması:
#   - Her tema için 18 renk tanımı
#   - Arka plan renkleri
#   - Yazı renkleri
#   - Vurgulama renkleri
#
# - Sistem Entegrasyonu:
#   - Otomatik yapılandırma yedekleme
#   - Bildirim sistemi entegrasyonu
#   - Tmux oturum yenileme
#   - Renkli terminal çıktıları
#
# Dizin: ~/.config/tmux/
# Dosyalar:
#   - tmux.conf: Ana yapılandırma
#   - tmux.conf.local: Yerel tema ayarları
#
# License: MIT
#
#######################################
# Kenp theme definition
declare -A kenp=(
  # Background colors
  [1]="#1a1b26" # terminal black (main background)
  [2]="#24283b" # darker blue
  [3]="#414868" # dark blue gray

  # Foreground colors
  [4]="#a9b1d6" # main text
  [5]="#c0caf5" # light text
  [6]="#565f89" # comments

  # Accent colors
  [7]="#f7768e"  # red
  [8]="#ff9e64"  # orange
  [9]="#e0af68"  # yellow
  [10]="#9ece6a" # green
  [11]="#73daca" # light green
  [12]="#b4f9f8" # cyan
  [13]="#2ac3de" # blue cyan
  [14]="#7aa2f7" # blue
  [15]="#7dcfff" # light blue
  [16]="#bb9af7" # purple
  [17]="#89ddff" # ice blue
  [18]="#c0caf5" # white
)

# Tokyo Night theme definition
declare -A tokyo_night=(
  # Background colors
  [1]="#1a1b26" # terminal black (main background)
  [2]="#24283b" # darker blue
  [3]="#414868" # dark blue gray

  # Foreground colors
  [4]="#a9b1d6" # main text
  [5]="#c0caf5" # light text
  [6]="#565f89" # comments

  # Accent colors
  [7]="#f7768e"  # red
  [8]="#ff9e64"  # orange
  [9]="#e0af68"  # yellow
  [10]="#9ece6a" # green
  [11]="#73daca" # light green
  [12]="#b4f9f8" # cyan
  [13]="#2ac3de" # blue cyan
  [14]="#7aa2f7" # blue
  [15]="#7dcfff" # light blue
  [16]="#bb9af7" # purple
  [17]="#89ddff" # ice blue
  [18]="#c0caf5" # white
)

# Dracula theme definition
declare -A dracula=(
  # Background colors
  [1]="#282a36" # background
  [2]="#44475a" # current line
  [3]="#44475a" # selection

  # Foreground colors
  [4]="#f8f8f2" # foreground
  [5]="#f8f8f2" # bright foreground
  [6]="#6272a4" # comment

  # Accent colors
  [7]="#ff5555"  # red
  [8]="#ffb86c"  # orange
  [9]="#f1fa8c"  # yellow
  [10]="#50fa7b" # green
  [11]="#50fa7b" # light green
  [12]="#8be9fd" # cyan
  [13]="#8be9fd" # cyan variant
  [14]="#bd93f9" # purple
  [15]="#ff79c6" # pink
  [16]="#bd93f9" # purple variant
  [17]="#8be9fd" # cyan bright
  [18]="#f8f8f2" # white
)

# Kanagawa theme definition
declare -A kanagawa=(
  # Background colors
  [1]="#1f1f28" # background
  [2]="#16161d" # darker background
  [3]="#363646" # selection

  # Foreground colors
  [4]="#dcd7ba" # foreground
  [5]="#dcd7ba" # bright foreground
  [6]="#54546d" # comment

  # Accent colors
  [7]="#ff5d62"  # red
  [8]="#ffa066"  # orange
  [9]="#ffa066"  # yellow
  [10]="#98bb6c" # green
  [11]="#98bb6c" # light green
  [12]="#7aa89f" # cyan
  [13]="#7fb4ca" # blue cyan
  [14]="#7e9cd8" # blue
  [15]="#7fb4ca" # light blue
  [16]="#957fb8" # purple
  [17]="#7fb4ca" # ice blue
  [18]="#dcd7ba" # white
)

# Nord theme definition
declare -A nord=(
  # Background colors
  [1]="#2e3440" # background
  [2]="#3b4252" # darker background
  [3]="#434c5e" # selection

  # Foreground colors
  [4]="#eceff4" # foreground
  [5]="#eceff4" # bright foreground
  [6]="#4c566a" # comment

  # Accent colors
  [7]="#bf616a"  # red
  [8]="#d08770"  # orange
  [9]="#ebcb8b"  # yellow
  [10]="#a3be8c" # green
  [11]="#a3be8c" # light green
  [12]="#8fbcbb" # cyan
  [13]="#88c0d0" # blue cyan
  [14]="#81a1c1" # blue
  [15]="#88c0d0" # light blue
  [16]="#b48ead" # purple
  [17]="#88c0d0" # ice blue
  [18]="#eceff4" # white
)

# Catppuccin Mocha theme definition
declare -A catppuccin_mocha=(
  # Background colors
  [1]="#1e1e2e" # background
  [2]="#181825" # darker background
  [3]="#313244" # selection

  # Foreground colors
  [4]="#cdd6f4" # foreground
  [5]="#cdd6f4" # bright foreground
  [6]="#45475a" # comment

  # Accent colors
  [7]="#f38ba8"  # red
  [8]="#fab387"  # orange
  [9]="#f9e2af"  # yellow
  [10]="#a6e3a1" # green
  [11]="#94e2d5" # light green
  [12]="#94e2d5" # cyan
  [13]="#89dceb" # blue cyan
  [14]="#89b4fa" # blue
  [15]="#89dceb" # light blue
  [16]="#cba6f7" # purple
  [17]="#89dceb" # ice blue
  [18]="#cdd6f4" # white
)

# Available themes array
THEMES=(
  "kenp"
  "tokyo_night"
  "dracula"
  "kanagawa"
  "nord"
  "catppuccin_mocha"
)

TMUX_C="/home/kenan/.config/tmux/tmux.conf"
TMUX_CONF="/home/kenan/.config/tmux/tmux.conf.local"
THEME_MARKER="# Current theme: "

# Function to list available themes
list_themes() {
  echo -e "\033[1;34mAvailable themes:\033[0m"
  current=$(get_current_theme)
  for theme in "${THEMES[@]}"; do
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
  local message="Tmux theme switched to ${theme}"
  local formatted_theme=$(echo "$theme" | tr '_' ' ' | sed 's/.*/\u&/')

  echo -e "\033[1;32m$message\033[0m"
  notify-send "Tmux Theme" "$formatted_theme" --icon=terminal
}

# Get current theme from file
get_current_theme() {
  grep "^$THEME_MARKER" "$TMUX_CONF" | cut -d' ' -f4 || echo "tokyo_night"
}

# Apply theme to tmux config
apply_theme() {
  local theme_name=$1
  local -n theme=$2

  # Create backup
  cp "$TMUX_CONF" "${TMUX_CONF}.bak"

  # Read the entire file
  local content=$(<"$TMUX_CONF")

  # Update theme marker
  if grep -q "^$THEME_MARKER" "$TMUX_CONF"; then
    content=$(echo "$content" | sed "s/^$THEME_MARKER.*/$THEME_MARKER$theme_name/")
  else
    content=$(echo "$content" | sed "/tmux_conf_theme_colour_1=/i\\$THEME_MARKER$theme_name")
  fi

  # Update color definitions
  for i in {1..30}; do
    local color_var="tmux_conf_theme_colour_$i"
    local color_value=${theme[$i]}
    content=$(echo "$content" | sed "s/^$color_var=.*/$color_var=\"$color_value\"/")
  done

  # Write back to file
  echo "$content" >"$TMUX_CONF"

  # Show notifications
  notify "$theme_name"
}

# Reload tmux configuration
reload_tmux() {
  if [ -n "$TMUX" ]; then
    tmux run "sh -c 'tmux source \"$TMUX_C\"'" \; display "Config reloaded!"
  fi
}

# Toggle between themes
toggle_theme() {
  current_theme=$(get_current_theme)
  local next_theme

  for i in "${!THEMES[@]}"; do
    if [ "${THEMES[$i]}" = "$current_theme" ]; then
      next_index=$(((i + 1) % ${#THEMES[@]}))
      next_theme="${THEMES[$next_index]}"
      break
    fi
  done

  if [ -z "$next_theme" ]; then
    next_theme="${THEMES[0]}"
  fi

  apply_theme "$next_theme" "$next_theme"
  reload_tmux
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
  echo "To apply a specific theme, use: $0 theme_name"
  echo "Example: $0 tokyo_night"
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
  # Check if the provided theme exists
  theme_exists=0
  for theme in "${THEMES[@]}"; do
    if [ "$1" = "$theme" ]; then
      theme_exists=1
      break
    fi
  done

  if [ $theme_exists -eq 1 ]; then
    apply_theme "$1" "$1"
    reload_tmux
  else
    echo -e "\033[1;31mError: Theme '$1' not found\033[0m"
    echo "Available themes:"
    list_themes
    exit 1
  fi
  ;;
esac
