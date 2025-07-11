#!/usr/bin/env bash
# ==============================================================================
# Complete GNOME Configuration Script for NixOS
# Tüm DConf ayarlarını manuel olarak uygular
# ==============================================================================

set -euo pipefail

# Log dizinini oluştur
LOG_DIR="$HOME/.logs"
LOG_FILE="$LOG_DIR/gnome_settings.log"
mkdir -p "$LOG_DIR"

# Debug mode'u aktif et ve log'a yönlendir
exec > >(tee -a "$LOG_FILE") 2>&1
set -x

echo "🚀 GNOME Complete Configuration başlatılıyor..."
echo "📝 Log dosyası: $LOG_FILE"
echo "🕐 Başlama zamanı: $(date)"

# Font ayarları
MAIN_FONT="Maple Mono"
EDITOR_FONT="Maple Mono"
TERMINAL_FONT="Hack Nerd Font"
FONT_SIZE_SM="12"
FONT_SIZE_MD="13"
FONT_SIZE_XL="15"

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
dconf write /org/gnome/TextEditor/style-scheme "'builder-dark'"
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

# Window movement within workspace - BU SATIRLARI GEÇİCİ OLARAK KAPAT
# dconf write /org/gnome/desktop/wm/keybindings/move-window-left "['<Super><Alt>Left', '<Super><Alt>h']"
# dconf write /org/gnome/desktop/wm/keybindings/move-window-right "['<Super><Alt>Right', '<Super><Alt>l']"
# dconf write /org/gnome/desktop/wm/keybindings/move-window-up "['<Super><Alt>Up', '<Super><Alt>k']"
# dconf write /org/gnome/desktop/wm/keybindings/move-window-down "['<Super><Alt>Down', '<Super><Alt>j']"

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
'clipboard-indicator@tudmotu.com',
'dash-to-panel@jderose9.github.com',
'alt-tab-scroll-workaround@lucasresck.github.io',
'extension-list@tu.berry',
'auto-move-windows@gnome-shell-extensions.gcampax.github.com',
'bluetooth-quick-connect@bjarosze.gmail.com',
'no-overview@fthx',
'Vitals@CoreCoding.com',
'tilingshell@ferrarodomenico.com',
'weatheroclock@CleoMenezesJr.github.io',
'spotify-controls@Sonath21',
'space-bar@luchrioh',
'sound-percentage@subashghimire.info.np',
'screenshort-cut@pauloimon',
'window-centering@hnjjhmtr27',
'disable-workspace-animation@ethnarque',
'gsconnect@andyholmes.github.io',
'mullvadindicator@pobega.github.com'
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
# CUSTOM KEYBINDINGS
# =============================================================================
echo "⌨️  Custom keybinding'ler ekleniyor..."

# Ana custom keybindings listesini oluştur
CUSTOM_PATHS=""
for i in {0..40}; do
	if [ $i -eq 0 ]; then
		CUSTOM_PATHS="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'"
	else
		CUSTOM_PATHS="$CUSTOM_PATHS, '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'"
	fi
done

dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "[$CUSTOM_PATHS]"

# Terminal
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Super>Return'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'kitty'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'Terminal'"

# Browser
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/binding "'<Super>b'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/command "'brave'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/name "'Browser'"

# Terminal File Manager (Floating)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/binding "'<Super>e'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/command "'kitty --class floating-terminal -e yazi'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/name "'Terminal File Manager (Floating)'"

# File Manager
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/binding "'<Alt><Ctrl>f'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/command "'nemo'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/name "'Open Nemo File Manager'"

# Terminal File Manager (Yazi)
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/binding "'<Alt>f'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/command "'kitty yazi'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/name "'Terminal File Manager (Yazi)'"

# Walker Launcher
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/binding "'<Super><Alt>space'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/command "'walker'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/name "'Open Walker'"

# Audio Output Switch
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/binding "'<Alt>a'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/command "'osc-soundctl switch'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/name "'Switch Audio Output'"

# Microphone Switch
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/binding "'<Alt><Ctrl>a'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/command "'osc-soundctl switch-mic'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/name "'Switch Microphone'"

# Spotify Toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/binding "'<Alt>e'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/command "'osc-spotify'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/name "'Spotify Toggle'"

