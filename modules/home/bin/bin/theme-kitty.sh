#!/bin/bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: KittyThemeManager - Kitty Terminal Renk Teması Yöneticisi
#
# Bu script Kitty terminal için kapsamlı bir renk teması yönetim sistemi sağlar.
# Temel özellikleri:
#
# - 9 Farklı Tema Desteği:
#   - Kenp (Özel tema)
#   - Tokyo Night
#   - Catppuccin Mocha
#   - Dracula Enhanced
#   - Rosé Pine Moon
#   - Kanagawa
#   - Nord
#   - Gruvbox Dark
#   - Everforest Dark
#
# - Tema Yönetimi:
#   - Tema değiştirme
#   - Temalar arası geçiş
#   - Otomatik yedekleme
#   - Canlı yenileme
#
# - Renk Özellikleri:
#   - Terminal renkleri (16 renk)
#   - İmleç renkleri
#   - Seçim renkleri
#   - Tab çubuğu renkleri
#   - URL ve işaretleme renkleri
#   - Pencere kenar renkleri
#
# - Sistem Entegrasyonu:
#   - Bildirim sistemi
#   - Kitty soket desteği
#   - Yapılandırma yedekleme
#
# Dizin: ~/.config/kitty/
# Dosya: theme.conf
#
# License: MIT
#
#######################################
KITTY_DIR="/home/kenan/.config/kitty"
THEME_FILE="$KITTY_DIR/theme.conf"
THEME_MARKER="# Current theme: "

# 1. En İyi Önerim
#foreground = "#c0caf5"
# Tokyo Night foreground
# Neden: Daha canlı, mavi alt tonu daha belirgin, okuma konforu yüksek
# HSL: 228°, 63%, 85%

# 2. Daha Nötr Seçenek
#foreground = "#c5ccdc"
# Özel karışım
# Neden: Daha dengeli gri-mavi, yormuyor
# HSL: 220°, 26%, 82%

# 3. Hafif Sıcak Ton
#foreground = "#cdd6f4"
# Catppuccin Mocha foreground
# Neden: Çok hafif mor alt ton, sıcak ve rahat
# HSL: 227°, 70%, 88%

# 4. Yüksek Kontrast
#foreground = "#d3d7e5"
# Özel karışım
# Neden: Daha yüksek kontrast isteyenler için
# HSL: 225°, 25%, 86%

# 5. Soft Ton
#foreground = "#b8c0d4"
# Özel karışım
# Neden: Daha yumuşak, göz yormayan
# HSL: 222°, 23%, 78%
# Kenp Theme (Custom)

read -r -d '' KENP <<'EOF'
# Kenp Theme
## Basic Colors
background              #282a36
foreground              #d8dae9
selection_foreground    #282a36
selection_background    #bd93f9
## Cursor Colors
cursor                  #bd93f9
cursor_text_color       #282a36
## URL Color
url_color              #8be9fd
## Window Border Colors
active_border_color     #bd93f9
inactive_border_color   #44475a
bell_border_color      #f1fa8c
## Tab Bar Colors
active_tab_foreground   #282a36
active_tab_background   #bd93f9
inactive_tab_foreground #f8f8f2
inactive_tab_background #282a36
tab_bar_background      #1e1f29
## Mark Colors
mark1_foreground #282a36
mark1_background #bd93f9
mark2_foreground #282a36
mark2_background #ff79c6
mark3_foreground #282a36
mark3_background #8be9fd
## Terminal Colors
# Black
color0  #595D71
color8  #6272a4
# Red
color1  #f38ba8
color9  #e95678
# Green
color2  #50fa7b
color10 #69ff94
# Yellow
color3  #f1fa8c
color11 #ffffa5
# Blue
color4  #bd93f9
color12 #d6acff
# Magenta
color5  #ff79c6
color13 #ff92df
# Cyan
color6  #8be9fd
color14 #a4ffff
# White
color7  #f8f8f2
color15 #ffffff
EOF

