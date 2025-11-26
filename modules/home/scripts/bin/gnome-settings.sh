#!/usr/bin/env bash
# ==============================================================================
# Complete GNOME Configuration Script for NixOS with Catppuccin Mocha Theme
# Tüm DConf ayarlarını manuel olarak uygular
# ==============================================================================

set -euo pipefail

# Log dizinini oluştur
LOG_DIR="$HOME/.logs"
LOG_FILE="$LOG_DIR/gnome_settings_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

# Debug mode'u aktif et ve log'a yönlendir
exec > >(tee -a "$LOG_FILE") 2>&1
set -x

echo "🚀 GNOME Complete Configuration başlatılıyor..."
echo "📝 Log dosyası: $LOG_FILE"
echo "🕐 Başlama zamanı: $(date)"

# Font ayarları
MAIN_FONT="Maple Mono NF"
EDITOR_FONT="Maple Mono NF"
TERMINAL_FONT="Hack Nerd Font"
FONT_SIZE_SM="12"
FONT_SIZE_MD="13"
FONT_SIZE_XL="15"

# =============================================================================
# CATPPUCCIN MOCHA RENK PALETİ
# =============================================================================
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

echo "📝 Mevcut ayarları temizleniyor..."
# Sadece custom keybinding'leri temizle, diğerlerini koru
dconf reset -f /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/

# =============================================================================
# TEXT EDITOR CONFIGURATION
# =============================================================================
echo "📄 Text Editor ayarları uygulanıyor..."

dconf write /org/gnome/TextEditor/custom-font "'$EDITOR_FONT $FONT_SIZE_XL'"
dconf write /org/gnome/TextEditor/highlight-current-line "true"
dconf write /org/gnome/TextEditor/indent-style "'space'"
dconf write /org/gnome/TextEditor/restore-session "false"
dconf write /org/gnome/TextEditor/show-grid "false"
dconf write /org/gnome/TextEditor/show-line-numbers "true"
dconf write /org/gnome/TextEditor/show-right-margin "false"
dconf write /org/gnome/TextEditor/style-scheme "'catppuccin-mocha'"
dconf write /org/gnome/TextEditor/style-variant "'dark'"
dconf write /org/gnome/TextEditor/tab-width "uint32 4"
dconf write /org/gnome/TextEditor/use-system-font "false"
dconf write /org/gnome/TextEditor/wrap-text "false"

# =============================================================================
# INTERFACE CONFIGURATION
# =============================================================================
echo "🎨 Interface ayarları uygulanıyor..."

dconf write /org/gnome/desktop/interface/font-name "'$MAIN_FONT $FONT_SIZE_SM'"
dconf write /org/gnome/desktop/interface/document-font-name "'$MAIN_FONT $FONT_SIZE_SM'"
dconf write /org/gnome/desktop/interface/monospace-font-name "'$TERMINAL_FONT $FONT_SIZE_SM'"
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/font-antialiasing "'grayscale'"
dconf write /org/gnome/desktop/interface/font-hinting "'slight'"
dconf write /org/gnome/desktop/interface/show-battery-percentage "true"
dconf write /org/gnome/desktop/interface/clock-show-weekday "true"
dconf write /org/gnome/desktop/interface/clock-show-date "true"
dconf write /org/gnome/desktop/interface/enable-animations "true"

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

# Accent color (GNOME 44+)
dconf write /org/gnome/desktop/interface/accent-color "'purple'"

# Window decorations
dconf write /org/gnome/desktop/wm/preferences/theme "'catppuccin-mocha-mauve-standard+normal'"
dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'$MAIN_FONT Bold $FONT_SIZE_SM'"

# Application menu
dconf write /org/gnome/desktop/wm/preferences/button-layout "'appmenu'"

# =============================================================================
# WALLPAPER CONFIGURATION (Catppuccin)
# =============================================================================
echo "🖼️  Catppuccin duvar kağıdı ayarları..."

# Ana duvar kağıdı
WALLPAPER_PATH="$HOME/Pictures/wallpapers/others/54.jpg"
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
LOCKSCREEN_PATH="$HOME/Pictures/wallpapers/others/54.jpg"
if [ -f "$LOCKSCREEN_PATH" ]; then
  dconf write /org/gnome/desktop/screensaver/picture-uri "'file://$LOCKSCREEN_PATH'"
else
  dconf write /org/gnome/desktop/screensaver/color-shading-type "'solid'"
  dconf write /org/gnome/desktop/screensaver/primary-color "'$MOCHA_MANTLE'"
fi

# =============================================================================
# AZWALLPAPER (WALLPAPER SLIDESHOW) CONFIGURATION
# =============================================================================
echo "🖼️  AzWallpaper (Wallpaper Slideshow) ayarları uygulanıyor..."

# Wallpaper dizini
WALLPAPER_DIR="$HOME/Pictures/wallpapers/others"
BING_DOWNLOAD_DIR="$HOME/Pictures/bing"

# Wallpaper dizinlerini oluştur
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$BING_DOWNLOAD_DIR"

# Temel ayarlar
dconf write /org/gnome/shell/extensions/azwallpaper/slideshow-directory "'$WALLPAPER_DIR'"
dconf write /org/gnome/shell/extensions/azwallpaper/bing-download-directory "'$BING_DOWNLOAD_DIR'"
dconf write /org/gnome/shell/extensions/azwallpaper/bing-wallpaper-download "true"

