# modules/core/wayland/default.nix
# ==============================================================================
# Wayland Configuration - Hyprland Focused
# ==============================================================================
# This configuration manages Hyprland-specific Wayland settings:
# - Hyprland compositor setup only
# - Hyprland-specific environment variables
#
# Note: XDG Portal config in modules/core/xdg
# Note: General Wayland env vars handled by individual modules
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # Hyprland Compositor
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };
  
  # Note: Environment variables managed by TTY-specific profile scripts
  # This avoids conflicts between GNOME and Hyprland sessions
}

