# modules/home/desktop/swaync/default.nix
# ==============================================================================
# SwayNC Notification Center Configuration
# ==============================================================================
{ pkgs, ... }:
let
 colors = import ./../../../themes/default.nix;
 swayncTheme = import ./theme.nix {
   inherit (colors) kenp effects fonts;
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
   ${swayncTheme.style}
   ${builtins.readFile ./style.css}
 '';
}
