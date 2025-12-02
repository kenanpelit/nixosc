# modules/core/display/default.nix
# ==============================================================================
# Display Stack Options
# ==============================================================================
# Defines module options for the graphical display stack.
# - Enablement toggles for DEs (Hyprland, GNOME, COSMIC)
# - Display Manager settings (auto-login, default session)
# - Keyboard layout options
# - Font and audio stack toggles
#
# ==============================================================================

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

    enableAudio = mkEnableOption "PipeWire audio stack";
  };
}
