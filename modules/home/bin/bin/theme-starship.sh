#!/bin/bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: StarshipThemeManager - Starship Prompt Tema Yöneticisi
#
# Bu script Starship prompt için tema yönetimini sağlayan kapsamlı bir araçtır.
# Temel özellikleri:
#
# - Tema Yönetimi:
#   - 4 farklı hazır tema (Original, Pastel, Ultimate, Ultimate Pro)
#   - Otomatik tema döngüsü
#   - İlk kurulum desteği
#   - Durum kontrolü ve geçiş
#
# - Tema Özellikleri:
#   - Git entegrasyonu ve özel semboller
#   - Programlama dili göstergeleri
#   - Komut süresi ve saat gösterimi
#   - Özelleştirilmiş karakter sembolleri
#   - Nerd Font desteği
#
# - Dizin Yapısı:
#   ~/.config/starship/
#     - starship.toml.original
#     - starship.toml.pastel
#     - starship.toml.ultimate
#     - starship.toml.ultimate-pro
#
# - Gereksinimler:
#   - Starship yüklü olmalı
#   - Ultimate temalar için Nerd Font gerekli
#
# License: MIT
#
#######################################
# Yapılandırma dosyalarının yolları
CONFIG_DIR="$HOME/.config/starship"
ORIGINAL_CONFIG="$CONFIG_DIR/starship.toml.original"
PASTEL_CONFIG="$CONFIG_DIR/starship.toml.pastel"
ULTIMATE_CONFIG="$CONFIG_DIR/starship.toml.ultimate"
ULTIMATE_PRO_CONFIG="$CONFIG_DIR/starship.toml.ultimate-pro"
SUMO_CONFIG="$CONFIG_DIR/starship.toml.sumo"
ACTIVE_CONFIG="$HOME/.config/starship.toml"

# Klasör yoksa oluştur
mkdir -p "$CONFIG_DIR"

# Orijinal yapılandırmayı oluştur
cat >"$ORIGINAL_CONFIG" <<'EOL'
format = """
$username$hostname$directory$git_branch$git_status$nodejs$python$rust$jobs$status
$character"""

right_format = "$cmd_duration"

[directory]
style = "blue"
read_only = " 🔒"
read_only_style = "red"
truncation_length = 3
truncate_to_repo = true
fish_style_pwd_dir_length = 1

[package]
disabled = true

[character]
success_symbol = "[❯](purple)"
error_symbol = "[❯](red)"
vimcmd_symbol = "[❮](green)"

[git_branch]
format = "[$branch]($style)"
style = "bright-black"

[git_status]
format = '[\($all_status$ahead_behind\)]($style) '
style = "bright-black"
conflicted = "🏳"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
untracked = "?${count}"
stashed = "📦"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[cmd_duration]
format = "[󰔟 $duration]($style)"
style = "yellow dimmed"
min_time = 2000
show_milliseconds = false

[nodejs]
format = "[$symbol($version )]($style)"
style = "green"

[python]
format = "[$symbol($version )]($style)"
style = "yellow"

[rust]
format = "[$symbol($version )]($style)"
style = "red"

[memory_usage]
format = "[$symbol${ram}]($style) "
style = "dimmed white"
threshold = 75
symbol = "🗃️ "
disabled = false

[battery]
full_symbol = "🔋"
charging_symbol = "⚡️"
discharging_symbol = "💀"
disabled = false
[[battery.display]]
threshold = 10
style = "red"
[[battery.display]]
threshold = 30
style = "yellow"

[time]
disabled = false
format = '🕙 [$time]($style) '
time_format = "%R"
style = "bright-black"

[jobs]
symbol = "⚙️"
number_threshold = 1
format = "[$symbol$number]($style) "
EOL

# Pastel yapılandırmayı oluştur
cat >"$PASTEL_CONFIG" <<'EOL'
format = """
$directory$git_branch$git_status
$character"""

right_format = "$cmd_duration"

[directory]
style = "#87CEEB"
read_only = " 🔒"
read_only_style = "#FFB6C1"
truncation_length = 3
truncate_to_repo = true
fish_style_pwd_dir_length = 1

[character]
success_symbol = "[❯](#DDA0DD)"
error_symbol = "[❯](#FFB6C1)"
vimcmd_symbol = "[❮](#98FB98)"

