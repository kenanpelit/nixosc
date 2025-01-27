# modules/home/waybar/colors.nix
{ config, ... }:
let
  colors = import ./../../../themes/default.nix;
  waybarTheme = import ./theme.nix {
    inherit (colors) kenp effects fonts;
  };
in
waybarTheme
