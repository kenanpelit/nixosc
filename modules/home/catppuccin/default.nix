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
  # GLOBAL CATPPUCCIN CONFIGURATION & APPLICATION-SPECIFIC ENABLEMENT
  # ============================================================================
  catppuccin = {
    # === Global Settings ===
    enable = true;
    flavor = "mocha";     # Dark theme variant (latte, frappe, macchiato, mocha)
    accent = "mauve";     # Accent color (rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender)
    
    # === Terminal Applications ===
    kitty.enable = lib.mkDefault true;        # GPU-accelerated terminal
    foot.enable = lib.mkDefault false;        # Lightweight Wayland terminal
    # wezterm - uses built-in Catppuccin, no module needed
    
    # === System Monitoring ===
    btop.enable = lib.mkDefault true;         # System resource monitor
    # cava - manual config, could be enabled if module exists
    
    # === File Management & Utilities ===
    bat.enable = lib.mkDefault true;          # Syntax-highlighted file viewer
    fzf.enable = lib.mkDefault true;          # Fuzzy finder (enable Catppuccin module)
    yazi.enable = lib.mkDefault true;         # File manager (enable instead of manual theme)
    
    # === Development Tools ===
    tmux.enable = lib.mkDefault true;         # Terminal multiplexer
    nvim.enable = lib.mkDefault true;         # Neovim (if you use it)
    lazygit.enable = lib.mkDefault true;      # Git TUI
    
    # === Wayland/Hyprland Ecosystem ===
    hyprland.enable = lib.mkDefault true;     # Wayland compositor
    waybar.enable = lib.mkDefault true;       # Status bar
    mako.enable = lib.mkDefault true;         # Notification daemon
    rofi.enable = lib.mkDefault true;         # Application launcher
    swaylock.enable = lib.mkDefault true;     # Screen locker
    
    # === Media Applications ===
    mpv.enable = lib.mkDefault true;          # Media player
    
    # === Desktop Theming ===
    gtk.enable = lib.mkDefault false;         # GTK theming disabled - handled by GTK module (deprecated upstream)
    cursors.enable = lib.mkDefault true;      # Cursor theming enabled - works fine
  };
}

