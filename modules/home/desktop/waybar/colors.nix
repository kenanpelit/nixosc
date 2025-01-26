# modules/home/waybar/colors.nix
{ config, ... }:
let
 colors = import ./../../../../themes/colors.nix;
 theme = colors.mkTheme {
   inherit (colors) kenp effects fonts;
 };
in
theme.waybar
