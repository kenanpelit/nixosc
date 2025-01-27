# modules/home/terminal/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emülatör Konfigürasyonu
# ==============================================================================
{ pkgs, host, ... }:
let
 colors = import ./../../../themes/default.nix;
 kittyTheme = import ./theme.nix {
   inherit (colors) kenp effects fonts;
 };
in
{
 imports = [
   (import ./settings.nix { inherit kittyTheme; })
 ];

 programs.kitty.enable = true;
}
