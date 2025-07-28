#!/usr/bin/env bash

# =============================================================================
# CATPPUCCIN MOCHA THEME CONFIGURATION
# =============================================================================

echo "🎨 Catppuccin Mocha teması ayarları uygulanıyor..."

# Catppuccin Mocha renk paleti
MOCHA_BASE="#1e1e2e"
MOCHA_MANTLE="#181825"
MOCHA_CRUST="#11111b"
MOCHA_TEXT="#cdd6f4"
MOCHA_SUBTEXT1="#bac2de"
MOCHA_SUBTEXT0="#a6adc8"
MOCHA_OVERLAY2="#9399b2"
MOCHA_OVERLAY1="#7f849c"
MOCHA_OVERLAY0="#6c7086"
MOCHA_SURFACE2="#585b70"
MOCHA_SURFACE1="#45475a"
MOCHA_SURFACE0="#313244"
MOCHA_MAUVE="#cba6f7"
MOCHA_LAVENDER="#b4befe"
MOCHA_BLUE="#89b4fa"
MOCHA_SAPPHIRE="#74c7ec"
MOCHA_SKY="#89dceb"
MOCHA_TEAL="#94e2d5"
MOCHA_GREEN="#a6e3a1"
MOCHA_YELLOW="#f9e2af"
MOCHA_PEACH="#fab387"
MOCHA_MAROON="#eba0ac"
MOCHA_RED="#f38ba8"
MOCHA_PINK="#f5c2e7"
MOCHA_FLAMINGO="#f2cdcd"
MOCHA_ROSEWATER="#f5e0dc"

# =============================================================================
# GTK THEME SETTINGS (Catppuccin Mocha)
# =============================================================================
echo "🎨 GTK tema ayarları (Catppuccin Mocha)..."

dconf write /org/gnome/desktop/interface/gtk-theme "'catppuccin-mocha-mauve-standard+normal'"
dconf write /org/gnome/desktop/interface/icon-theme "'a-candy-beauty-icon-theme'"
dconf write /org/gnome/desktop/interface/cursor-theme "'catppuccin-mocha-dark-cursors'"
dconf write /org/gnome/desktop/interface/cursor-size "24"

# Shell tema
dconf write /org/gnome/shell/extensions/user-theme/name "'catppuccin-mocha-mauve-standard+normal'"

# =============================================================================
# WALLPAPER CONFIGURATION (Catppuccin)
# =============================================================================
echo "🖼️  Catppuccin duvar kağıdı ayarları..."

# Ana duvar kağıdı
WALLPAPER_PATH="$HOME/Pictures/wallpapers/catppuccin-mocha.jpg"
if [ -f "$WALLPAPER_PATH" ]; then
	dconf write /org/gnome/desktop/background/picture-uri "'file://$WALLPAPER_PATH'"
	dconf write /org/gnome/desktop/background/picture-uri-dark "'file://$WALLPAPER_PATH'"
	dconf write /org/gnome/desktop/background/picture-options "'zoom'"
	echo "✅ Duvar kağıdı ayarlandı: $WALLPAPER_PATH"
else
	# Fallback solid color
	dconf write /org/gnome/desktop/background/color-shading-type "'solid'"
	dconf write /org/gnome/desktop/background/primary-color "'$MOCHA_BASE'"
	dconf write /org/gnome/desktop/background/picture-options "'none'"
	echo "⚠️  Duvar kağıdı bulunamadı, solid renk kullanılıyor"
fi

# Lock screen duvar kağıdı
LOCKSCREEN_PATH="$HOME/Pictures/wallpapers/catppuccin-mocha-lockscreen.jpg"
if [ -f "$LOCKSCREEN_PATH" ]; then
	dconf write /org/gnome/desktop/screensaver/picture-uri "'file://$LOCKSCREEN_PATH'"
else
	dconf write /org/gnome/desktop/screensaver/color-shading-type "'solid'"
	dconf write /org/gnome/desktop/screensaver/primary-color "'$MOCHA_MANTLE'"
fi

# =============================================================================
# TERMINAL COLORS (Catppuccin Mocha için)
# =============================================================================
echo "💻 Terminal renk ayarları (Catppuccin Mocha)..."

# GNOME Terminal profili oluştur
TERMINAL_PROFILE_ID="catppuccin-mocha"
dconf write /org/gnome/terminal/legacy/profiles:/default "'$TERMINAL_PROFILE_ID'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/visible-name "'Catppuccin Mocha'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/use-theme-colors "false"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/use-theme-transparency "false"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/use-transparent-background "true"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/background-transparency-percent "10"

