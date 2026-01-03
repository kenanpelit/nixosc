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
        # Default width (fraction of monitor width)
        column_width = 0.7;
        # Presets cycled by `layoutmsg colresize +/-conf`
        explicit_column_widths = "0.5, 0.7, 1.0";
        fullscreen_on_one_column = true;
        # 0=center, 1=fit
        focus_fit_method = 1;
        follow_focus = true;
      };
    };
  };
}
