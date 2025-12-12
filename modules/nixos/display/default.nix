# modules/nixos/display/default.nix
# ==============================================================================
# NixOS display stack wiring: Wayland/X defaults, GPU drivers, session bits.
# Central place for compositor/display-manager related settings.
# Avoid per-host drift by keeping display policy defined here.
# ==============================================================================

{ lib, ... }:

let inherit (lib) mkOption mkEnableOption types;
in {
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
}
