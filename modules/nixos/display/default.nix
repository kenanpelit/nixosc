# modules/nixos/display/default.nix
# ==============================================================================
# NixOS display stack wiring: options + DM/DE application logic.
# Central place for compositor/display-manager related settings.
# Avoid per-host drift by keeping display policy and implementation together.
# ==============================================================================

{ lib, config, ... }:

let
  inherit (lib) mkOption mkEnableOption mkIf mkMerge concatStringsSep types;
  cfg = config.my.display;
  dmsGreeterEnabled = config.my.greeter.dms.enable or false;
in
{
  options.my.display = {
    enable = mkEnableOption "display stack (DM/DE/portals/fonts/audio)";
    enableHyprland = mkEnableOption "Hyprland Wayland compositor";
    enableGnome    = mkEnableOption "GNOME desktop environment";
    enableNiri     = mkEnableOption "Niri compositor";

    defaultSession = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default session name for the display manager.";
    };

    autoLogin = {
      enable = mkOption { type = types.bool; default = false; description = "GDM auto-login"; };
      user   = mkOption { type = types.nullOr types.str; default = null; };
    };

    keyboard = {
      layout = mkOption { type = types.str; default = "tr"; };
      variant = mkOption { type = types.nullOr types.str; default = "f"; };
      options = mkOption { type = types.listOf types.str; default = [ "ctrl:nocaps" ]; };
    };

    enableAudio = mkEnableOption "PipeWire audio stack";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver.enable = cfg.enableGnome;

      services.displayManager.gdm = mkIf (!dmsGreeterEnabled) {
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
        else if cfg.enableNiri then "niri-optimized"
        else if cfg.enableHyprland then "hyprland-optimized"
        else if cfg.enableGnome then "gnome"
        else null;

      services.xserver.xkb.layout  = cfg.keyboard.layout;
      services.xserver.xkb.variant = cfg.keyboard.variant;
      services.xserver.xkb.options = concatStringsSep "," cfg.keyboard.options;
    }
  ]);
}