# Catppuccin Mocha terminal renkleri
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/background-color "'$MOCHA_BASE'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/foreground-color "'$MOCHA_TEXT'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/bold-color "'$MOCHA_TEXT'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/bold-color-same-as-fg "true"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/cursor-colors-set "true"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/cursor-background-color "'$MOCHA_ROSEWATER'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/cursor-foreground-color "'$MOCHA_BASE'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/highlight-colors-set "true"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/highlight-background-color "'$MOCHA_SURFACE2'"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/highlight-foreground-color "'$MOCHA_TEXT'"

# Terminal palet renkleri (16 renk)
TERMINAL_PALETTE="['$MOCHA_SURFACE1', '$MOCHA_RED', '$MOCHA_GREEN', '$MOCHA_YELLOW', '$MOCHA_BLUE', '$MOCHA_PINK', '$MOCHA_TEAL', '$MOCHA_SUBTEXT1', '$MOCHA_SURFACE2', '$MOCHA_RED', '$MOCHA_GREEN', '$MOCHA_YELLOW', '$MOCHA_BLUE', '$MOCHA_PINK', '$MOCHA_TEAL', '$MOCHA_SUBTEXT0']"
dconf write /org/gnome/terminal/legacy/profiles:/:$TERMINAL_PROFILE_ID/palette "$TERMINAL_PALETTE"

# =============================================================================
# EXTENSION THEMING (Catppuccin Mocha)
# =============================================================================
echo "🧩 Extension tema ayarları (Catppuccin Mocha)..."

# Dash to Panel - Catppuccin renkleri
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-element-positions-monitors-sync "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/trans-use-custom-bg "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/trans-bg-color "'$MOCHA_BASE'"
dconf write /org/gnome/shell/extensions/dash-to-panel/trans-use-custom-opacity "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/trans-panel-opacity "0.95"

# Vitals - Catppuccin renkleri
dconf write /org/gnome/shell/extensions/vitals/menu-centered "false"
dconf write /org/gnome/shell/extensions/vitals/use-higher-precision "false"

# Tiling Shell - Catppuccin accent
dconf write /org/gnome/shell/extensions/tilingshell/border-color "'$MOCHA_MAUVE'"
dconf write /org/gnome/shell/extensions/tilingshell/active-window-border-color "'$MOCHA_LAVENDER'"

# Space Bar - Catppuccin CSS güncelleme
SPACE_BAR_MOCHA_CSS='
.space-bar {
  -natural-hpadding: 12px;
  background-color: '"$MOCHA_BASE"';
}