# Spotify Next
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/binding "'<Alt><Ctrl>n'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/command "'osc-spotify next'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/name "'Spotify Next'"

# Spotify Previous
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/binding "'<Alt><Ctrl>b'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/command "'osc-spotify prev'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/name "'Spotify Previous'"

# MPV Start/Focus
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/binding "'<Alt>i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/command "'gnome-mpv-manager start'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/name "'MPV Start/Focus'"

# Lock Screen
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/binding "'<Alt>l'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/command "'loginctl lock-session'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/name "'Lock Screen'"

# Previous Workspace
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/binding "'<Super><Alt>Left'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/command "'bash -c \"current=\$(wmctrl -d | grep \\\"*\\\" | awk \\\"{print \\\\\$1}\\\"); if [ \$current -gt 0 ]; then wmctrl -s \$((current - 1)); fi\"'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/name "'Previous Workspace'"

# Next Workspace
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/binding "'<Super><Alt>Right'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/command "'bash -c \"current=\$(wmctrl -d | grep \\\"*\\\" | awk \\\"{print \\\\\$1}\\\"); total=\$(wmctrl -d | wc -l); if [ \$current -lt \$((total - 1)) ]; then wmctrl -s \$((current + 1)); fi\"'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/name "'Next Workspace'"

# Discord
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/binding "'<Super><Shift>d'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/command "'webcord --enable-features=UseOzonePlatform --ozone-platform=wayland'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/name "'Open Discord'"

# KKENP
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/binding "'<Alt>t'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/command "'gnome-kkenp'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/name "'Start KKENP'"

# Notes Manager
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/binding "'<Super>n'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/command "'anotes -M'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/name "'Notes Manager'"

# Clipboard Manager
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/binding "'<Alt>v'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/command "'copyq toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/name "'Clipboard Manager'"

# Bluetooth Toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/binding "'F10'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/command "'hypr-bluetooth_toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/name "'Bluetooth Toggle'"

# Mullvad Toggle
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/binding "'<Alt>F12'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/command "'osc-mullvad toggle'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/name "'Mullvad Toggle'"

# Gnome Start
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/binding "'<Super><Alt>Return'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/command "'osc-start_gnome launch --daily'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/name "'Gnome Start'"

# Screenshot Tool
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/binding "'<Super><Shift>s'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/command "'gnome-screenshot -i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/name "'Screenshot Tool'"

# MPV Move Window
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/binding "'<Alt><Shift>i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/command "'gnome-mpv-manager move'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/name "'MPV Move Window'"

# MPV Resize Center
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/binding "'<Alt><Ctrl>i'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/command "'gnome-mpv-manager resize'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/name "'MPV Resize Center'"

# Play YouTube from Clipboard
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/binding "'<Alt>y'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/command "'gnome-mpv-manager play-yt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/name "'Play YouTube from Clipboard'"

# Download YouTube Video
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/binding "'<Alt><Shift>y'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/command "'gnome-mpv-manager save-yt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/name "'Download YouTube Video'"

# MPV Toggle Playback
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/binding "'<Alt>p'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/command "'gnome-mpv-manager playback'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/name "'MPV Toggle Playback'"

# Workspace Switching with History Support (1-9)
echo "🔢 Workspace keybinding'leri ekleniyor..."

for i in {1..9}; do
	custom_index=$((27 + i))
	dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$custom_index/binding "'<Super>$i'"
	dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$custom_index/command "'workspace-switcher $i'"
	dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$custom_index/name "'Workspace $i (with history)'"
done

# Power Management Shortcuts
echo "⚡ Power management keybinding'leri ekleniyor..."

# Shutdown
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/binding "'<Ctrl><Alt><Shift>s'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/command "'gnome-session-quit --power-off --no-prompt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/name "'Shutdown Computer'"

# Restart
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/binding "'<Ctrl><Alt>r'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/command "'gnome-session-quit --reboot --no-prompt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/name "'Restart Computer'"

# Logout
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/binding "'<Ctrl><Alt>q'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/command "'gnome-session-quit --logout --no-prompt'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/name "'Logout'"

# Power Menu
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/binding "'<Ctrl><Alt>p'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/command "'gnome-session-quit --power-off'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/name "'Power Menu (with confirmation)'"

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