# Slideshow zamanlaması - 5 dakikada bir değişsin (0 saat, 5 dakika, 0 saniye)
dconf write /org/gnome/shell/extensions/azwallpaper/slideshow-slide-duration "(0, 5, 0)"
dconf write /org/gnome/shell/extensions/azwallpaper/slideshow-use-absolute-time-for-duration "true"

# Preferences sayfası (boş - varsayılan)
dconf write /org/gnome/shell/extensions/azwallpaper/prefs-visible-page "''"

# Update notifier
dconf write /org/gnome/shell/extensions/azwallpaper/update-notifier-project-version "16"

echo "✅ AzWallpaper ayarları tamamlandı"
echo "   📁 Wallpaper dizini: $WALLPAPER_DIR"
echo "   📁 Bing indirme dizini: $BING_DOWNLOAD_DIR"
echo "   ⏱️  Değişim süresi: 5 dakika"
echo "   🌐 Bing otomatik indirme: Aktif"

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
# WINDOW MANAGER KEYBINDINGS
# =============================================================================
echo "⌨️  Window Manager keybinding'leri uygulanıyor..."

# Basic window management
dconf write /org/gnome/desktop/wm/keybindings/close "['<Super>q']"
dconf write /org/gnome/desktop/wm/keybindings/toggle-fullscreen "['<Super>f']"
dconf write /org/gnome/desktop/wm/keybindings/toggle-maximized "['<Super>m']"
dconf write /org/gnome/desktop/wm/keybindings/minimize "['<Super>h']"
dconf write /org/gnome/desktop/wm/keybindings/show-desktop "['<Super>d']"
dconf write /org/gnome/desktop/wm/keybindings/switch-applications "['<Alt>Tab']"
dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "['<Shift><Alt>Tab']"
dconf write /org/gnome/desktop/wm/keybindings/switch-windows "['<Super>Tab']"
dconf write /org/gnome/desktop/wm/keybindings/switch-windows-backward "['<Shift><Super>Tab']"

# Workspace switching - DISABLED for custom history support
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-1 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-2 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-3 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-4 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-5 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-6 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-7 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-8 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-9 "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-10 "@as []"

# Move window to workspace
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-1 "['<Super><Shift>1']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-2 "['<Super><Shift>2']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-3 "['<Super><Shift>3']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-4 "['<Super><Shift>4']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-5 "['<Super><Shift>5']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-6 "['<Super><Shift>6']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-7 "['<Super><Shift>7']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-8 "['<Super><Shift>8']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-9 "['<Super><Shift>9']"

# Navigate workspaces with arrows - DISABLED
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-up "@as []"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-down "@as []"

# Move window between workspaces
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-left "['<Super><Shift>Left']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-right "['<Super><Shift>Right']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-up "['<Super><Shift>Up']"
dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-down "['<Super><Shift>Down']"

# =============================================================================
# SHELL KEYBINDINGS
# =============================================================================
echo "🐚 Shell keybinding'leri uygulanıyor..."

dconf write /org/gnome/shell/keybindings/show-applications "['<Super>a']"
dconf write /org/gnome/shell/keybindings/show-screenshot-ui "['<Super>Print']"
dconf write /org/gnome/shell/keybindings/toggle-overview "['<Super>s']"

# Application switching keybinding'larını kapat (workspace çakışması için)
dconf write /org/gnome/shell/keybindings/switch-to-application-1 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-2 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-3 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-4 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-5 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-6 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-7 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-8 "@as []"
dconf write /org/gnome/shell/keybindings/switch-to-application-9 "@as []"

# =============================================================================
# NIGHT LIGHT (Mavi ışık filtresi)
# =============================================================================
echo "🌙 Night Light ayarları uygulanıyor..."

# 00:00 - 00:00 (24 saat) ve örnek sıcaklık değeri
NIGHT_LIGHT_FROM="0.0" # 00:00
NIGHT_LIGHT_TO="0.0"   # 00:00 (GNOME çoğu sürümde 24h anlamına gelir)
NIGHT_LIGHT_TEMP=2800  # 1000–10000 arası (daha sıcak = daha sarı)

dconf write /org/gnome/settings-daemon/plugins/color/night-light-enabled true
dconf write /org/gnome/settings-daemon/plugins/color/night-light-schedule-automatic false
dconf write /org/gnome/settings-daemon/plugins/color/night-light-temperature "uint32 $NIGHT_LIGHT_TEMP"
dconf write /org/gnome/settings-daemon/plugins/color/night-light-schedule-from "$NIGHT_LIGHT_FROM"
dconf write /org/gnome/settings-daemon/plugins/color/night-light-schedule-to "$NIGHT_LIGHT_TO"

# Not: Bazı GNOME derlemelerinde 0.0→0.0 tam-gün davranmıyorsa,
# yalnızca aşağıdaki satırı 24.0 yapman yeterli olur:
# dconf write /org/gnome/settings-daemon/plugins/color/night-light-schedule-to "24.0"

# =============================================================================
# MUTTER SETTINGS
# =============================================================================
echo "🪟 Mutter ayarları uygulanıyor..."