[git_branch]
format = "[$branch]($style)"
style = "#A9A9A9"

[git_status]
format = '[\($all_status$ahead_behind\)]($style) '
style = "#A9A9A9"
conflicted = "✗"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕"
untracked = "?"
stashed = "≡"
modified = "!"
staged = "+"
renamed = "»"
deleted = "✘"

[cmd_duration]
format = " [󰔟 $duration]($style)"
style = "#F0E68C"
min_time = 1000
show_milliseconds = false

[nodejs]
format = "[$symbol($version )]($style)"
style = "#98FB98"

[python]
format = "[$symbol($version )]($style)"
style = "#F0E68C"

[rust]
format = "[$symbol($version )]($style)"
style = "#FFB6C1"

[jobs]
format = "[$symbol]($style)"
symbol = "⚙"
style = "#87CEEB"
EOL

# Ultimate yapılandırmayı oluştur
cat >"$ULTIMATE_CONFIG" <<'EOL'
format = """
[](fg:#1C2128 bg:none)\
$directory\
$git_branch\
$git_status\
[](fg:#1C2128 bg:none)\
$fill\
$cmd_duration\
$time
$character"""

continuation_prompt = "[ ](fg:#33658A)"

[directory]
style = "fg:#33658A bg:#1C2128"
format = "[ $path ]($style)"
truncation_length = 3
truncate_to_repo = true
fish_style_pwd_dir_length = 1

[character]
success_symbol = "[󱞪](purple)"
error_symbol = "[󱞪](red)"
vimcmd_symbol = "[󱞩](green)"

[git_branch]
format = '[ $symbol$branch(:$remote_branch) ]($style)'
symbol = "󰘬 "
style = "fg:#86BBD8 bg:#1C2128"

[git_status]
format = '[$all_status$ahead_behind]($style)'
style = "fg:#F06449 bg:#1C2128"
conflicted = "≠"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕"
untracked = "?${count}"
stashed = "≡"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[cmd_duration]
format = "[ 󱎫 $duration]($style)"
style = "fg:#F26419 bg:#1C2128"
min_time = 1000
show_milliseconds = false

[time]
format = '[ 󰥔 $time ]($style)'
style = "fg:#2F4858 bg:#1C2128"
time_format = "%R"
disabled = false

[fill]
symbol = " "

[aws]
symbol = "  "

[buf]
symbol = " "

[c]
symbol = " "

[conda]
symbol = " "

[dart]
symbol = " "

[docker_context]
symbol = " "

[elixir]
symbol = " "

[elm]
symbol = " "

[golang]
symbol = " "

[guix_shell]
symbol = " "

[haskell]
symbol = " "

[haxe]
symbol = " "

[hg_branch]
symbol = " "

[hostname]
ssh_symbol = " "

[java]
symbol = " "

[julia]
symbol = " "

[lua]
symbol = " "

[memory_usage]
symbol = "󰍛 "

[meson]
symbol = "󰔷 "

[nim]
symbol = "󰆥 "

[nix_shell]
symbol = " "

[nodejs]
symbol = " "

[os.symbols]
Alpaquita = " "
Alpine = " "
Amazon = " "
Android = " "
Arch = " "
Artix = " "
CentOS = " "
Debian = " "
DragonFly = " "
Emscripten = " "
EndeavourOS = " "
Fedora = " "
FreeBSD = " "
Garuda = "󰛓 "
Gentoo = " "
HardenedBSD = "󰞌 "
Illumos = "󰈸 "
Linux = " "
Mabox = " "
Macos = " "
Manjaro = " "
Mariner = " "
MidnightBSD = " "
Mint = " "
NetBSD = " "
NixOS = " "
OpenBSD = "󰈺 "
openSUSE = " "
OracleLinux = "󰌷 "
Pop = " "
Raspbian = " "
Redhat = " "
RedHatEnterprise = " "
Redox = "󰀘 "
Solus = "󰠳 "
SUSE = " "
Ubuntu = " "
Unknown = " "
Windows = "󰍲 "

[package]
symbol = "󰏗 "

[python]
symbol = " "

[rlang]
symbol = "󰟔 "

[ruby]
symbol = " "

[rust]
symbol = " "

[scala]
symbol = " "

[spack]
symbol = "🅢 "
EOL

