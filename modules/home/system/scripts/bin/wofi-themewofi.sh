#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"
CONFIG_DIR="$HOME/.config/hypr"

# Catppuccin renk paletleri
declare -A THEMES=(
  # Kenp
  ["🎭 Kenp - Default"]="2E2B37"
  ["🎭 Kenp - Pink"]="F5C2E7"
  ["🎭 Kenp - Purple"]="CBA6F7"
  ["🎭 Kenp - Blue"]="89DCEB"

  # Dracula
  ["🦇 Dracula - Default"]="282a36"
  ["🦇 Dracula - Purple"]="bd93f9"
  ["🦇 Dracula - Pink"]="ff79c6"
  ["🦇 Dracula - Blue"]="8be9fd"
  ["🦇 Dracula - Green"]="50fa7b"
  ["🦇 Dracula - Yellow"]="f1fa8c"
  ["🦇 Dracula - Orange"]="ffb86c"
  ["🦇 Dracula - Red"]="ff5555"

  # Mocha
  ["🌑 Mocha - Rosewater"]="f5e0dc"
  ["🌑 Mocha - Flamingo"]="f2cdcd"
  ["🌑 Mocha - Pink"]="f5c2e7"
  ["🌑 Mocha - Mauve"]="cba6f7"
  ["🌑 Mocha - Red"]="f38ba8"
  ["🌑 Mocha - Maroon"]="eba0ac"
  ["🌑 Mocha - Peach"]="fab387"
  ["🌑 Mocha - Yellow"]="f9e2af"
  ["🌑 Mocha - Green"]="a6e3a1"
  ["🌑 Mocha - Teal"]="94e2d5"
  ["🌑 Mocha - Sky"]="89dceb"
  ["🌑 Mocha - Sapphire"]="74c7ec"
  ["🌑 Mocha - Blue"]="89b4fa"
  ["🌑 Mocha - Lavender"]="b4befe"

  # Macchiato
  ["☕ Macchiato - Rosewater"]="f4dbd6"
  ["☕ Macchiato - Flamingo"]="f0c6c6"
  ["☕ Macchiato - Pink"]="f5bde6"
  ["☕ Macchiato - Mauve"]="c6a0f6"
  ["☕ Macchiato - Red"]="ed8796"
  ["☕ Macchiato - Maroon"]="ee99a0"
  ["☕ Macchiato - Peach"]="f5a97f"
  ["☕ Macchiato - Yellow"]="eed49f"
  ["☕ Macchiato - Green"]="a6da95"
  ["☕ Macchiato - Teal"]="8bd5ca"
  ["☕ Macchiato - Sky"]="91d7e3"
  ["☕ Macchiato - Sapphire"]="7dc4e4"
  ["☕ Macchiato - Blue"]="8aadf4"
  ["☕ Macchiato - Lavender"]="b7bdf8"

  # Frappe
  ["🍮 Frappe - Rosewater"]="f2d5cf"
  ["🍮 Frappe - Flamingo"]="eebebe"
  ["🍮 Frappe - Pink"]="f4b8e4"
  ["🍮 Frappe - Mauve"]="ca9ee6"
  ["🍮 Frappe - Red"]="e78284"
  ["🍮 Frappe - Maroon"]="ea999c"
  ["🍮 Frappe - Peach"]="ef9f76"
  ["🍮 Frappe - Yellow"]="e5c890"
  ["🍮 Frappe - Green"]="a6d189"
  ["🍮 Frappe - Teal"]="81c8be"
  ["🍮 Frappe - Sky"]="99d1db"
  ["🍮 Frappe - Sapphire"]="85c1dc"
  ["🍮 Frappe - Blue"]="8caaee"
  ["🍮 Frappe - Lavender"]="babbf1"

  # Latte
  ["🥛 Latte - Rosewater"]="dc8a78"
  ["🥛 Latte - Flamingo"]="dd7878"
  ["🥛 Latte - Pink"]="ea76cb"
  ["🥛 Latte - Mauve"]="8839ef"
  ["🥛 Latte - Red"]="d20f39"
  ["🥛 Latte - Maroon"]="e64553"
  ["🥛 Latte - Peach"]="fe640b"
  ["🥛 Latte - Yellow"]="df8e1d"
  ["🥛 Latte - Green"]="40a02b"
  ["🥛 Latte - Teal"]="179299"
  ["🥛 Latte - Sky"]="04a5e5"
  ["🥛 Latte - Sapphire"]="209fb5"
  ["🥛 Latte - Blue"]="1e66f5"
  ["🥛 Latte - Lavender"]="7287fd"
)