dconf write /org/gnome/mutter/edge-tiling "true"
dconf write /org/gnome/mutter/dynamic-workspaces "false"
dconf write /org/gnome/mutter/workspaces-only-on-primary "false"
dconf write /org/gnome/mutter/center-new-windows "true"
dconf write /org/gnome/mutter/focus-change-on-pointer-rest "true"
dconf write /org/gnome/mutter/auto-maximize "false"
dconf write /org/gnome/mutter/attach-modal-dialogs "true"

# =============================================================================
# WORKSPACE SETTINGS
# =============================================================================
echo "🏢 Workspace ayarları uygulanıyor..."

dconf write /org/gnome/desktop/wm/preferences/num-workspaces "9"
dconf write /org/gnome/desktop/wm/preferences/workspace-names "['1', '2', '3', '4', '5', '6', '7', '8', '9']"
dconf write /org/gnome/desktop/wm/preferences/focus-mode "'click'"
dconf write /org/gnome/desktop/wm/preferences/focus-new-windows "'smart'"
dconf write /org/gnome/desktop/wm/preferences/auto-raise "false"
dconf write /org/gnome/desktop/wm/preferences/raise-on-click "true"

# =============================================================================
# SHELL SETTINGS
# =============================================================================
echo "🐚 Shell ayarları uygulanıyor..."

dconf write /org/gnome/shell/favorite-apps "['brave-browser.desktop', 'kitty.desktop']"

# Extensions - NixOS'ta yüklü olanlar
EXTENSIONS="[
'alt-tab-scroll-workaround@lucasresck.github.io',
'auto-move-windows@gnome-shell-extensions.gcampax.github.com',
'azwallpaper@azwallpaper.gitlab.com',
'bluetooth-quick-connect@bjarosze.gmail.com',
'clipboard-indicator@tudmotu.com',
'dash-to-panel@jderose9.github.com',
'disable-workspace-animation@ethnarque',
'extension-list@tu.berry',
'gsconnect@andyholmes.github.io',
'just-perfection-desktop@just-perfection',
'mediacontrols@cliffniff.github.com',
'mullvadindicator@pobega.github.com',
'no-overview@fthx',
'no-titlebar-when-maximized@alec.ninja',
'quick-settings-tweaks@qwreey',
'screenshort-cut@pauloimon',
'sound-percentage@subashghimire.info.np',
'space-bar@luchrioh',
'tilingshell@ferrarodomenico.com',
'tophat@fflewddur.github.io',
'trayIconsReloaded@selfmade.pl',
'weatheroclock@CleoMenezesJr.github.io',
'window-centering@hnjjhmtr27',
'zetadev@bootpaper'
]"

dconf write /org/gnome/shell/enabled-extensions "$EXTENSIONS"
dconf write /org/gnome/shell/disabled-extensions "@as []"

# =============================================================================
# APP SWITCHER SETTINGS
# =============================================================================
echo "🔄 App switcher ayarları uygulanıyor..."

dconf write /org/gnome/shell/app-switcher/current-workspace-only "false"
dconf write /org/gnome/shell/window-switcher/current-workspace-only "true"

# =============================================================================
# EXTENSION CONFIGURATIONS
# =============================================================================
echo "🧩 Extension ayarları uygulanıyor..."

# Clipboard Indicator
dconf write /org/gnome/shell/extensions/clipboard-indicator/toggle-menu "['<Super>v']"
dconf write /org/gnome/shell/extensions/clipboard-indicator/clear-history "@as []"
dconf write /org/gnome/shell/extensions/clipboard-indicator/prev-entry "@as []"
dconf write /org/gnome/shell/extensions/clipboard-indicator/next-entry "@as []"
dconf write /org/gnome/shell/extensions/clipboard-indicator/cache-size "50"
dconf write /org/gnome/shell/extensions/clipboard-indicator/display-mode "0"

# GSConnect
dconf write /org/gnome/shell/extensions/gsconnect/show-indicators "true"
dconf write /org/gnome/shell/extensions/gsconnect/show-offline "false"

# Bluetooth Quick Connect
dconf write /org/gnome/shell/extensions/bluetooth-quick-connect/show-battery-icon-on "true"
dconf write /org/gnome/shell/extensions/bluetooth-quick-connect/show-battery-value-on "true"

# Vitals
dconf write /org/gnome/shell/extensions/vitals/hot-sensors "['_processor_usage_', '_memory_usage_', '_network-rx_max_', '_network-tx_max_']"
dconf write /org/gnome/shell/extensions/vitals/position-in-panel "2"
dconf write /org/gnome/shell/extensions/vitals/use-higher-precision "false"
dconf write /org/gnome/shell/extensions/vitals/alphabetize "true"
dconf write /org/gnome/shell/extensions/vitals/include-static-info "false"
dconf write /org/gnome/shell/extensions/vitals/show-icons "true"
dconf write /org/gnome/shell/extensions/vitals/show-battery "true"
dconf write /org/gnome/shell/extensions/vitals/unit-fahrenheit "false"
dconf write /org/gnome/shell/extensions/vitals/memory-measurement "0"
dconf write /org/gnome/shell/extensions/vitals/network-speed-format "1"
dconf write /org/gnome/shell/extensions/vitals/storage-measurement "0"
dconf write /org/gnome/shell/extensions/vitals/hide-zeros "true"
dconf write /org/gnome/shell/extensions/vitals/menu-centered "false"

