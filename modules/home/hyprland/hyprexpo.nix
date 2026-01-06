# modules/home/hyprland/hyprexpo.nix
# ==============================================================================
# Hyprexpo (hyprwm/hyprland-plugins) integration
#
# - Loads the hyprexpo plugin
# - Adds workspace overview/expo settings
# ==============================================================================

{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
  system = pkgs.stdenv.hostPlatform.system;

  hyprexpoPkg =
    if inputs ? hyprland-plugins
    then inputs.hyprland-plugins.packages.${system}.hyprexpo
    else null;
    
  inherit (config.catppuccin) sources;
  flavor = config.catppuccin.flavor;
  colors = (lib.importJSON "${sources.palette}/palette.json").${flavor}.colors;
in
lib.mkIf cfg.enable {
  assertions = [
    {
      assertion = hyprexpoPkg != null;
      message = "hyprexpo is enabled but `inputs.hyprland-plugins` is missing.";
    }
  ];

  wayland.windowManager.hyprland = {
    plugins = lib.optional (hyprexpoPkg != null) hyprexpoPkg;

    settings = {
      plugin.hyprexpo = {
        columns = 3;
        gap_size = 5;
        workspace_method = "center current"; # [center/first] [workspace] e.g. first 1 or center m+1
      };
    };
  };
}
