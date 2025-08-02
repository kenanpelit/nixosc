# modules/core/wayland/default.nix
# ==============================================================================
# Wayland Configuration - Single Source of Truth
# ==============================================================================
# This configuration manages ALL Wayland settings including:
# - Hyprland compositor setup
# - XDG portal integration  
# - Environment variables (centralized)
# - Wayland-specific optimizations
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # Hyprland Compositor
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };
  
  # XDG Desktop Portal Configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk  # For file picker fallback
    ];
    config = {
      common = {
        default = [ "hyprland" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };
  
  # Centralized Wayland Environment Variables
  environment.sessionVariables = {
    # Wayland Core
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    
    # Wayland Backend Settings
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    OZONE_PLATFORM = "wayland";
    
    # Application-specific Wayland
    NIXOS_OZONE_WL = "1";           # Chromium/Electron apps
    MOZ_ENABLE_WAYLAND = "1";       # Firefox
    MOZ_WEBRENDER = "1";            # Firefox hardware acceleration
    MOZ_USE_XINPUT2 = "1";          # Firefox touch input
    
    # Qt Wayland
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    
    # Java AWT (for Java applications)
    _JAVA_AWT_WM_NONREPARENTING = "1";
    
    # Hyprland specific
    WLR_NO_HARDWARE_CURSORS = "1";  # Intel Arc/NVIDIA compatibility
    HYPRLAND_LOG_WLR = "1";
    
    # Default applications
    TERMINAL = "kitty";
    BROWSER = "brave";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}