# Spotify Controls
dconf write /org/gnome/shell/extensions/spotify-controls/show-track-info "false"
dconf write /org/gnome/shell/extensions/spotify-controls/position "'middle-right'"
dconf write /org/gnome/shell/extensions/spotify-controls/show-notifications "true"
dconf write /org/gnome/shell/extensions/spotify-controls/track-length "30"
dconf write /org/gnome/shell/extensions/spotify-controls/show-pause-icon "true"
dconf write /org/gnome/shell/extensions/spotify-controls/show-next-icon "true"
dconf write /org/gnome/shell/extensions/spotify-controls/show-prev-icon "true"
dconf write /org/gnome/shell/extensions/spotify-controls/button-color "'default'"
dconf write /org/gnome/shell/extensions/spotify-controls/hide-on-no-spotify "true"
dconf write /org/gnome/shell/extensions/spotify-controls/show-volume-control "false"
dconf write /org/gnome/shell/extensions/spotify-controls/show-album-art "false"
dconf write /org/gnome/shell/extensions/spotify-controls/compact-mode "true"

# Auto Move Windows
AUTO_MOVE_LIST="[
'brave-browser.desktop:1',
'kitty.desktop:2',
'discord.desktop:5',
'webcord.desktop:5',
'whatsie.desktop:9',
'ferdium.desktop:9',
'spotify.desktop:8',
'brave-agimnkijcaahngcdmfeangaknmldooml-Default.desktop:7'
]"
dconf write /org/gnome/shell/extensions/auto-move-windows/application-list "$AUTO_MOVE_LIST"

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
# PRIVACY SETTINGS
# =============================================================================
echo "🔒 Privacy ayarları uygulanıyor..."

dconf write /org/gnome/desktop/privacy/report-technical-problems "false"
dconf write /org/gnome/desktop/privacy/send-software-usage-stats "false"
dconf write /org/gnome/desktop/privacy/disable-microphone "false"
dconf write /org/gnome/desktop/privacy/disable-camera "false"

# =============================================================================
# POWER SETTINGS
# =============================================================================
echo "⚡ Power ayarları uygulanıyor..."

dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type "'suspend'"
dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout "3600"
dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type "'suspend'"
dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-timeout "3600"
dconf write /org/gnome/settings-daemon/plugins/power/power-button-action "'interactive'"
dconf write /org/gnome/settings-daemon/plugins/power/handle-lid-switch "false"

# =============================================================================
# SESSION SETTINGS
# =============================================================================
echo "🖥️  Session ayarları uygulanıyor..."

dconf write /org/gnome/desktop/session/idle-delay "uint32 0"

# =============================================================================
# TOUCHPAD SETTINGS
# =============================================================================
echo "👆 Touchpad ayarları uygulanıyor..."

dconf write /org/gnome/desktop/peripherals/touchpad/tap-to-click "true"
dconf write /org/gnome/desktop/peripherals/touchpad/two-finger-scrolling-enabled "true"
dconf write /org/gnome/desktop/peripherals/touchpad/natural-scroll "false"
dconf write /org/gnome/desktop/peripherals/touchpad/disable-while-typing "true"
dconf write /org/gnome/desktop/peripherals/touchpad/click-method "'fingers'"
dconf write /org/gnome/desktop/peripherals/touchpad/send-events "'enabled'"
dconf write /org/gnome/desktop/peripherals/touchpad/speed "0.8"
dconf write /org/gnome/desktop/peripherals/touchpad/accel-profile "'default'"
dconf write /org/gnome/desktop/peripherals/touchpad/scroll-method "'two-finger-scrolling'"
dconf write /org/gnome/desktop/peripherals/touchpad/middle-click-emulation "false"

# =============================================================================
# MOUSE SETTINGS
# =============================================================================
echo "🖱️  Mouse ayarları uygulanıyor..."

dconf write /org/gnome/desktop/peripherals/mouse/natural-scroll "false"
dconf write /org/gnome/desktop/peripherals/mouse/speed "0.0"

# =============================================================================
# SOUND SETTINGS
# =============================================================================
echo "🔊 Sound ayarları uygulanıyor..."

dconf write /org/gnome/desktop/sound/event-sounds "true"
dconf write /org/gnome/desktop/sound/theme-name "'freedesktop'"

# =============================================================================
# SCREENSAVER SETTINGS
# =============================================================================
echo "🔒 Screensaver ayarları uygulanıyor..."

dconf write /org/gnome/desktop/screensaver/lock-enabled "true"
dconf write /org/gnome/desktop/screensaver/lock-delay "uint32 0"
dconf write /org/gnome/desktop/screensaver/idle-activation-enabled "true"

## =============================================================================
## LOCK SCREEN DISABLE (AUTOLOGIN İÇİN)
## =============================================================================
#echo "🔓 Kilit ekranı devre dışı bırakılıyor (autologin için)..."

#dconf write /org/gnome/desktop/lockdown/disable-lock-screen "true"
#dconf write /org/gnome/desktop/screensaver/lock-enabled "false"
#dconf write /org/gnome/desktop/screensaver/idle-activation-enabled "false"
#dconf write /org/gnome/desktop/session/idle-delay "uint32 0"

#echo "✅ Kilit ekranı tamamen devre dışı bırakıldı"

# =============================================================================
# LOCK SCREEN SETTINGS
# =============================================================================
echo "🔒 Kilit ekranı ayarları yapılıyor..."