# Ultimate Pro yapılandırmayı oluştur
cat >"$ULTIMATE_PRO_CONFIG" <<'EOL'
format = """
[](fg:#090c0c)\
$os\
$directory\
$git_branch\
$git_status\
[](fg:#1C2128 bg:#090c0c)\
$fill\
$nodejs\
$rust\
$golang\
$python\
$docker_context\
$cmd_duration\
$time\
[](fg:#090c0c)\
$line_break\
$character"""

[os]
format = "[$symbol]($style)"
style = "fg:#81A1C1 bg:#090c0c"

[directory]
style = "fg:#88C0D0 bg:#090c0c"
format = "[ $path ]($style)"
truncation_length = 3
truncate_to_repo = true
fish_style_pwd_dir_length = 1

[character]
success_symbol = "[󰁔](bold #A3BE8C)"
error_symbol = "[󰁔](bold #BF616A)"
vimcmd_symbol = "[󰁕](bold #81A1C1)"

[git_branch]
format = "[ $symbol$branch(:$remote_branch) ]($style)"
symbol = "󰘬 "
style = "fg:#8FBCBB bg:#090c0c"

[git_status]
format = '[$all_status$ahead_behind]($style)'
style = "fg:#BF616A bg:#090c0c"
conflicted = "≠"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕"
untracked = "?${count}"
stashed = "≡"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[cmd_duration]
format = "[ 󱎫 $duration]($style)"
style = "fg:#D08770 bg:#090c0c"
min_time = 1000

[time]
format = '[ 󰥔 $time ]($style)'
style = "fg:#B48EAD bg:#090c0c"
time_format = "%R"

[docker_context]
symbol = " "
style = "fg:#81A1C1 bg:#090c0c"
format = "[ $symbol$context ]($style)"

[nodejs]
symbol = "󰎙 "
style = "fg:#A3BE8C bg:#090c0c"
format = '[ $symbol($version) ]($style)'

[rust]
symbol = "󱘗 "
style = "fg:#D08770 bg:#090c0c"
format = '[ $symbol($version) ]($style)'

[golang]
symbol = "󰟓 "
style = "fg:#81A1C1 bg:#090c0c"
format = '[ $symbol($version) ]($style)'

[python]
symbol = "󰌠 "
style = "fg:#EBCB8B bg:#090c0c"
format = '[ $symbol($version) ]($style)'

[fill]
symbol = " "
EOL

# Mevcut yapılandırmayı kontrol et ve geçiş yap
check_current_config() {
  if cmp -s "$ACTIVE_CONFIG" "$ORIGINAL_CONFIG"; then
    echo "Pastel yapılandırmaya geçiliyor..."
    cp "$PASTEL_CONFIG" "$ACTIVE_CONFIG"
    echo "✨ Pastel tema aktif edildi!"
  elif cmp -s "$ACTIVE_CONFIG" "$PASTEL_CONFIG"; then
    echo "Ultimate yapılandırmaya geçiliyor..."
    cp "$ULTIMATE_CONFIG" "$ACTIVE_CONFIG"
    echo "✨ Ultimate tema aktif edildi!"
  elif cmp -s "$ACTIVE_CONFIG" "$ULTIMATE_CONFIG"; then
    echo "Ultimate Pro yapılandırmaya geçiliyor..."
    cp "$ULTIMATE_PRO_CONFIG" "$ACTIVE_CONFIG"
    echo "✨ Ultimate Pro tema aktif edildi!"
  else
    echo "Orijinal yapılandırmaya geçiliyor..."
    cp "$ORIGINAL_CONFIG" "$ACTIVE_CONFIG"
    echo "✨ Orijinal tema aktif edildi!"
  fi
}

# Ana fonksiyon
main() {
  if [ ! -f "$ACTIVE_CONFIG" ]; then
    echo "İlk kurulum yapılıyor..."
    cp "$ORIGINAL_CONFIG" "$ACTIVE_CONFIG"
    echo "✨ Orijinal tema aktif edildi!"
  else
    check_current_config
  fi

  echo "⚠️  Not: Yeni temanın aktif olması için terminal penceresini yeniden açmanız gerekebilir."
  echo "💡 İpucu: Ultimate, Ultimate Pro ve SUMO temaları için Nerd Font kurulu olması gereklidir."
}

# Scripti çalıştır
main
