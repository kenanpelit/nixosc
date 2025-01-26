# modules/home/waybar/colors.nix
{ config, ... }:
let
 colors = import ./../../../../themes/colors.nix;
 theme = colors.mkTheme {
   inherit (colors) tokyonight effects fonts;
 };
in
theme.waybar
