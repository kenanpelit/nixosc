# modules/home/desktop/swaync/default.nix
# ==============================================================================
# SwayNC Notification Center Configuration
# ==============================================================================
{ pkgs, ... }:
let
  colors = import ./../../../../themes/colors.nix;
  theme = colors.mkTheme {
    inherit (colors) mocha effects fonts;
  };
in
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = (with pkgs; [ swaynotificationcenter ]);

  # =============================================================================
  # Configuration Files
  # =============================================================================
  xdg.configFile."swaync/config.json".source = ./config.json;
  xdg.configFile."swaync/style.css".text = ''
    ${theme.swaync.style}
    ${builtins.readFile ./style.css}
  '';
}