dconf write /org/gnome/desktop/lockdown/disable-lock-screen "false"
dconf write /org/gnome/desktop/screensaver/lock-enabled "true"
dconf write /org/gnome/desktop/screensaver/lock-delay "uint32 0"
dconf write /org/gnome/desktop/screensaver/idle-activation-enabled "true"
dconf write /org/gnome/desktop/session/idle-delay "uint32 1800"

echo "✅ Kilit ekranı aktif (30 dakika idle sonra, Alt+L ile manuel)"
# =============================================================================
# NAUTILUS SETTINGS
# =============================================================================
echo "📁 Nautilus ayarları uygulanıyor..."

dconf write /org/gnome/nautilus/preferences/default-folder-viewer "'list-view'"
dconf write /org/gnome/nautilus/preferences/search-filter-time-type "'last_modified'"
dconf write /org/gnome/nautilus/preferences/show-hidden-files "false"
dconf write /org/gnome/nautilus/preferences/show-create-link "true"

dconf write /org/gnome/nautilus/list-view/use-tree-view "true"
dconf write /org/gnome/nautilus/list-view/default-zoom-level "'small'"

# =============================================================================
# FILE MANAGER THEME (Nemo için Catppuccin)
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
  dconf write /org/gnome/desktop/interface/cursor-size "24"
  echo "🖥️  HiDPI ekran tespit edildi, cursor boyutu 32'ye ayarlandı"
else
  dconf write /org/gnome/desktop/interface/cursor-size "20"
fi

# =============================================================================
# NOTIFICATION STYLING
# =============================================================================
echo "🔔 Bildirim ayarları..."

# Notification timeout
dconf write /org/gnome/desktop/notifications/show-in-lock-screen "false"
dconf write /org/gnome/desktop/notifications/show-banners "true"

# =============================================================================
# CUSTOM KEYBINDINGS (0..40) — absolute paths, no PATH lookups
# =============================================================================
echo "⌨️  Custom keybinding'ler (0..40) yazılıyor..."

# --- helpers: resolve absolute paths
opt() {
  local n="$1"
  local cand

  # 1) PATH içinde varsa
  cand="$(command -v "$n" 2>/dev/null || true)"
  if [ -n "$cand" ] && [ -x "$cand" ]; then
    printf '%s' "$cand"
    return 0
  fi

  # 2) NixOS'ta yaygın dizinler
  for cand in \
    "/etc/profiles/per-user/$USER/bin/$n" \
    "$HOME/.local/bin/$n" \
    "$HOME/.nix-profile/bin/$n" \
    "/run/current-system/sw/bin/$n"; do
    if [ -x "$cand" ]; then
      printf '%s' "$cand"
      return 0
    fi
  done

  # 3) yoksa son çare isim (ama bu gecikme demek!)
  printf '%s' "$n"
}

KITTY="$(opt kitty)"
BRAVE="$(opt brave || opt brave-browser)"
YAZI="$(opt yazi)"
NEMO="$(opt nemo)"
WALKER="$(opt walker)"
COPYQ="$(opt copyq)"
WEBCORD="$(opt webcord)"
WMCTRL="$(opt wmctrl)"
LOGINCTL="$(opt loginctl)"

OSC_SOUNDCTL="$(opt osc-soundctl)"
OSC_SPOTIFY="$(opt osc-spotify)"
OSC_REBOOT="$(opt osc-safe-reboot)"
BLUE_TOGGLE="$(opt bluetooth_toggle)"
MPV_MGR="$(opt gnome-mpv-manager)"
KKENP="$(opt start-kkenp)"
SEM_SUMO="$(opt semsumo)"
WORKSW="$(opt workspace-switcher)"
WSPREV="$(opt ws-prev)"
WSNEXT="$(opt ws-next)"
MULLVAD="$(opt osc-mullvad)"
SCREENSHOT="$(opt gnome-screenshot)"
GKR="$(opt gnome-kr-fix)"
WALK="$(opt walk)"

# 0..40 path list
CUSTOM_PATHS=""
for i in {0..43}; do
  p="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${i}/"
  if [ -z "$CUSTOM_PATHS" ]; then
    CUSTOM_PATHS="'$p'"
  else
    CUSTOM_PATHS="$CUSTOM_PATHS, '$p'"
  fi
done
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "[ $CUSTOM_PATHS ]"

# 0) Terminal
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Super>Return'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'$KITTY'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'Terminal'"

# 1) Browser
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/binding "'<Super>b'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/command "'$BRAVE'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/name "'Browser'"

# 2) Terminal FM (floating yazi)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/binding "'<Super>e'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/command "'$KITTY --class floating-terminal -e $YAZI'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/name "'Terminal File Manager (Floating)'"

# 3) Nemo
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/binding "'<Alt><Ctrl>f'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/command "'$NEMO'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/name "'Open Nemo File Manager'"

# 4) Terminal FM (yazi)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/binding "'<Alt>f'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/command "'$KITTY $YAZI'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/name "'Terminal File Manager (Yazi)'"

# 5) Walker
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/binding "'<Super><Alt>space'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/command "'$WALKER'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/name "'Open Walker'"

# 6) Audio output switch
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/binding "'<Alt>a'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/command "'$OSC_SOUNDCTL switch'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/name "'Switch Audio Output'"

# 7) Mic switch
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/binding "'<Alt><Ctrl>a'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/command "'$OSC_SOUNDCTL switch-mic'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/name "'Switch Microphone'"

