# modules/home/desktop/rofi/theme.nix
# ==============================================================================
# Rofi Theme Configuration
# ==============================================================================
{ pkgs, ... }:
let
 # =============================================================================
 # Theme Import and Setup
 # =============================================================================
 colors = import ./../../../../themes/colors.nix;
 theme = colors.mkTheme {
   inherit (colors) tokyonight effects fonts;
 };
in
{
 # =============================================================================
 # Theme Configuration
 # =============================================================================
 xdg.configFile."rofi/theme.rasi".text = ''
   * {
     /* Base Colors */
     bg-col: ${colors.tokyonight.crust};
     bg-col-light: ${colors.tokyonight.base};
     border-col: ${colors.tokyonight.surface1};
     selected-col: ${colors.tokyonight.surface0};
     /* Accent Colors */
     green: ${colors.tokyonight.green};
     fg-col: ${colors.tokyonight.text};
     fg-col2: ${colors.tokyonight.subtext1};
     grey: ${colors.tokyonight.surface2};
     highlight: @green;
   }
 '';
}
