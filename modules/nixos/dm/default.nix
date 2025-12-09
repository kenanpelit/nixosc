# modules/nixos/dm/default.nix
# ------------------------------------------------------------------------------
# NixOS module for dm (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ lib, config, ... }:

let
  cfg = config.my.display;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    services.desktopManager.gnome.enable = cfg.enableGnome;
    services.displayManager.autoLogin = {
      enable = cfg.autoLogin.enable;
      user   = cfg.autoLogin.user or null;
    };
    services.displayManager.defaultSession =
      if cfg.defaultSession != null then cfg.defaultSession
      else if cfg.enableHyprland then "hyprland-optimized"
      else if cfg.enableGnome then "gnome"
      else null;

    services.xserver.xkb.layout  = cfg.keyboard.layout;
    services.xserver.xkb.variant = cfg.keyboard.variant;
    services.xserver.xkb.options = lib.concatStringsSep "," cfg.keyboard.options;
  };
}
