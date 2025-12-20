# modules/nixos/portals/default.nix
# ==============================================================================
# NixOS XDG portal selection (desktop/flatpak integration).
# Centralize portal backends to keep file pickers/screenshare consistent.
# Tweak portal providers here instead of per-session overrides.
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
        ++ [ 
          pkgs.xdg-desktop-portal-gtk 
          pkgs.xdg-desktop-portal-gnome
        ];
      config.common.default =
        if cfg.enableHyprland then [ "hyprland" "gtk" ] 
        else if cfg.enableNiri then [ "gnome" "gtk" ]
        else [ "gtk" ];
    };
  };
}