# Panel positions - JSON string
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-positions '"{\"CMN-0x00000000\":\"TOP\",\"DEL-KRXTR88N909L\":\"TOP\"}"'
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-sizes '"{\"CMN-0x00000000\":22,\"DEL-KRXTR88N909L\":22}"'
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
dconf write /org/gnome/shell/extensions/tilingshell/border-color "'rgba(66, 165, 245, 0.8)'"
dconf write /org/gnome/shell/extensions/tilingshell/enable-animations "true"
dconf write /org/gnome/shell/extensions/tilingshell/animation-duration "150"
dconf write /org/gnome/shell/extensions/tilingshell/resize-step "50"

# Advanced settings
dconf write /org/gnome/shell/extensions/tilingshell/respect-workspaces "true"
dconf write /org/gnome/shell/extensions/tilingshell/tile-dialogs "false"
dconf write /org/gnome/shell/extensions/tilingshell/tile-modals "false"
dconf write /org/gnome/shell/extensions/tilingshell/last-version-name-installed "'16.4'"

# Space Bar CSS Configuration
echo "🌌 Space Bar CSS ayarları..."

SPACE_BAR_CSS='
.space-bar {
  -natural-hpadding: 12px;
}

.space-bar-workspace-label.active {
  margin: 0 4px;
  background-color: rgba(255,255,255,0.3);
  color: rgba(255,255,255,1);
  border-color: rgba(0,0,0,0);
  font-weight: 700;
  border-radius: 4px;
  border-width: 0px;
  padding: 3px 8px;
}

.space-bar-workspace-label.inactive {
  margin: 0 4px;
  background-color: rgba(0,0,0,0);
  color: rgba(255,255,255,1);
  border-color: rgba(0,0,0,0);
  font-weight: 700;
  border-radius: 4px;
  border-width: 0px;
  padding: 3px 8px;
}

.space-bar-workspace-label.inactive.empty {
  margin: 0 4px;
  background-color: rgba(0,0,0,0);
  color: rgba(255,255,255,0.5);
  border-color: rgba(0,0,0,0);
  font-weight: 700;
  border-radius: 4px;
  border-width: 0px;
  padding: 3px 8px;
}
'

dconf write /org/gnome/shell/extensions/space-bar/appearance/application-styles "'$SPACE_BAR_CSS'"

# =============================================================================
# FINALIZATION
# =============================================================================
echo "🔄 DConf güncelleniyor..."
dconf update

echo "🔧 GNOME Settings Daemon restart ediliyor..."
pkill -f gnome-settings-daemon || true
sleep 2
nohup gnome-settings-daemon >/dev/null 2>&1 &

echo ""
echo "✅ GNOME Konfigürasyonu başarıyla tamamlandı!"
echo "🕐 Bitiş zamanı: $(date)"
echo "📊 Script çalışma süresi: $SECONDS saniye"
echo ""
echo "📋 Test etmek için temel keybinding'ler:"
echo "   🖥️  Super+Return    → Terminal"
echo "   🌐 Super+b         → Browser"
echo "   📁 Super+e         → File Manager"
echo "   📋 Alt+v           → Clipboard"
echo "   🏢 Super+1-9       → Workspaces"
echo "   ❌ Super+q         → Close Window"
echo "   📸 Super+Shift+s   → Screenshot"
echo "   🔒 Alt+l           → Lock Screen"
echo ""
echo "🎨 Extension ayarları:"
echo "   📊 Dash to Panel   → Panel yapılandırması"
echo "   🪟 Tiling Shell    → Window tiling sistemi"
echo "   🌌 Space Bar       → Workspace göstergesi"
echo "   📋 Clipboard       → Super+v ile erişim"
echo "   💻 Vitals          → Sistem monitörü"
echo ""
echo "⚠️  Eğer bazı komutlar çalışmazsa:"
echo "   • O uygulamaların yüklü olduğundan emin olun"
echo "   • Extension'ları GNOME Extensions'dan kontrol edin"
echo "   • Logout/login yapın"
echo ""
echo "🔍 Ayarları kontrol etmek için:"
echo "   gnome-control-center"
echo "   dconf-editor (detaylı ayarlar için)"
echo ""
echo "📁 Detaylı log dosyası: $LOG_FILE"

# Debug mode'u kapat
set +x
