# modules/core/xdg/default.nix
# ==============================================================================
# XDG Portal Configuration
# ==============================================================================
# This configuration manages XDG portal settings including:
# - Portal enablement
# - Default portal configuration
# - Additional portal packages
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    
    # Default Portal Configuration
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [
        "gtk"
        "hyprland"
      ];
    };

    # Additional Portals
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
