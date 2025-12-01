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
  flatpakEnabled = config.services.flatpak.enable or false;
  hyprPortalPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
in
{
  config = lib.mkIf (cfg.enable || flatpakEnabled) {
    # Required when Home Manager installs portals via user packages
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    xdg.portal = {
      enable = true;
      extraPortals =
        (lib.optional cfg.enableHyprland hyprPortalPkg)
        ++ [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default =
        if cfg.enableHyprland then [ "hyprland" "gtk" ] else [ "gtk" ];
    };
  };
}