# 8) Spotify toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/binding "'<Alt>e'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/command "'$OSC_SPOTIFY'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/name "'Spotify Toggle'"

# 9) Spotify next
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/binding "'<Alt><Ctrl>n'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/command "'$OSC_SPOTIFY next'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/name "'Spotify Next'"

# 10) Spotify prev
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/binding "'<Alt><Ctrl>b'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/command "'$OSC_SPOTIFY prev'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/name "'Spotify Previous'"

# 11) MPV start/focus
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/binding "'<Alt>i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/command "'$MPV_MGR start'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/name "'MPV Start/Focus'"

# 12) Lock screen
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/binding "'<Alt>l'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/command "'$LOGINCTL lock-session'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/name "'Lock Screen'"

# 13) Prev workspace
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/binding "'<Super><Alt>Left'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/command "'$WSPREV'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/name "'Previous Workspace'"

# 14) Next workspace
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/binding "'<Super><Alt>Right'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/command "'$WSNEXT'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/name "'Next Workspace'"

# 15) Discord (WebCord)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/binding "'<Super><Shift>d'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/command "'$WEBCORD --enable-features=UseOzonePlatform --ozone-platform=wayland'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/name "'Open Discord'"

# 16) KKENP
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/binding "'<Alt>t'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/command "'$KKENP'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/name "'Start KKENP'"

# 17) Notes Manager
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/binding "'<Super>n'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/command "'anotes -M'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/name "'Notes Manager'"

# 18) Clipboard (CopyQ)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/binding "'<Alt>v'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/command "'$COPYQ toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/name "'Clipboard Manager'"

# 19) Bluetooth toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/binding "'F10'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/command "'$BLUE_TOGGLE'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/name "'Bluetooth Toggle'"

# 20) Mullvad toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/binding "'<Alt>F12'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/command "'osc-mullvad toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/name "'Mullvad Toggle'"

# 21) Gnome Start
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/binding "'<Super><Alt>Return'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/command "'$SEM_SUMO launch --daily'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/name "'Gnome Start'"

# 22) Screenshot UI
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/binding "'<Super><Shift>s'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/command "'gnome-screenshot -i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/name "'Screenshot Tool'"

# 23) MPV Move
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/binding "'<Alt><Shift>i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/command "'$MPV_MGR move'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/name "'MPV Move Window'"

# 24) MPV Resize
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/binding "'<Alt><Ctrl>i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/command "'$MPV_MGR resize'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/name "'MPV Resize Center'"

# 25) Play YouTube (clipboard)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/binding "'<Alt>y'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/command "'$MPV_MGR play-yt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/name "'Play YouTube from Clipboard'"

# 26) Save YouTube
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/binding "'<Alt><Shift>y'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/command "'$MPV_MGR save-yt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/name "'Download YouTube Video'"

# 27) MPV Toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/binding "'<Alt>p'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/command "'$MPV_MGR playback'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/name "'MPV Toggle Playback'"

# 28..36) Workspaces 1..9 (history switcher)
for i in {1..9}; do
  idx=$((27 + i)) # 28..36
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/binding "'<Super>$i'"
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/command "'$WORKSW $i'"
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/name "'Workspace $i (with history)'"
done

# 37) Shutdown
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/binding "'<Ctrl><Alt><Shift>s'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/command "'gnome-session-quit --power-off --no-prompt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/name "'Shutdown Computer'"

# 38) Restart
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/binding "'<Ctrl><Alt>r'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/command "'gnome-session-quit --reboot --no-prompt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/name "'Restart Computer'"

# 39) Logout
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/binding "'<Ctrl><Alt>q'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/command "'gnome-session-quit --logout --no-prompt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/name "'Logout'"

# 40) Power menu (confirm)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/binding "'<Ctrl><Alt>p'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/command "'gnome-session-quit --power-off'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/name "'Power Menu (with confirmation)'"

# 41) GKR
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom41/binding "'<Super><Ctrl>F12'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom41/command "'$GKR'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom41/name "'GNOME GKR'"

# 42) Walker
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom42/binding "'<Super>space'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom42/command "'$WALK'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom42/name "'WalkerS'"

# 43) Safe Reboot
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom43/binding "'<Super>backspace'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom43/command "'$OSC_REBOOT'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom43/name "'OSC Reboot'"

# =============================================================================
# GNOME'UN VARSAYILAN SUPER+[1-9] KISA YOLLARINI KAPAT
# =============================================================================
echo "🚫 GNOME varsayılan Super+[1-9] kısayolları devre dışı bırakılıyor..."

# Uygulama başlatma kısayollarını kapat (Super+[1-9])
for i in {1..9}; do
  dconf write /org/gnome/shell/keybindings/switch-to-application-$i "@as []"
done

# Workspace geçiş kısayollarını kapat (Super+[1-9])
for i in {1..9}; do
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-$i "@as []"
  #dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-$i "@as []"
done

# Space Bar extension'ının workspace switching kısayolunu kapat
echo "🔧 Space Bar extension kısayolları devre dışı bırakılıyor..."
dconf write /org/gnome/shell/extensions/space-bar/shortcuts/enable-activate-workspace-shortcuts false

echo "✅ Varsayılan Super+[1-9] kısayolları kapatıldı."
echo "💡 Artık sadece Alt+[1-9] ile workspace geçişi yapabilirsiniz."