.space-bar-workspace-label.active {
  margin: 0 4px;
  background-color: '"$MOCHA_MAUVE"';
  color: '"$MOCHA_BASE"';
  border-color: transparent;
  font-weight: 700;
  border-radius: 6px;
  border-width: 0px;
  padding: 4px 10px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.space-bar-workspace-label.inactive {
  margin: 0 4px;
  background-color: '"$MOCHA_SURFACE0"';
  color: '"$MOCHA_TEXT"';
  border-color: transparent;
  font-weight: 500;
  border-radius: 6px;
  border-width: 0px;
  padding: 4px 10px;
  transition: all 0.2s ease;
}

.space-bar-workspace-label.inactive:hover {
  background-color: '"$MOCHA_SURFACE1"';
  color: '"$MOCHA_SUBTEXT1"';
}

.space-bar-workspace-label.inactive.empty {
  margin: 0 4px;
  background-color: transparent;
  color: '"$MOCHA_OVERLAY0"';
  border-color: transparent;
  font-weight: 400;
  border-radius: 6px;
  border-width: 0px;
  padding: 4px 10px;
}
'

dconf write /org/gnome/shell/extensions/space-bar/appearance/application-styles "'$SPACE_BAR_MOCHA_CSS'"

# =============================================================================
# TEXT EDITOR THEME (Catppuccin Mocha)
# =============================================================================
echo "📝 Text Editor tema ayarları (Catppuccin Mocha)..."

dconf write /org/gnome/TextEditor/style-scheme "'catppuccin-mocha'"
dconf write /org/gnome/TextEditor/style-variant "'dark'"

# =============================================================================
# SYSTEM APPEARANCE TWEAKS
# =============================================================================
echo "⚙️  Sistem görünüm ayarları..."

# Accent color (GNOME 44+)
dconf write /org/gnome/desktop/interface/accent-color "'purple'"

# Window decorations
dconf write /org/gnome/desktop/wm/preferences/theme "'catppuccin-mocha-mauve-standard+normal'"
dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'$MAIN_FONT Bold $FONT_SIZE_SM'"

# Application menu
dconf write /org/gnome/desktop/wm/preferences/button-layout "'appmenu:minimize,maximize,close'"

# =============================================================================
# FILE MANAGER THEME (Nemo için)
# =============================================================================
echo "📁 Dosya yöneticisi tema ayarları..."

# Nemo için GTK CSS
NEMO_CSS_DIR="$HOME/.config/gtk-3.0"
mkdir -p "$NEMO_CSS_DIR"

cat >"$NEMO_CSS_DIR/gtk.css" <<EOF
/* Catppuccin Mocha Nemo Customizations */
.nemo-window {
    background-color: $MOCHA_BASE;
    color: $MOCHA_TEXT;
}

.nemo-window .toolbar {
    background-color: $MOCHA_MANTLE;
    border-bottom: 1px solid $MOCHA_SURFACE0;
}

.nemo-window .sidebar {
    background-color: $MOCHA_MANTLE;
    border-right: 1px solid $MOCHA_SURFACE0;
}

.nemo-window .view {
    background-color: $MOCHA_BASE;
    color: $MOCHA_TEXT;
}

.nemo-window .view:selected {
    background-color: $MOCHA_MAUVE;
    color: $MOCHA_BASE;
}
EOF

# =============================================================================
# CURSORS AND ICONS
# =============================================================================
echo "🎯 Cursor ve ikon ayarları..."

# Cursor size for HiDPI
if xrandr | grep -q "3840x2160\|2560x1440"; then
	dconf write /org/gnome/desktop/interface/cursor-size "32"
	echo "🖥️  HiDPI ekran tespit edildi, cursor boyutu 32'ye ayarlandı"
else
	dconf write /org/gnome/desktop/interface/cursor-size "24"
fi

# =============================================================================
# NOTIFICATION STYLING
# =============================================================================
echo "🔔 Bildirim ayarları..."

# Notification timeout
dconf write /org/gnome/desktop/notifications/show-in-lock-screen "false"
dconf write /org/gnome/desktop/notifications/show-banners "true"

# =============================================================================
# CATPPUCCIN ENVIRONMENT VARIABLES
# =============================================================================
echo "🌍 Catppuccin ortam değişkenleri..."

# ~/.profile dosyasına ekle
PROFILE_FILE="$HOME/.profile"
if ! grep -q "CATPPUCCIN_THEME" "$PROFILE_FILE" 2>/dev/null; then
	cat >>"$PROFILE_FILE" <<EOF

# Catppuccin Mocha Theme Environment
export CATPPUCCIN_THEME="mocha"
export CATPPUCCIN_ACCENT="mauve"
export GTK_THEME="catppuccin-mocha-mauve-standard+normal"
export XCURSOR_THEME="catppuccin-mocha-dark-cursors"
export XCURSOR_SIZE="24"
EOF
	echo "✅ Catppuccin ortam değişkenleri ~/.profile'a eklendi"
fi

# =============================================================================
# THEME VALIDATION
# =============================================================================
echo "✅ Catppuccin Mocha tema doğrulaması..."

# GTK tema kontrolü
if gsettings get org.gnome.desktop.interface gtk-theme | grep -q "catppuccin-mocha"; then
	echo "✅ GTK teması: Catppuccin Mocha aktif"
else
	echo "⚠️  GTK teması: Catppuccin Mocha aktif değil"
fi

# Icon tema kontrolü
if gsettings get org.gnome.desktop.interface icon-theme | grep -q "candy-beauty"; then
	echo "✅ İkon teması: Candy Beauty aktif"
else
	echo "⚠️  İkon teması: Varsayılan kullanılıyor"
fi

# Cursor tema kontrolü
if gsettings get org.gnome.desktop.interface cursor-theme | grep -q "catppuccin-mocha"; then
	echo "✅ Cursor teması: Catppuccin Mocha aktif"
else
	echo "⚠️  Cursor teması: Catppuccin Mocha aktif değil"
fi

echo ""
echo "🎨 Catppuccin Mocha tema konfigürasyonu tamamlandı!"
echo ""
echo "🔧 Manuel kontrol için:"
echo "   gsettings get org.gnome.desktop.interface gtk-theme"
echo "   gsettings get org.gnome.desktop.interface icon-theme"
echo "   gsettings get org.gnome.desktop.interface cursor-theme"
echo ""
echo "📁 Tema dosyaları lokasyonu:"
echo "   ~/.themes/ (GTK temaları)"
echo "   ~/.icons/ (İkon temaları)"
echo "   ~/.local/share/icons/ (Cursor temaları)"
echo ""
echo "🔄 Değişikliklerin tam olarak uygulanması için logout/login yapın"
