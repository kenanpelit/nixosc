# modules/core/portals/default.nix
# ==============================================================================
# XDG Desktop Portals
# ==============================================================================
# Configures XDG portals for Wayland desktop integration.
# - Enables portal support
# - Adds Hyprland portal backend if display stack is enabled
# - Sets default portals to hyprland and gtk
#
# ==============================================================================

{ pkgs, lib, inputs, config, ... }:

let
  cfg = config.my.display;
  hyprPortalPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
in
{
  config = lib.mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [ hyprPortalPkg ];
      config.common.default = [ "hyprland" "gtk" ];
    };
  };
}
