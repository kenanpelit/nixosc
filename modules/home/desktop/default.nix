# modules/home/desktop/default.nix
# ==============================================================================
# Desktop Configuration
# ==============================================================================
# This module manages desktop environment configurations including:
#
# Components:
# - Window Managers:
#   - Hyprland: Wayland compositor
#   - Sway: i3-compatible Wayland compositor
# - UI Elements:
#   - Waybar: Status bar
#   - Mako/SwayNC: Notifications
#   - Rofi/Wofi/Ulauncher: Application launchers
# - Display:
#   - GTK/Qt: Theming and styling
#   - Waypaper/Wpaperd: Wallpaper management
# - System Integration:
#   - Swaylock: Screen locking
#   - SwayOSD: On-screen display
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, nixpkgs, self, username, host, lib, ... }:

{
 imports = [
   ./gtk
   ./hyprland
   ./hyprsunset
   ./qt
   ./rofi
   ./sway
   ./swaylock
   ./swaync
   ./swayosd
   ./ulauncher
   ./waybar
   ./waypaper
   #./wpaperd
   ./xserver
 ];
}



