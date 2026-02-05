# modules/home/hyprland/hyprscrolling.nix
# ==============================================================================
# Hyprscrolling (hyprwm/hyprland-plugins) integration
#
# - Loads the hyprscrolling plugin
# - Switches layout to `scrolling`
# - Adds plugin settings matching Niri-like preset widths
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;

  hyprscrollingPkg =
    if lib.hasAttrByPath [ "hyprlandPlugins" "hyprscrolling" ] pkgs.unstable
    then pkgs.unstable.hyprlandPlugins.hyprscrolling
    else null;
in
lib.mkIf cfg.enable {
  assertions = [
    {
      assertion = hyprscrollingPkg != null;
      message = "hyprscrolling is enabled but `pkgs.unstable.hyprlandPlugins.hyprscrolling` is missing.";
    }
  ];

  wayland.windowManager.hyprland = {
    plugins = lib.optional (hyprscrollingPkg != null) hyprscrollingPkg;

    settings = {
      # hyprscrolling registers the `scrolling` layout
      general.layout = lib.mkForce "scrolling";

      plugin.hyprscrolling = {
        # Niri-like defaults:
        # - presets cycled via `layoutmsg colresize +conf` (Mod+R)
        # - default width around 80% (Niri default-column-width)
        column_width = 0.8;
        explicit_column_widths = "0.30, 0.45, 0.60, 0.75, 1.0";
        fullscreen_on_one_column = false;
        # 0=center, 1=fit
        focus_fit_method = 0;
        follow_focus = true;
      };
    };
  };
}