generate_menu() {
  echo ">>> 🎭 Kenp"
  for theme in "${!THEMES[@]}"; do
    [[ $theme == "🎭 Kenp"* ]] && echo "$theme"
  done
  echo ""

  echo ">>> 🦇 Dracula"
  for theme in "${!THEMES[@]}"; do
    [[ $theme == "🦇 Dracula"* ]] && echo "$theme"
  done
  echo ""

  echo ">>> 🌑 Mocha"
  for theme in "${!THEMES[@]}"; do
    [[ $theme == "🌑 Mocha"* ]] && echo "$theme"
  done
  echo ""

  echo ">>> ☕ Macchiato"
  for theme in "${!THEMES[@]}"; do
    [[ $theme == "☕ Macchiato"* ]] && echo "$theme"
  done
  echo ""

  echo ">>> 🍮 Frappe"
  for theme in "${!THEMES[@]}"; do
    [[ $theme == "🍮 Frappe"* ]] && echo "$theme"
  done
  echo ""

  echo ">>> 🥛 Latte"
  for theme in "${!THEMES[@]}"; do
    [[ $theme == "🥛 Latte"* ]] && echo "$theme"
  done
}

show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/theme" \
    --cache-file=/dev/null \
    --prompt "Select Theme:" \
    --insensitive
}

apply_theme() {
  local theme_name="$1"
  local flavor="${theme_name%% -*}"
  flavor="${flavor#* }"             # İkonu kaldır
  local color="${theme_name##* - }" # Renk adını al

  # Catppuccin ve Kenp renk kodları
  declare -A KENP=(
    ["Default"]="#2E2B37"
    ["Pink"]="#F5C2E7"
    ["Purple"]="#CBA6F7"
    ["Blue"]="#89DCEB"
    ["Base"]="#2E2B37"
    ["Surface0"]="#3B3846"
    ["Text"]="#DCD7EA"
    ["Mauve"]="#CBA6F7"
  )

  declare -A DRACULA=(
    ["Default"]="#282a36"
    ["Purple"]="#bd93f9"
    ["Pink"]="#ff79c6"
    ["Blue"]="#8be9fd"
    ["Green"]="#50fa7b"
    ["Yellow"]="#f1fa8c"
    ["Orange"]="#ffb86c"
    ["Red"]="#ff5555"
    ["Base"]="#282a36"
    ["Surface0"]="#44475a"
    ["Text"]="#f8f8f2"
    ["Mauve"]="#bd93f9"
  )

  declare -A MOCHA=(
    ["Rosewater"]="#f5e0dc" ["Flamingo"]="#f2cdcd" ["Pink"]="#f5c2e7"
    ["Mauve"]="#cba6f7" ["Red"]="#f38ba8" ["Maroon"]="#eba0ac"
    ["Peach"]="#fab387" ["Yellow"]="#f9e2af" ["Green"]="#a6e3a1"
    ["Teal"]="#94e2d5" ["Sky"]="#89dceb" ["Sapphire"]="#74c7ec"
    ["Blue"]="#89b4fa" ["Lavender"]="#b4befe"
    ["Base"]="#1e1e2e" ["Surface0"]="#313244" ["Text"]="#cdd6f4"
  )

  declare -A MACCHIATO=(
    ["Rosewater"]="#f4dbd6" ["Flamingo"]="#f0c6c6" ["Pink"]="#f5bde6"
    ["Mauve"]="#c6a0f6" ["Red"]="#ed8796" ["Maroon"]="#ee99a0"
    ["Peach"]="#f5a97f" ["Yellow"]="#eed49f" ["Green"]="#a6da95"
    ["Teal"]="#8bd5ca" ["Sky"]="#91d7e3" ["Sapphire"]="#7dc4e4"
    ["Blue"]="#8aadf4" ["Lavender"]="#b7bdf8"
    ["Base"]="#24273a" ["Surface0"]="#363a4f" ["Text"]="#cad3f5"
  )

  declare -A FRAPPE=(
    ["Rosewater"]="#f2d5cf" ["Flamingo"]="#eebebe" ["Pink"]="#f4b8e4"
    ["Mauve"]="#ca9ee6" ["Red"]="#e78284" ["Maroon"]="#ea999c"
    ["Peach"]="#ef9f76" ["Yellow"]="#e5c890" ["Green"]="#a6d189"
    ["Teal"]="#81c8be" ["Sky"]="#99d1db" ["Sapphire"]="#85c1dc"
    ["Blue"]="#8caaee" ["Lavender"]="#babbf1"
    ["Base"]="#303446" ["Surface0"]="#414559" ["Text"]="#c6d0f5"
  )

  declare -A LATTE=(
    ["Rosewater"]="#dc8a78" ["Flamingo"]="#dd7878" ["Pink"]="#ea76cb"
    ["Mauve"]="#8839ef" ["Red"]="#d20f39" ["Maroon"]="#e64553"
    ["Peach"]="#fe640b" ["Yellow"]="#df8e1d" ["Green"]="#40a02b"
    ["Teal"]="#179299" ["Sky"]="#04a5e5" ["Sapphire"]="#209fb5"
    ["Blue"]="#1e66f5" ["Lavender"]="#7287fd"
    ["Base"]="#eff1f5" ["Surface0"]="#ccd0da" ["Text"]="#4c4f69"
  )

  # Seçilen temanın renklerini al
  local -n COLORS
  case "$flavor" in
  "Dracula") COLORS=DRACULA ;;
  "Kenp") COLORS=KENP ;;
  "Mocha") COLORS=MOCHA ;;
  "Macchiato") COLORS=MACCHIATO ;;
  "Frappe") COLORS=FRAPPE ;;
  "Latte") COLORS=LATTE ;;
  esac

  # CSS template dosyası oluştur
  local css_template="$WOFI_DIR/styles/style.css.template"
  cat >"$css_template" <<'EOF'
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 18px;
    font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
}

