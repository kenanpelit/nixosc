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
         xdg-desktop-portal-gnome
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

          # Niri: prefer GTK for general portals (file pickers etc.), and use the
          # restricted GNOME portal for ScreenCast/Screenshot/RemoteDesktop.
          #
          # Note: `gnome-niri` is provided by the flake overlay
          # `overlays/xdg-desktop-portal-gnome-niri.nix`.
          niri = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Access" = [ "gtk" ];
            "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.GlobalShortcuts" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome-niri" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome-niri" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome-niri" ];
          };
        };
      };
    };
  };
}
