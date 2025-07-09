# modules/home/rofi/default.nix
# ==============================================================================
# Rofi Root Configuration
# ==============================================================================
{ pkgs, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    crust = "#1a1b26";
    base = "#24283b";
    surface0 = "#292e42";
    surface1 = "#414868";
    surface2 = "#565f89";
    text = "#c0caf5";
    subtext1 = "#a9b1d6";
    green = "#9ece6a";
  };

  # Rofi tema CSS'i
  rofiTheme = {
    theme = ''
      * {
        bg-col: ${colors.crust};
        bg-col-light: ${colors.base};
        border-col: ${colors.surface1};
        selected-col: ${colors.surface0};
        green: ${colors.green};
        fg-col: ${colors.text};
        fg-col2: ${colors.subtext1};
        grey: ${colors.surface2};
        highlight: @green;
      }
    '';
  };
in
{
  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [
    ./config.nix   # Main configuration
  ];
  
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = (with pkgs; [ rofi-wayland ]);
  
  # =============================================================================
  # Theme Configuration
  # =============================================================================
  xdg.configFile."rofi/theme.rasi".text = rofiTheme.theme;
}