#window {
    background-color: %base_alpha%;
    color: %text%;
    border: 2px solid %accent%;
    border-radius: 15px;
}

#outer-box {
    padding: 15px;
}

#input {
    background-color: %surface0_alpha%;
    border: none;
    border-radius: 8px;
    margin: 0px 0px 10px 0px;
    padding: 8px 12px;
    color: %accent%;
}

#scroll {
    margin: 5px 0px;
}

#text {
    color: %text%;
    margin: 0px 5px;
}

#entry {
    padding: 5px 10px;
    margin: 0px 0px;
}

#entry:selected {
    background: linear-gradient(90deg, %accent_alpha%, %accent2_alpha%);
    border-radius: 8px;
    color: %base%;
}
EOF

  # CSS dosyasını oluştur
  local css_file="$WOFI_DIR/styles/style.css"
  cp "$css_template" "$css_file"

  # Renkleri değiştir
  sed -i \
    -e "s/%base%/${COLORS[Base]}/g" \
    -e "s/%base_alpha%/rgba(${COLORS[Base]//\#/}, 0.95)/g" \
    -e "s/%text%/${COLORS[Text]}/g" \
    -e "s/%surface0%/${COLORS[Surface0]}/g" \
    -e "s/%surface0_alpha%/rgba(${COLORS[Surface0]//\#/}, 0.7)/g" \
    -e "s/%accent%/${COLORS[$color]}/g" \
    -e "s/%accent_alpha%/rgba(${COLORS[$color]//\#/}, 0.7)/g" \
    -e "s/%accent2%/${COLORS[Mauve]}/g" \
    -e "s/%accent2_alpha%/rgba(${COLORS[Mauve]//\#/}, 0.7)/g" \
    "$css_file"

  # Hyprland'ı yeniden yükle
  if command -v hyprctl &>/dev/null; then
    hyprctl reload
  fi

  notify-send "Theme Changed" "Applied $theme_name theme"
}

create_theme_config() {
  cat >"$WOFI_DIR/configs/theme" <<EOF
## Wofi Theme Switcher Config
show=dmenu
prompt=Select Theme:
insensitive=true
normal_window=false
layer=overlay
columns=1

## Geometry
width=400
height=600
location=center
orientation=vertical
halign=fill
line_wrap=off
dynamic_lines=true

## Style
allow_markup=true
allow_images=true
image_size=24
hide_scroll=true
no_actions=true
matching=fuzzy
sort_order=default
gtk_dark=true
filter_rate=100

## Keys
key_down=Down,Tab,Control+j
key_up=Up,ISO_Left_Tab,Control+k
key_forward=Down,Tab
key_backward=Up,ISO_Left_Tab
key_exit=Escape
key_submit=Return,KP_Enter
EOF
}

main() {
  # Config dosyasını oluştur
  create_theme_config

  # Tema seç
  local choice
  if ! choice=$(show_menu); then
    exit 0
  fi

  # Kategori başlığı seçildiyse çık
  if [[ "$choice" == ">>> "* ]]; then
    exit 0
  fi

  # Temayı uygula
  if [[ -n "$choice" ]]; then
    apply_theme "$choice"
  fi
}

main
