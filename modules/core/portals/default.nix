# modules/core/portals/default.nix
# XDG portals (Hyprland/GTK).

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
