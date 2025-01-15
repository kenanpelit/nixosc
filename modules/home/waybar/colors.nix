{ config, ... }:
let
  colors = import ./../../../themes/colors.nix;
  theme = colors.mkTheme {
    inherit (colors) mocha effects fonts;
  };
in
theme.waybar
