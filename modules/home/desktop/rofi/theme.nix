# modules/home/desktop/rofi/theme.nix
# ==============================================================================
# Rofi Theme Configuration
# ==============================================================================
{ pkgs, ... }:
let
 # =============================================================================
 # Theme Import and Setup
 # =============================================================================
 colors = import ./../../../themes/colors.nix;
 theme = colors.mkTheme {
   inherit (colors) kenp effects fonts;
 };
in
{
 # =============================================================================
 # Theme Configuration
 # =============================================================================
 xdg.configFile."rofi/theme.rasi".text = ''
   * {
     /* Base Colors */
     bg-col: ${colors.kenp.crust};
     bg-col-light: ${colors.kenp.base};
     border-col: ${colors.kenp.surface1};
     selected-col: ${colors.kenp.surface0};
     /* Accent Colors */
     green: ${colors.kenp.green};
     fg-col: ${colors.kenp.text};
     fg-col2: ${colors.kenp.subtext1};
     grey: ${colors.kenp.surface2};
     highlight: @green;
   }
 '';
}
