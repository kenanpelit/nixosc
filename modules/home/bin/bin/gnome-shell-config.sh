#!/usr/bin/env bash

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

# For use with https://github.com/pop-os/shell/
#
# Use these extensions:
#  https://extensions.gnome.org/extension/3851/workspaces-bar/
#  https://extensions.gnome.org/extension/758/no-workspace-switcher-popup/
#  https://extensions.gnome.org/extension/808/hide-workspace-thumbnails/
#  https://extensions.gnome.org/extension/805/hide-dash/

# Basic Settings
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"
gsettings set org.gnome.shell.keybindings toggle-overview []

# Use fixed number of workspaces
gsettings set org.gnome.mutter dynamic-workspaces false
dconf write '/org/gnome/shell/overrides/dynamic-workspaces' false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 9

# Window Behavior
gsettings set org.gnome.mutter center-new-windows true

# Display Settings
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 4200

# System shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>F12', '<Alt>l']"
gsettings set org.gnome.settings-daemon.plugins.media-keys suspend "['<Alt>F12']"

# Window Management
dconf write '/org/gnome/desktop/wm/keybindings/minimize' "['<Super>d']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"

# Launcher
dconf write /org/gnome/shell/extensions/pop-shell/activate-launcher "['<Super>Space', '<Super>slash']"

# Disable overview
gsettings set org.gnome.mutter overlay-key ''

# Workspace Switching
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"

# Move Window to Workspace
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Super><Shift>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Super><Shift>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Super><Shift>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Super><Shift>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Super><Shift>9']"

# Window Movement
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Super><Alt>Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Alt>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Ctrl>Page_Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Ctrl>Page_Down']"

# Focus Movement
dconf write '/org/gnome/shell/extensions/pop-shell/focus-left' "['<Super>Left', '<Super>h']"
dconf write '/org/gnome/shell/extensions/pop-shell/focus-down' "['<Super>Down', '<Super>j']"
dconf write '/org/gnome/shell/extensions/pop-shell/focus-up' "['<Super>Up', '<Super>k']"
dconf write '/org/gnome/shell/extensions/pop-shell/focus-right' "['<Super>Right', '<Super>l']"

# Window Controls
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Alt>f']"
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>f']"
gsettings set org.gnome.desktop.wm.keybindings toggle-above "['<Ctrl><Super>Space']"

# Application Switching
dconf write '/org/gnome/desktop/wm/keybindings/switch-windows' "['<Super>Tab']"
dconf write '/org/gnome/desktop/wm/keybindings/switch-windows-backward' "['<Super><Shift>Tab']"
dconf write '/org/gnome/desktop/wm/keybindings/switch-applications' "['<Alt>Tab']"
dconf write '/org/gnome/desktop/wm/keybindings/switch-applications-backward' "['<Shift><Alt>Tab']"

# Pop Shell Configuration
dconf write '/org/gnome/shell/extensions/pop-shell/active-hint' true
dconf write '/org/gnome/shell/extensions/pop-shell/active-hint-border-radius' "uint32 5"
dconf write '/org/gnome/shell/extensions/pop-shell/gap-inner' "uint32 4"
dconf write '/org/gnome/shell/extensions/pop-shell/gap-outer' "uint32 4"
dconf write '/org/gnome/shell/extensions/pop-shell/hint-color-rgba' "'rgba(50,150,150,1)'"
dconf write '/org/gnome/shell/extensions/pop-shell/smart-gaps' false
dconf write '/org/gnome/shell/extensions/pop-shell/show-title' true

# Tile Management
dconf write '/org/gnome/shell/extensions/pop-shell/tile-enter' "['<Super>Return']"
dconf write '/org/gnome/shell/extensions/pop-shell/tile-accept' "['Return']"
dconf write '/org/gnome/shell/extensions/pop-shell/tile-move-down' "['Down', 'j']"
dconf write '/org/gnome/shell/extensions/pop-shell/tile-move-left' "['Left', 'h']"
dconf write '/org/gnome/shell/extensions/pop-shell/tile-move-right' "['Right', 'l']"
dconf write '/org/gnome/shell/extensions/pop-shell/tile-move-up' "['Up', 'k']"

