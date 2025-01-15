{ pkgs, ... }:
let
  colors = import ./../../../themes/colors.nix;
  theme = colors.mkTheme {
    inherit (colors) mocha effects fonts;
  };
in
{
  home.packages = (with pkgs; [ swaynotificationcenter ]);
  xdg.configFile."swaync/config.json".source = ./config.json;
  xdg.configFile."swaync/style.css".text = ''
    ${theme.swaync.style}
    ${builtins.readFile ./style.css}
  '';
}
