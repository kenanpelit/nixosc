# modules/home/rofi/theme.nix
# ==============================================================================
# Rofi Theme Configuration
# ==============================================================================
{ pkgs, ... }:
let
  # =============================================================================
  # Theme Import
  # =============================================================================
  colors = import ./../../../themes/colors.nix;
  theme = colors.mkTheme {
    inherit (colors) mocha effects fonts;
  };
in
{
  # =============================================================================
  # Theme Configuration
  # =============================================================================
  xdg.configFile."rofi/theme.rasi".text = ''
    * {
      # ---------------------------------------------------------------------------
      # Color Definitions
      # ---------------------------------------------------------------------------
      bg-col: ${colors.mocha.crust};
      bg-col-light: ${colors.mocha.base};
      border-col: ${colors.mocha.surface1};
      selected-col: ${colors.mocha.surface0};
      green: ${colors.mocha.green};
      fg-col: ${colors.mocha.text};
      fg-col2: ${colors.mocha.subtext1};
      grey: ${colors.mocha.surface2};
      highlight: @green;
    }
  '';
}

