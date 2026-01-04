# modules/home/hyprland/hyprscrolling.nix
# ==============================================================================
# Hyprscrolling (hyprwm/hyprland-plugins) integration
#
# - Loads the hyprscrolling plugin
# - Switches layout to `scrolling`
# - Adds plugin settings matching the common "onehalf/one" preset workflow
# ==============================================================================

{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
  system = pkgs.stdenv.hostPlatform.system;

  hyprscrollingPkg =
    if inputs ? hyprland-plugins
    then inputs.hyprland-plugins.packages.${system}.hyprscrolling
    else null;
in
lib.mkIf cfg.enable {
  assertions = [
    {
      assertion = hyprscrollingPkg != null;
      message = "hyprscrolling is enabled but `inputs.hyprland-plugins` is missing (expected a flake input pointing to hyprwm/hyprland-plugins).";
    }
  ];

  wayland.windowManager.hyprland = {
    plugins = lib.optional (hyprscrollingPkg != null) hyprscrollingPkg;

    settings = {
      # hyprscrolling registers the `scrolling` layout
      general.layout = lib.mkForce "scrolling";

      plugin.hyprscrolling = {
        # Niri-like column width (0.5 default)
        column_width = 0.5;
        # Niri preset widths: 1/3, 1/2, 2/3, Full
        explicit_column_widths = "0.33333, 0.5, 0.66667, 1.0";
        # Niri doesn't "fullscreen" single-column; keep normal sizing + centering.
        fullscreen_on_one_column = false;
        # Niri's "center-focused-column on-overflow" doesn't exist upstream here;
        # `fit` is the closest approximation for focus navigation.
        # 0=center, 1=fit
        focus_fit_method = 1;
        follow_focus = true;
      };
    };
  };
}