# =============================================================================
# EXTENSION COMPLEX CONFIGURATIONS
# =============================================================================
echo "🎨 Karmaşık extension ayarları uygulanıyor..."

# Dash to Panel - JSON Configuration
echo "📊 Dash to Panel ayarları..."

dconf write /org/gnome/shell/extensions/dash-to-panel/appicon-margin "8"
dconf write /org/gnome/shell/extensions/dash-to-panel/appicon-padding "4"
dconf write /org/gnome/shell/extensions/dash-to-panel/show-favorites "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/show-running-apps "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/show-window-previews "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/isolate-workspaces "false"
dconf write /org/gnome/shell/extensions/dash-to-panel/group-apps "true"
dconf write /org/gnome/shell/extensions/dash-to-panel/dot-position "'BOTTOM'"
dconf write /org/gnome/shell/extensions/dash-to-panel/window-preview-title-position "'TOP'"
dconf write /org/gnome/shell/extensions/dash-to-panel/hotkeys-overlay-combo "'TEMPORARILY'"
dconf write /org/gnome/shell/extensions/dash-to-panel/intellihide "false"

# Panel positions - JSON string
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-positions '"{\"CMN-0x00000000\":\"TOP\",\"DEL-KRXTR88N909L\":\"TOP\"}"'
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-sizes '"{\"CMN-0x00000000\":28,\"DEL-KRXTR88N909L\":28}"'
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-lengths '"{\"CMN-0x00000000\":100,\"DEL-KRXTR88N909L\":100}"'
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-anchors '"{\"CMN-0x00000000\":\"MIDDLE\",\"DEL-KRXTR88N909L\":\"MIDDLE\"}"'

# Tiling Shell Configuration
echo "🪟 Tiling Shell ayarları..."

dconf write /org/gnome/shell/extensions/tilingshell/enable-tiling-system "true"
dconf write /org/gnome/shell/extensions/tilingshell/auto-tile "true"
dconf write /org/gnome/shell/extensions/tilingshell/snap-assist "true"
dconf write /org/gnome/shell/extensions/tilingshell/default-layout "'split'"
dconf write /org/gnome/shell/extensions/tilingshell/inner-gaps "4"
dconf write /org/gnome/shell/extensions/tilingshell/outer-gaps "4"

# Window Suggestions
dconf write /org/gnome/shell/extensions/tilingshell/enable-window-suggestions "true"
dconf write /org/gnome/shell/extensions/tilingshell/window-suggestions-for-snap-assist "true"
dconf write /org/gnome/shell/extensions/tilingshell/window-suggestions-for-edge-tiling "true"
dconf write /org/gnome/shell/extensions/tilingshell/window-suggestions-for-keybinding "true"
dconf write /org/gnome/shell/extensions/tilingshell/suggestions-timeout "3000"
dconf write /org/gnome/shell/extensions/tilingshell/max-suggestions-to-show "6"
dconf write /org/gnome/shell/extensions/tilingshell/enable-suggestions-scroll "true"

# Tiling Keybindings
dconf write /org/gnome/shell/extensions/tilingshell/tile-left "['<Super><Shift>Left']"
dconf write /org/gnome/shell/extensions/tilingshell/tile-right "['<Super><Shift>Right']"
dconf write /org/gnome/shell/extensions/tilingshell/tile-up "['<Super><Shift>Up']"
dconf write /org/gnome/shell/extensions/tilingshell/tile-down "['<Super><Shift>Down']"
dconf write /org/gnome/shell/extensions/tilingshell/toggle-tiling "['<Super>t']"
dconf write /org/gnome/shell/extensions/tilingshell/toggle-floating "['<Super>f']"

# Focus keybindings
dconf write /org/gnome/shell/extensions/tilingshell/focus-left "['<Super>Left']"
dconf write /org/gnome/shell/extensions/tilingshell/focus-right "['<Super>Right']"
dconf write /org/gnome/shell/extensions/tilingshell/focus-up "['<Super>Up']"
dconf write /org/gnome/shell/extensions/tilingshell/focus-down "['<Super>Down']"

# Focus settings
dconf write /org/gnome/shell/extensions/tilingshell/auto-focus-on-tile "true"
dconf write /org/gnome/shell/extensions/tilingshell/focus-follows-mouse "false"
dconf write /org/gnome/shell/extensions/tilingshell/respect-focus-hints "true"

# Layout switching
dconf write /org/gnome/shell/extensions/tilingshell/next-layout "['<Super>Tab']"
dconf write /org/gnome/shell/extensions/tilingshell/prev-layout "['<Super><Shift>Tab']"

# Visual settings
dconf write /org/gnome/shell/extensions/tilingshell/show-border "true"
dconf write /org/gnome/shell/extensions/tilingshell/border-width "2"
dconf write /org/gnome/shell/extensions/tilingshell/enable-animations "true"
dconf write /org/gnome/shell/extensions/tilingshell/animation-duration "150"
dconf write /org/gnome/shell/extensions/tilingshell/resize-step "50"

# Advanced settings
dconf write /org/gnome/shell/extensions/tilingshell/respect-workspaces "true"
dconf write /org/gnome/shell/extensions/tilingshell/tile-dialogs "false"
dconf write /org/gnome/shell/extensions/tilingshell/tile-modals "false"
dconf write /org/gnome/shell/extensions/tilingshell/last-version-name-installed "'16.4'"

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
export XCURSOR_SIZE="16"
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
if gsettings get org.gnome.desktop.interface icon-theme | grep -q "a-candy-beauty-icon-theme"; then
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

