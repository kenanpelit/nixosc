# modules/home/xdg-portal/default.nix
# ==============================================================================
# Home module for per-user XDG portal helpers (if needed on Wayland).
# Keep portal preferences here instead of manual env tweaks.
# ==============================================================================

{ pkgs, lib, config, osConfig ? null, ... }:
let
  cfg = config.my.user.xdg-portal;
  nixosManagesPortals =
    osConfig != null && (lib.attrByPath [ "xdg" "portal" "enable" ] false osConfig);
in
{
  options.my.user.xdg-portal = {
    enable = lib.mkEnableOption "XDG desktop portal";
  };

  config = lib.mkIf (cfg.enable && !nixosManagesPortals) {
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
