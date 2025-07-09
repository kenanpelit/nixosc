# modules/core/wayland/default.nix
# ==============================================================================
# Wayland Configuration
# ==============================================================================
# This configuration manages Wayland settings including:
# - Hyprland compositor setup
# - XDG portal integration
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };
}
