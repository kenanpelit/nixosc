# modules/home/desktop/rofi/default.nix
# ==============================================================================
# Rofi Root Configuration
# ==============================================================================
{ pkgs, ... }:
let
  colors = import ./../../../themes/default.nix;
  rofiTheme = import ./theme.nix {
    inherit (colors) kenp effects fonts;
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
