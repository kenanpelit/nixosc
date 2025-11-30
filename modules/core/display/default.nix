# modules/core/display/defaul.nix
# Display stack options; imports handled in core/default.nix.

{ lib, ... }:

let inherit (lib) mkOption mkEnableOption types;
in {
  options.my.display = {
    enable = mkEnableOption "display stack (DM/DE/portals/fonts/audio)";
    enableHyprland = mkEnableOption "Hyprland Wayland compositor";
    enableGnome    = mkEnableOption "GNOME desktop environment";
    enableCosmic   = mkEnableOption "COSMIC desktop environment";

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

    fonts = {
      enable = mkEnableOption "font stack";
      hiDpiOptimized = mkEnableOption "HiDPI font tuning";
    };

    enableAudio = mkEnableOption "PipeWire audio stack";
  };
}
