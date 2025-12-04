# modules/home/xdg-portal/default.nix
# ==============================================================================
# XDG Portal Configuration
# ==============================================================================
{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.xdg-portal;
in
{
  options.my.user.xdg-portal = {
    enable = lib.mkEnableOption "XDG desktop portal";
  };

  config = lib.mkIf cfg.enable {
   xdg = {
     portal = {
       # =============================================================================
       # Base Configuration
       # =============================================================================
       enable = true;
  
       # =============================================================================
       # Portal Implementation
       # =============================================================================
       extraPortals = with pkgs; [
         xdg-desktop-portal-gtk
       ];
  
       # =============================================================================
       # Portal Settings
       # =============================================================================
       config = {
         common = {
           default = [ "gtk" ];
           "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
         };
       };
     };
   };
  };
}
