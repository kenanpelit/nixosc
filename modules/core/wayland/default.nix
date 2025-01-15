# modules/core/wayland/default.nix
# ==============================================================================
# Wayland Display Server Configuration
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # =============================================================================
  # Hyprland Configuration
  # =============================================================================
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # =============================================================================
  # XDG Portal Configuration
  # =============================================================================
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
