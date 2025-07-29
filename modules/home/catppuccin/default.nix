# ==============================================================================
# Catppuccin Theme Module
# ~/.nixosc/modules/home/catppuccin/default.nix
# ==============================================================================
# Global Catppuccin theming configuration for all supported applications
# This module provides centralized theming using Catppuccin Mocha Mauve
#
# Author: Kenan Pelit
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # GLOBAL CATPPUCCIN CONFIGURATION
  # ============================================================================
  catppuccin = {
    enable = true;
    flavor = "mocha";     # Dark theme variant (latte, frappe, macchiato, mocha)
    accent = "mauve";     # Accent color (rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender)
  };

  # ============================================================================
  # APPLICATION-SPECIFIC CATPPUCCIN ENABLEMENT
  # ============================================================================
  catppuccin = {
    # === Terminal Applications ===
    kitty.enable = lib.mkDefault true;     # GPU-accelerated terminal emulator
    foot.enable = lib.mkDefault true;      # Lightweight Wayland terminal
    
    # === System Monitoring ===
    btop.enable = lib.mkDefault true;      # Advanced system resource monitor
    
    # === File Management & Utilities ===
    bat.enable = lib.mkDefault true;       # Syntax-highlighted file viewer - RE-ENABLED with conflict fix
    
    # === Development Tools ===
    tmux.enable = lib.mkDefault true;      # Terminal multiplexer
    
    # === Wayland/Hyprland Ecosystem ===
    hyprland.enable = lib.mkDefault true;  # Wayland compositor
    waybar.enable = lib.mkDefault true;    # Status bar
    mako.enable = lib.mkDefault true;      # Notification daemon
    rofi.enable = lib.mkDefault true;      # Application launcher
    
    # === Media Applications ===
    mpv.enable = lib.mkDefault true;       # Media player
    
    # === Desktop Theming ===
    gtk.enable = lib.mkDefault false;      # GTK theming disabled - handled by GTK module
    cursors.enable = lib.mkDefault false;  # Cursor theming disabled - handled by GTK module
  };

  # ============================================================================
  # ADVANCED THEMING CONFIGURATIONS
  # ============================================================================
  
  # GTK specific Catppuccin customizations - DISABLED to avoid conflicts
  # catppuccin.gtk = {
  #   size = "standard";                     # Theme size variant (standard, compact)
  #   tweaks = [ "rimless" ];               # Visual tweaks (black, rimless, normal, float)
  #   icon = {
  #     enable = true;                       # Enable Catppuccin icon theme
  #     flavor = "mocha";                    # Icon theme flavor
  #     accent = "mauve";                    # Icon accent color
  #   };
  # };

  # ============================================================================
  # CURSOR THEME CONFIGURATION - DISABLED
  # ============================================================================
  # Cursor configuration is handled by the GTK module to avoid conflicts
  # See modules/home/gtk/default.nix for cursor settings
  
  # home.pointerCursor = lib.mkIf config.catppuccin.cursors.enable {
  #   name = "catppuccin-mocha-mauve-cursors";
  #   package = pkgs.catppuccin-cursors.mochaMauve;
  #   size = 24;                             # Cursor size in pixels
  #   gtk.enable = true;                     # Enable for GTK applications
  #   x11.enable = true;                     # Enable for X11 applications
  # };

  # Environment variables for cursor theme
  # home.sessionVariables = lib.mkIf config.catppuccin.cursors.enable {
  #   XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
  #   XCURSOR_SIZE = "24";
  # };

  # ============================================================================
  # ADDITIONAL THEMING NOTES
  # ============================================================================
  # Applications without direct Catppuccin support can be themed manually:
  # - fastfetch: No direct support yet
  # - git: No direct support in catppuccin/nix
  # - lazygit: No direct support yet
  # - firefox: Requires manual theme installation
  # - chrome/brave: Requires manual theme installation
  # - discord: Requires BetterDiscord + Catppuccin theme
  # - vscode: Available via extension marketplace
  # 
  # To disable any application theming, override in your host configuration:
  # catppuccin.APPLICATION.enable = lib.mkForce false;
}

