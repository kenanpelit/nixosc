# modules/home/desktop/rofi/theme.nix
# ==============================================================================
# Rofi Theme Configuration
# ==============================================================================
{ kenp, effects, fonts }:
{
  theme = ''
    * {
      bg-col: ${kenp.crust};
      bg-col-light: ${kenp.base};
      border-col: ${kenp.surface1};
      selected-col: ${kenp.surface0};
      green: ${kenp.green};
      fg-col: ${kenp.text};
      fg-col2: ${kenp.subtext1};
      grey: ${kenp.surface2};
      highlight: @green;
    }
  '';
}
