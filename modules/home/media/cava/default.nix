# modules/home/cava/default.nix
# ==============================================================================
# Cava Audio Visualizer Configuration
# ==============================================================================
{ pkgs, ... }:
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
    # Catppuccin Mocha Color Theme
    # ============================================================================
    [color]
    gradient = 1
    gradient_count = 8
    gradient_color_1 = '#f5e0dc' # Rosewater
    gradient_color_2 = '#f2cdcd' # Flamingo
    gradient_color_3 = '#f5c2e7' # Pink
    gradient_color_4 = '#cba6f7' # Mauve
    gradient_color_5 = '#f38ba8' # Red
    gradient_color_6 = '#eba0ac' # Maroon
    gradient_color_7 = '#fab387' # Peach
    gradient_color_8 = '#f9e2af' # Yellow
  '';
}