# Tokyo Theme
read -r -d '' TOKYO <<'EOF'
# Tokyo Night Theme
## Basic Colors
background              #1a1b26
#foreground              #c0caf5
foreground              #c0caf5
selection_foreground    #c0caf5
selection_background    #283457
## Cursor Colors
cursor                  #c0caf5
cursor_text_color       #1a1b26
## URL Color
url_color              #73daca
## Window Border Colors
active_border_color     #7aa2f7
inactive_border_color   #292e42
bell_border_color      #e0af68
## Tab Bar Colors
active_tab_foreground   #1a1b26
active_tab_background   #7aa2f7
inactive_tab_foreground #545c7e
inactive_tab_background #1a1b26
tab_bar_background      #15161e
## Mark Colors
mark1_foreground #1a1b26
mark1_background #7aa2f7
mark2_foreground #1a1b26
mark2_background #9ece6a
mark3_foreground #1a1b26
mark3_background #e0af68
## Terminal Colors
# Black
color0  #15161e
color8  #414868
# Red
color1  #f7768e
color9  #f7768e
# Green
color2  #9ece6a
color10 #9ece6a
# Yellow
color3  #e0af68
color11 #e0af68
# Blue
color4  #7aa2f7
color12 #7aa2f7
# Magenta
color5  #bb9af7
color13 #bb9af7
# Cyan
color6  #7dcfff
color14 #7dcfff
# White
color7  #a9b1d6
color15 #c0caf5
EOF

# Catppuccin Mocha Theme
read -r -d '' CATPPUCCIN_MOCHA <<'EOF'
# Catppuccin Mocha Theme
## Basic Colors
background              #1e1e2e
#foreground              #cdd6f4
foreground              #c0caf5
selection_foreground    #1e1e2e
selection_background    #f5e0dc
## Cursor Colors
cursor                  #f5e0dc
cursor_text_color       #1e1e2e
## URL Color
url_color              #f5e0dc
## Window Border Colors
active_border_color     #b4befe
inactive_border_color   #6c7086
bell_border_color      #f9e2af
## Tab Bar Colors
active_tab_foreground   #1e1e2e
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b
## Mark Colors
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec
## Terminal Colors
# Black
color0  #45475a
color8  #585b70
# Red
color1  #f38ba8
color9  #f38ba8
# Green
color2  #a6e3a1
color10 #a6e3a1
# Yellow
color3  #f9e2af
color11 #f9e2af
# Blue
color4  #89b4fa
color12 #89b4fa
# Magenta
color5  #f5c2e7
color13 #f5c2e7
# Cyan
color6  #94e2d5
color14 #94e2d5
# White
color7  #bac2de
color15 #a6adc8
EOF

# Dracula Theme
read -r -d '' DRACULA <<'EOF'
# Dracula Theme Enhanced
## Basic Colors
background              #21222C
foreground              #d8dae9
selection_foreground    #282a36
selection_background    #44475a
## Cursor Colors
cursor                  #bd93f9
cursor_text_color      #282a36
## URL Color
url_color              #ff79c6
url_style              underline
## Window Border Colors
active_border_color     #bd93f9
inactive_border_color   #44475a
bell_border_color      #f1fa8c
## Tab Bar Colors
tab_bar_style          fade
active_tab_foreground   #282a36
active_tab_background   #bd93f9
inactive_tab_foreground #f8f8f2
inactive_tab_background #282a36
tab_bar_background      #1e1f29
## Mark Colors
mark1_foreground #282a36
mark1_background #bd93f9
mark2_foreground #282a36
mark2_background #ff79c6
mark3_foreground #282a36
mark3_background #8be9fd
## Terminal Colors
# Black
color0  #44475a
color8  #565b70
# Red (Pastel)
color1  #ffb3c1
color9  #ffc1d0
# Green
color2  #50fa7b
color10 #69ff94
# Yellow
color3  #f1fa8c
color11 #ffffa5
# Blue
color4  #bd93f9
color12 #d6acff
# Magenta
color5  #ff79c6
color13 #ff92df
# Cyan
color6  #8be9fd
color14 #a4ffff
# White
color7  #f8f8f2
color15 #ffffff
## Extra Features
cursor_blink_interval   0.5
cursor_stop_blinking_after 5.0
#background_opacity      0.95
EOF