# Additional Features
dconf write '/org/gnome/shell/extensions/pop-shell/toggle-floating' "['<Super>g']"
dconf write '/org/gnome/shell/extensions/pop-shell/toggle-stacking' "['s']"
dconf write '/org/gnome/shell/extensions/pop-shell/toggle-stacking-global' "['<Super>s']"
dconf write '/org/gnome/shell/extensions/pop-shell/toggle-tiling' "['<Super>y']"

# Custom Keybindings for Applications
BEGINNING="gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['$KEY_PATH/custom0/', '$KEY_PATH/custom1/', '$KEY_PATH/custom2/', '$KEY_PATH/custom3/', \
'$KEY_PATH/custom9/', '$KEY_PATH/custom10/', '$KEY_PATH/custom11/', \
'$KEY_PATH/custom12/', '$KEY_PATH/custom13/', '$KEY_PATH/custom14/', '$KEY_PATH/custom15/', \
'$KEY_PATH/custom16/', '$KEY_PATH/custom17/', '$KEY_PATH/custom18/', '$KEY_PATH/custom19/', \
'$KEY_PATH/custom20/', '$KEY_PATH/custom21/', '$KEY_PATH/custom22/', '$KEY_PATH/custom23/', \
'$KEY_PATH/custom24/', '$KEY_PATH/custom25/', '$KEY_PATH/custom26/', '$KEY_PATH/custom27/', \
'$KEY_PATH/custom28/', '$KEY_PATH/custom29/', '$KEY_PATH/custom30/', '$KEY_PATH/custom31/', \
'$KEY_PATH/custom32/', '$KEY_PATH/custom33/', '$KEY_PATH/custom34/']"

# Terminal Emulators
$BEGINNING/custom0/ name "Alacritty"
$BEGINNING/custom0/ command "$HOME/.bin/semsumo.sh start foot never"
$BEGINNING/custom0/ binding "<Super>Return"

$BEGINNING/custom1/ name "Foot Always"
$BEGINNING/custom1/ command "$HOME/.bin/semsumo.sh start foot always"
$BEGINNING/custom1/ binding "<Super><Ctrl>Return"

$BEGINNING/custom2/ name "Kitty Single"
$BEGINNING/custom2/ command "$HOME/.bin/semsumo.sh start kitty-single never"
$BEGINNING/custom2/ binding "<Alt>Return"

$BEGINNING/custom3/ name "Kitty Single Always"
$BEGINNING/custom3/ command "$HOME/.bin/semsumo.sh start kitty-single always"
$BEGINNING/custom3/ binding "<Ctrl><Alt>Return"

# Launchers and Menus
$BEGINNING/custom9/ name "Wofi"
$BEGINNING/custom9/ command "$HOME/.bin/launch-wofi.sh"
$BEGINNING/custom9/ binding "<ALT>space"

$BEGINNING/custom10/ name "Rofi"
$BEGINNING/custom10/ command "pkill -x rofi || $HOME/.bin/08_rofi-cliphist.sh"
$BEGINNING/custom10/ binding "<Super><Alt>space"

$BEGINNING/custom11/ name "Ulauncher"
$BEGINNING/custom11/ command "$HOME/.bin/hypr-start-ulauncher.sh"
$BEGINNING/custom11/ binding "<Super><Ctrl>space"

# System Controls
$BEGINNING/custom12/ name "Blue Light Toggle"
$BEGINNING/custom12/ command "$HOME/.bin/hypr-hyprshade_blue_light_toggle.sh kenp"
$BEGINNING/custom12/ binding "F9"

$BEGINNING/custom13/ name "Hyprshade Toggle"
$BEGINNING/custom13/ command "/usr/bin/hyprshade toggle"
$BEGINNING/custom13/ binding "<Alt>F9"

$BEGINNING/custom14/ name "Bluetooth Toggle"
$BEGINNING/custom14/ command "$HOME/.bin/hypr-bluetooth_toggle.sh"
$BEGINNING/custom14/ binding "F10"

# Utilities
$BEGINNING/custom15/ name "Color Picker"
$BEGINNING/custom15/ command "$HOME/.bin/hypr-colorpicker.sh"
$BEGINNING/custom15/ binding "<Super><Ctrl>o"

