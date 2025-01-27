# modules/home/terminal/figlet/default.nix
# ==============================================================================
# Terminal Figlet Configuration
# Author: Kenan Pelit
# ==============================================================================
{ config, pkgs, lib, inputs, ... }:
let
 cfg = config.modules.home.terminal.figlet;
 inherit (config.modules.home) username;
 # XDG kullanıcı dizinleri 
 xdgConfigDir = config.home-manager.users.${username}.xdg.configHome;
 fontDir = "${xdgConfigDir}/figlet";
in {
 options.modules.home.terminal.figlet.enable = lib.mkEnableOption "figlet";

 config = lib.mkIf cfg.enable {
   home-manager.users.${username} = {
     # Gerekli paketleri yükle
     home.packages = with pkgs; [ 
       figlet 
       toilet 
     ];

     # Font dizinini ~/.config/figlet olarak ayarla
     home.sessionVariables = {
       FIGLET_FONTDIR = fontDir;
     };

     # Figlet fontlarını ~/.config/figlet dizinine kopyala
     xdg.configFile."figlet" = {
       source = inputs.figlet-fonts;
       recursive = true;  # Alt dizinleri de kopyala
     };
   };
 };
}