# Rosé Pine Moon Theme
read -r -d '' ROSE_PINE_MOON <<'EOF'
# Rosé Pine Moon Theme
## Basic Colors
background              #232136
#foreground              #e0def4
foreground              #c0caf5
selection_foreground    #e0def4
selection_background    #44415a
## Cursor Colors
cursor                  #56526e
cursor_text_color       #e0def4
## URL Color
url_color              #c4a7e7
## Window Border Colors
active_border_color     #3e8fb0
inactive_border_color   #44415a
bell_border_color      #ea9a97
## Tab Bar Colors
active_tab_foreground   #e0def4
active_tab_background   #393552
inactive_tab_foreground #908caa
inactive_tab_background #2a273f
tab_bar_background      #232136
## Mark Colors
mark1_foreground       #232136
mark1_background       #c4a7e7
mark2_foreground       #232136
mark2_background       #ea9a97
mark3_foreground       #232136
mark3_background       #f6c177
## Terminal Colors
# Black
color0  #393552
color8  #6e6a86
# Red
color1  #eb6f92
color9  #eb6f92
# Green
color2  #3e8fb0
color10 #3e8fb0
# Yellow
color3  #f6c177
color11 #f6c177
# Blue
color4  #9ccfd8
color12 #9ccfd8
# Magenta
color5  #c4a7e7
color13 #c4a7e7
# Cyan
color6  #ea9a97
color14 #ea9a97
# White
color7  #e0def4
color15 #e0def4
EOF

# Kanagawa Theme
read -r -d '' KANAGAWA <<'EOF'
# Kanagawa Theme
## Basic Colors
background              #1f1f28
#foreground              #dcd7ba
foreground              #c0caf5
selection_foreground    #dcd7ba
selection_background    #2d4f67
## Cursor Colors
cursor                  #c8c093
cursor_text_color       #1f1f28
## URL Color
url_color              #7e9cd8
## Window Border Colors
active_border_color     #957fb8
inactive_border_color   #2d4f67
bell_border_color      #ffa066
## Tab Bar Colors
active_tab_foreground   #dcd7ba
active_tab_background   #2d4f67
inactive_tab_foreground #727169
inactive_tab_background #1f1f28
tab_bar_background      #16161d
## Mark Colors
mark1_foreground       #1f1f28
mark1_background       #7e9cd8
mark2_foreground       #1f1f28
mark2_background       #957fb8
mark3_foreground       #1f1f28
mark3_background       #98bb6c
## Terminal Colors
# Black
color0  #16161d
color8  #727169
# Red
color1  #c34043
color9  #ff5d62
# Green
color2  #76946a
color10 #98bb6c
# Yellow
color3  #c0a36e
color11 #ffa066
# Blue
color4  #7e9cd8
color12 #7fb4ca
# Magenta
color5  #957fb8
color13 #938aa9
# Cyan
color6  #6a9589
color14 #7aa89f
# White
color7  #dcd7ba
color15 #c8c093
EOF

# Nord Theme
read -r -d '' NORD <<'EOF'
# Nord Theme
## Basic Colors
background              #2e3440
#foreground              #d8dee9
foreground              #c0caf5
selection_foreground    #d8dee9
selection_background    #4c566a
## Cursor Colors
cursor                  #d8dee9
cursor_text_color       #2e3440
## URL Color
url_color              #88c0d0
## Window Border Colors
active_border_color     #88c0d0
inactive_border_color   #4c566a
bell_border_color      #ebcb8b
## Tab Bar Colors
active_tab_foreground   #2e3440
active_tab_background   #88c0d0
inactive_tab_foreground #d8dee9
inactive_tab_background #3b4252
tab_bar_background      #2e3440
## Mark Colors
mark1_foreground       #2e3440
mark1_background       #88c0d0
mark2_foreground       #2e3440
mark2_background       #81a1c1
mark3_foreground       #2e3440
mark3_background       #a3be8c
## Terminal Colors
# Black
color0  #3b4252
color8  #4c566a
# Red
color1  #bf616a
color9  #bf616a
# Green
color2  #a3be8c
color10 #a3be8c
# Yellow
color3  #ebcb8b
color11 #ebcb8b
# Blue
color4  #81a1c1
color12 #81a1c1
# Magenta
color5  #b48ead
color13 #b48ead
# Cyan
color6  #88c0d0
color14 #8fbcbb
# White
color7  #e5e9f0
color15 #eceff4
EOF