$BEGINNING/custom16/ name "CopyQ"
$BEGINNING/custom16/ command "copyq toggle"
$BEGINNING/custom16/ binding "<Super>v"

$BEGINNING/custom17/ name "Airplane Mode"
$BEGINNING/custom17/ command "$HOME/.bin/hypr-airplane_mode.sh"
$BEGINNING/custom17/ binding "<Super>F8"

# File Manager
$BEGINNING/custom18/ name "Thunar"
$BEGINNING/custom18/ command "$HOME/.bin/hypr-start-thunar.sh"
$BEGINNING/custom18/ binding "<Super><Shift>Return"

# Media Controls
$BEGINNING/custom19/ name "Audio Switcher"
$BEGINNING/custom19/ command "$HOME/.bin/hypr-audio_switcher.sh"
$BEGINNING/custom19/ binding "<Alt>a"

$BEGINNING/custom20/ name "Spotify Toggle"
$BEGINNING/custom20/ command "$HOME/.bin/hypr-spotify_toggle.sh"
$BEGINNING/custom20/ binding "<Alt>e"

$BEGINNING/custom21/ name "MPC Control"
$BEGINNING/custom21/ command "$HOME/.bin/mpc-control toggle"
$BEGINNING/custom21/ binding "<Alt><Ctrl>e"

$BEGINNING/custom22/ name "MPV Toggle"
$BEGINNING/custom22/ command "$HOME/.bin/hypr-mpv-manager.sh toggle"
$BEGINNING/custom22/ binding "<Alt>i"

$BEGINNING/custom23/ name "MPV YTDL"
$BEGINNING/custom23/ command "$HOME/.bin/hypr-mpv-manager.sh yplay"
$BEGINNING/custom23/ binding "<Alt>u"

$BEGINNING/custom24/ name "MPV Cycle"
$BEGINNING/custom24/ command "$HOME/.bin/hypr-mpv-manager.sh cycle"
$BEGINNING/custom24/ binding "<Alt><Ctrl>h"

$BEGINNING/custom25/ name "VLC Toggle"
$BEGINNING/custom25/ command "$HOME/.bin/hypr-vlc_toggle.sh"
$BEGINNING/custom25/ binding "<Alt><Ctrl>i"

# System Functions
$BEGINNING/custom26/ name "Mullvad Toggle"
$BEGINNING/custom26/ command "$HOME/.bin/hypr-mullvad_toggle.sh toggle"
$BEGINNING/custom26/ binding "<Alt>F12"

$BEGINNING/custom27/ name "Mako Restore"
$BEGINNING/custom27/ command "makoctl restore"
$BEGINNING/custom27/ binding "<Alt>space"

$BEGINNING/custom28/ name "Mako Dismiss"
$BEGINNING/custom28/ command "makoctl dismiss"
$BEGINNING/custom28/ binding "<Alt><Ctrl>space"

$BEGINNING/custom29/ name "Screen Lock"
$BEGINNING/custom29/ command "/usr/bin/hyprlock"
$BEGINNING/custom29/ binding "<Alt>l"

$BEGINNING/custom30/ name "Start All Apps"
$BEGINNING/custom30/ command "$HOME/.bin/hypr-start-zen-all.sh"
$BEGINNING/custom30/ binding "<Super><Alt>Return"

# Terminal with Sem Script
$BEGINNING/custom31/ name "Terminal FKENP"
$BEGINNING/custom31/ command "$HOME/.bin/semsumo.sh start fkenp never"
$BEGINNING/custom31/ binding "<Alt>t"

$BEGINNING/custom32/ name "Terminal FCTA"
$BEGINNING/custom32/ command "$HOME/.bin/semsumo.sh start fcta always"
$BEGINNING/custom32/ binding "<Alt><Ctrl>c"

# Anote Shortcuts
$BEGINNING/custom33/ name "Anote Snippets"
$BEGINNING/custom33/ command "$HOME/.bin/hypr-start-manager.sh anote"
$BEGINNING/custom33/ binding "<Super>n"

$BEGINNING/custom34/ name "Clipboard Manager"
$BEGINNING/custom34/ command "$HOME/.bin/hypr-clibp.sh"
$BEGINNING/custom34/ binding "<Super>b"
