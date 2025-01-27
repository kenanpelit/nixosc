# modules/home/cava/default.nix
# ==============================================================================
# Cava Audio Visualizer Configuration
# ==============================================================================
{ pkgs, ... }:
let
  colors = import ./../../../themes/default.nix;
  inherit (colors) kenp;
in
{
  # =============================================================================
  # Program Configuration
  # =============================================================================
  programs.cava = {
    enable = true;
  };

  # =============================================================================
  # Configuration File
  # =============================================================================
  xdg.configFile."cava/config".text = ''
    # ============================================================================
    # General Settings
    # ============================================================================
    [general]
    autosens = 1
    overshoot = 0

    # ============================================================================
    # Color Theme
    # ============================================================================
    [color]
    gradient = 1
    gradient_count = 8
    gradient_color_1 = '${kenp.rosewater}' # Rosewater
    gradient_color_2 = '${kenp.flamingo}'  # Flamingo
    gradient_color_3 = '${kenp.pink}'      # Pink
    gradient_color_4 = '${kenp.mauve}'     # Mauve
    gradient_color_5 = '${kenp.red}'       # Red
    gradient_color_6 = '${kenp.maroon}'    # Maroon
    gradient_color_7 = '${kenp.peach}'     # Peach
    gradient_color_8 = '${kenp.yellow}'    # Yellow
  '';
}