# Gruvbox Dark Theme
read -r -d '' GRUVBOX_DARK <<'EOF'
# Gruvbox Dark Theme
## Basic Colors
background              #282828
#foreground              #ebdbb2
foreground              #c0caf5
selection_foreground    #ebdbb2
selection_background    #504945
## Cursor Colors
cursor                  #ebdbb2
cursor_text_color       #282828
## URL Color
url_color              #83a598
## Window Border Colors
active_border_color     #83a598
inactive_border_color   #504945
bell_border_color      #fe8019
## Tab Bar Colors
active_tab_foreground   #282828
active_tab_background   #83a598
inactive_tab_foreground #ebdbb2
inactive_tab_background #3c3836
tab_bar_background      #282828
## Mark Colors
mark1_foreground       #282828
mark1_background       #83a598
mark2_foreground       #282828
mark2_background       #d3869b
mark3_foreground       #282828
mark3_background       #b8bb26
## Terminal Colors
# Black
color0  #282828
color8  #928374
# Red
color1  #cc241d
color9  #fb4934
# Green
color2  #98971a
color10 #b8bb26
# Yellow
color3  #d79921
color11 #fabd2f
# Blue
color4  #458588
color12 #83a598
# Magenta
color5  #b16286
color13 #d3869b
# Cyan
color6  #689d6a
color14 #8ec07c
# White
color7  #a89984
color15 #ebdbb2
EOF

# Everforest Dark Theme
read -r -d '' EVERFOREST_DARK <<'EOF'
# Everforest Dark Theme
## Basic Colors
background              #2b3339
#foreground              #d3c6aa
foreground              #c0caf5
selection_foreground    #d3c6aa
selection_background    #503946
## Cursor Colors
cursor                  #d3c6aa
cursor_text_color       #2b3339
## URL Color
url_color              #7fbbb3
## Window Border Colors
active_border_color     #7fbbb3
inactive_border_color   #503946
bell_border_color      #e69875
## Tab Bar Colors
active_tab_foreground   #2b3339
active_tab_background   #7fbbb3
inactive_tab_foreground #d3c6aa
inactive_tab_background #374247
tab_bar_background      #2b3339
## Mark Colors
mark1_foreground       #2b3339
mark1_background       #7fbbb3
mark2_foreground       #2b3339
mark2_background       #d699b6
mark3_foreground       #2b3339
mark3_background       #dbbc7f
## Terminal Colors
# Black
color0  #4b565c
color8  #5c6a72
# Red
color1  #e67e80
color9  #e67e80
# Green
color2  #a7c080
color10 #a7c080
# Yellow
color3  #dbbc7f
color11 #dbbc7f
# Blue
color4  #7fbbb3
color12 #7fbbb3
# Magenta
color5  #d699b6
color13 #d699b6
# Cyan
color6  #83c092
color14 #83c092
# White
color7  #d3c6aa
color15 #d3c6aa
EOF

# Available themes array
declare -A THEMES=(
  ["kenp"]="$KENP"
  ["tokyo"]="$TOKYO"
  ["catppuccin_mocha"]="$CATPPUCCIN_MOCHA"
  ["dracula"]="$DRACULA"
  ["rose_pine_moon"]="$ROSE_PINE_MOON"
  ["kanagawa"]="$KANAGAWA"
  ["nord"]="$NORD"
  ["gruvbox_dark"]="$GRUVBOX_DARK"
  ["everforest_dark"]="$EVERFOREST_DARK"
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
  local message="Kitty theme switched to ${theme}"
  local formatted_theme=$(echo "$theme" | tr '_' ' ' | sed 's/.*/\u&/')

  echo -e "\033[1;32m$message\033[0m"
  notify-send "Kitty Theme" "$formatted_theme" --icon=terminal
}

# Get current theme from file
get_current_theme() {
  grep "^$THEME_MARKER" "$THEME_FILE" | cut -d' ' -f4 || echo "kenp"
}

# Apply theme to kitty config
apply_theme() {
  local theme_name=$1
  local theme_content="${THEMES[$theme_name]}"

  # Create backup
  cp "$THEME_FILE" "${THEME_FILE}.bak"

  # Write the theme marker and content
  echo "$THEME_MARKER$theme_name" >"$THEME_FILE"
  echo "$theme_content" >>"$THEME_FILE"

  # Show notifications
  notify "$theme_name"

  # Reload kitty configuration if running
  if [ -n "$KITTY_SOCKET" ]; then
    kitty @ set-colors --all "$THEME_FILE"
  fi
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
  echo "  $0 nord               # Switch to Nord theme"
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
