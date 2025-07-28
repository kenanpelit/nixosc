# modules/home/media/cava/default.nix
# ==============================================================================
# Cava Audio Visualizer Configuration - Catppuccin Mocha
# ==============================================================================
{ pkgs, ... }:
let
  # Catppuccin Mocha tema renkleri
  colors = {
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
  };
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
    # Color Theme - Catppuccin Mocha
    # ============================================================================
    [color]
    gradient = 1
    gradient_count = 8
    gradient_color_1 = '${colors.rosewater}' # Rosewater
    gradient_color_2 = '${colors.flamingo}'  # Flamingo
    gradient_color_3 = '${colors.pink}'      # Pink
    gradient_color_4 = '${colors.mauve}'     # Mauve
    gradient_color_5 = '${colors.red}'       # Red
    gradient_color_6 = '${colors.maroon}'    # Maroon
    gradient_color_7 = '${colors.peach}'     # Peach
    gradient_color_8 = '${colors.yellow}'    # Yellow
  '';
}