# =============================================================================
# FINALIZATION
# =============================================================================
#echo "🔄 DConf güncelleniyor..."
#dconf update

#echo "🔧 GNOME Settings Daemon restart ediliyor..."
#pkill -f gnome-settings-daemon || true
#sleep 2
#nohup gnome-settings-daemon >/dev/null 2>&1 &

echo ""
echo "✅ GNOME + Catppuccin Mocha Konfigürasyonu başarıyla tamamlandı!"
echo "🕐 Bitiş zamanı: $(date)"
echo "📊 Script çalışma süresi: $SECONDS saniye"
echo ""
echo "🎨 Catppuccin Mocha Tema Özellikleri:"
echo "   • GTK Teması: catppuccin-mocha-mauve-standard+normal"
echo "   • İkon Teması: a-candy-beauty-icon-theme"
echo "   • Cursor Teması: catppuccin-mocha-dark-cursors"
echo "   • Terminal Renkleri: Catppuccin Mocha paleti"
echo "   • Extension Temaları: Mocha renkleri ile uyumlu"
echo ""
echo "📋 Test etmek için temel keybinding'ler:"
echo "   🖥️  Super+Return    → Terminal"
echo "   🌐 Super+b         → Browser"
echo "   📁 Super+e         → File Manager (Yazi)"
echo "   📁 Alt+Ctrl+f      → Nemo File Manager"
echo "   📋 Super+v         → Clipboard"
echo "   🏢 Super+1-9       → Workspaces"
echo "   ❌ Super+q         → Close Window"
echo "   📸 Super+Shift+s   → Screenshot"
echo "   🔒 Alt+l           → Lock Screen"
echo ""
echo "🎨 Extension ayarları:"
echo "   📊 Dash to Panel   → Panel yapılandırması (Catppuccin renkli)"
echo "   🪟 Tiling Shell    → Window tiling sistemi (Mauve border)"
echo "   🌌 Space Bar       → Workspace göstergesi (Mocha tema)"
echo "   📋 Clipboard       → Super+v ile erişim"
echo "   💻 Vitals          → Sistem monitörü"
echo ""
echo "🎵 Medya Kontrolleri:"
echo "   🎧 Alt+e           → Spotify Toggle"
echo "   ⏭️  Alt+Ctrl+n      → Spotify Next"
echo "   ⏮️  Alt+Ctrl+b      → Spotify Previous"
echo "   🎬 Alt+i           → MPV Start/Focus"
echo "   ▶️  Alt+p           → MPV Toggle Playback"
echo ""
echo "🔧 Sistem Kontrolleri:"
echo "   🔊 Alt+a           → Audio Output Switch"
echo "   🎤 Alt+Ctrl+a      → Microphone Switch"
echo "   🔵 F10             → Bluetooth Toggle"
echo "   🔒 Alt+F12         → Mullvad VPN Toggle"
echo ""
echo "⚡ Güç Yönetimi:"
echo "   💤 Ctrl+Alt+Shift+s → Shutdown"
echo "   🔄 Ctrl+Alt+r       → Restart"
echo "   🚪 Ctrl+Alt+q       → Logout"
echo "   ⚙️  Ctrl+Alt+p       → Power Menu"
echo ""
echo "🏢 Workspace Yönetimi:"
echo "   ← Super+Alt+Left   → Previous Workspace"
echo "   → Super+Alt+Right  → Next Workspace"
echo "   ⬆️ Super+Shift+↑    → Move Window Up"
echo "   ⬇️ Super+Shift+↓    → Move Window Down"
echo ""
echo "⚠️  Eğer bazı komutlar çalışmazsa:"
echo "   • O uygulamaların yüklü olduğundan emin olun"
echo "   • Extension'ları GNOME Extensions'dan kontrol edin"
echo "   • Logout/login yapın veya sistemi yeniden başlatın"
echo "   • Tema dosyalarının doğru konumda olduğunu kontrol edin"
echo ""
echo "🔍 Ayarları kontrol etmek için:"
echo "   gnome-control-center"
echo "   dconf-editor (detaylı ayarlar için)"
echo "   gsettings get org.gnome.desktop.interface gtk-theme"
echo ""
echo "🔧 Manuel kontrol komutları:"
echo "   gsettings get org.gnome.desktop.interface gtk-theme"
echo "   gsettings get org.gnome.desktop.interface icon-theme"
echo "   gsettings get org.gnome.desktop.interface cursor-theme"
echo ""
echo "📁 Tema dosyaları lokasyonu:"
echo "   ~/.themes/ (GTK temaları)"
echo "   ~/.icons/ (İkon temaları)"
echo "   ~/.local/share/icons/ (Cursor temaları)"
echo "   ~/.config/gtk-3.0/gtk.css (Nemo özelleştirmeleri)"
echo ""
echo "📁 Detaylı log dosyası: $LOG_FILE"
echo ""
echo "🎉 Catppuccin Mocha teması ile GNOME deneyiminizin keyfini çıkarın!"
echo "🔄 Değişikliklerin tam olarak uygulanması için logout/login yapın"

# Debug mode'u kapat
set +x
