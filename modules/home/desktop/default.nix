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
{ config, lib, pkgs, ... }:

{
  imports = builtins.filter
    (x: x != null)
    (map
      (name: if (builtins.match ".*\\.nix" name != null && name != "default.nix")
             then ./${name}
             else if (builtins.pathExists (./. + "/${name}/default.nix"))
             then ./${name}
             else null)
      (builtins.attrNames (builtins.readDir ./.)));
}
