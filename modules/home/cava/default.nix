# modules/home/media/cava/default.nix
# ==============================================================================
# Cava Audio Visualizer Configuration
# ==============================================================================
{ pkgs, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    rosewater = "#f7768e";
    flamingo = "#ff9e64";
    pink = "#ff75a0";
    mauve = "#bb9af7";
    red = "#f7768e";
    maroon = "#e0af68";
    peach = "#ff9e64";
    yellow = "#e0af68";
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
    # Color Theme
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

