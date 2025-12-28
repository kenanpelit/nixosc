#!/usr/bin/env bash
# osc-font-info - Show effective font configuration and defaults.
# - Uses Fontconfig (fc-match/fc-list) to report actual resolved fonts
# - Prints common desktop/tool overrides (GTK/Qt/Kitty, env vars)
set -euo pipefail

section() { printf '\n== %s ==\n' "$1"; }
kv() { printf '%-24s %s\n' "$1" "$2"; }
have() { command -v "$1" >/dev/null 2>&1; }

print_file_kv() {
  local label="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    kv "$label" "$file"
  else
    kv "$label" "(missing: $file)"
  fi
}

safe_grep() {
  local pattern="$1"
  local file="$2"
  [[ -f "$file" ]] || return 0
  grep -E "$pattern" "$file" 2>/dev/null || true
}

fc_match_chain() {
  local query="$1"
  local limit="${2:-8}"

  if ! have fc-match; then
    echo "(fc-match not found)"
    return 0
  fi

  # Tab-separated: family  style  file
  fc-match -s "$query" -f '%{family}\t%{style}\t%{file}\n' 2>/dev/null | head -n "$limit" || true
}

fc_match_first() {
  local query="$1"
  if ! have fc-match; then
    echo "(fc-match not found)"
    return 0
  fi
  fc-match "$query" -f '%{family} (%{style}) — %{file}\n' 2>/dev/null || true
}

main() {
  section "Session"
  kv "User" "${USER:-}"
  kv "Host" "$(hostname 2>/dev/null || true)"
  kv "XDG_SESSION_TYPE" "${XDG_SESSION_TYPE:-}"
  kv "XDG_SESSION_DESKTOP" "${XDG_SESSION_DESKTOP:-}"
  kv "XDG_CURRENT_DESKTOP" "${XDG_CURRENT_DESKTOP:-}"
  kv "DESKTOP_SESSION" "${DESKTOP_SESSION:-}"

  section "Env Overrides"
  for v in FONTCONFIG_FILE FONTCONFIG_PATH XDG_DATA_DIRS XDG_CONFIG_HOME GTK_FONT_NAME QT_FONT_DPI QT_STYLE_OVERRIDE; do
    [[ -n "${!v:-}" ]] && kv "$v" "${!v}"
  done

  section "Fontconfig"
  if have fc-match; then kv "fc-match" "$(command -v fc-match)"; fi
  if have fc-list; then kv "fc-list" "$(command -v fc-list)"; fi
  if have fc-cache; then kv "fc-cache" "$(command -v fc-cache)"; fi
  if have fc-match; then kv "fc-match --version" "$(fc-match --version 2>/dev/null | head -n 1)"; fi
  if have fc-cache; then kv "fc-cache -V" "$(fc-cache -V 2>/dev/null | head -n 1)"; fi

  print_file_kv "/etc/fonts/fonts.conf" "/etc/fonts/fonts.conf"
  print_file_kv "~/.config/fontconfig/fonts.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/fonts.conf"
  print_file_kv "~/.config/fontconfig/conf.d/" "${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"

  section "Default Matches (Resolved)"
  local queries=(
    "sans"
    "serif"
    "monospace"
    "system-ui"
    "emoji"
  )
  local q
  for q in "${queries[@]}"; do
    kv "$q" "$(fc_match_first "$q" | tr -d '\n')"
  done

  section "Fallback Chains (Top 8)"
  for q in "${queries[@]}"; do
    printf '\n-- %s --\n' "$q"
    if have column; then
      fc_match_chain "$q" 8 | column -t -s $'\t'
    else
      fc_match_chain "$q" 8
    fi
  done

  section "GTK Settings"
  local gtk3="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
  local gtk4="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"
  [[ -f "$gtk3" ]] && { kv "gtk-3.0" "$gtk3"; safe_grep '^(gtk-font-name|gtk-icon-theme-name)=' "$gtk3" | sed 's/^/  /'; }
  [[ -f "$gtk4" ]] && { kv "gtk-4.0" "$gtk4"; safe_grep '^(gtk-font-name|gtk-icon-theme-name)=' "$gtk4" | sed 's/^/  /'; }

  if have gsettings; then
    # Only print if schema exists; otherwise it spams errors.
    if gsettings writable org.gnome.desktop.interface font-name >/dev/null 2>&1; then
      kv "gsettings font-name" "$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || true)"
      kv "gsettings mono-font-name" "$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || true)"
      kv "gsettings text-scaling" "$(gsettings get org.gnome.desktop.interface text-scaling-factor 2>/dev/null || true)"
    fi
  fi

  section "Qt Settings"
  local qt5ct="${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct/qt5ct.conf"
  local qt6ct="${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/qt6ct.conf"
  [[ -f "$qt5ct" ]] && { kv "qt5ct" "$qt5ct"; safe_grep '^(font|icon_theme)=' "$qt5ct" | sed 's/^/  /'; }
  [[ -f "$qt6ct" ]] && { kv "qt6ct" "$qt6ct"; safe_grep '^(font|icon_theme)=' "$qt6ct" | sed 's/^/  /'; }

  section "Kitty (if configured)"
  local kittyConf="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
  if [[ -f "$kittyConf" ]]; then
    kv "kitty.conf" "$kittyConf"
    safe_grep '^(font_family|bold_font|italic_font|bold_italic_font|font_size)\\b' "$kittyConf" | sed 's/^/  /'
  else
    kv "kitty.conf" "(not found)"
  fi

  section "Quick List (First 30 fonts)"
  if have fc-list; then
    fc-list -f '%{family}\t%{style}\t%{file}\n' 2>/dev/null | head -n 30 | (have column && column -t -s $'\t' || cat)
  else
    echo "(fc-list not found)"
  fi
}

main "$@"

