# modules/core/desktop/default.nix
# ==============================================================================
# Desktop Environment Configuration
# ==============================================================================
# This configuration file manages all desktop-related settings including:
# - Wayland display server
# - X11 server configuration
# - Font management and rendering
# - Display portals and desktop integration
#
# Key components:
# - Hyprland Wayland compositor
# - X.org server setup
# - System-wide font configuration
# - XDG portal integration
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./wayland
    ./x11
    ./fonts
    ./xdg
  ];

  systemd.extraConfig = "DefaultTimeoutStopSec=10s";
}
