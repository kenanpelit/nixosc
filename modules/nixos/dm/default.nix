# modules/nixos/dm/default.nix
# ==============================================================================
# NixOS display-manager/greeter wiring (e.g., greetd/lightdm settings).
# Centralize login UI toggles and session registration here.
# Keep DM choices consistent across hosts from this module.
# ==============================================================================

{ lib, config, options, ... }:

let
  cfg = config.my.display;
  dmsGreeterEnabled = config.my.greeter.dms.enable or false;
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.xserver.enable = true;

      services.displayManager.gdm = lib.mkIf (!dmsGreeterEnabled) {
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
    }
  ]);
}
