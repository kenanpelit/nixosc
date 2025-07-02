# modules/home/default.nix
# ==============================================================================
# Home Manager Configuration
# ==============================================================================
# This configuration manages the import of all home-manager modules including:
# - Desktop environments and window managers
# - Application configurations and settings
# - Development tools and utilities
# - System customization and theming
#
# Module Structure:
# 1. Desktop Environment
#    - desktop/    → {hyprland, sway, waybar, rofi, ...}
#    - xdg/        → {xdg-dirs, xdg-mimes, xdg-portal}
#
# 2. Applications & Media
#    - apps/       → {elektron, obsidian, webcord, ...}
#    - browser/    → {chrome, firefox, zen}
#    - media/      → {audacious, mpv, spicetify, ...}
#
# 3. Development & Files
#    - development/→ {git, lazygit, nvim}
#    - file/       → {nemo, yazi}
#
# 4. System & Security
#    - system/     → {btop, fastfetch, scripts, ...}
#    - security/   → {gnupg, password-store, sops}
#    - services/   → {fusuma, touchegg}
#
# 5. Terminal & Utilities
#    - terminal/   → {foot, kitty, tmux, zsh, ...}
#    - utility/    → {bat, copyq, iwmenu, ...}
#    - network/    → {anydesk, rsync, transmission}
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  imports = [
    # =============================================================================
    # Desktop Environment
    # =============================================================================
    ./desktop       # Window managers, bars, notifications, launchers
    ./xdg           # XDG specifications and portals
    
    # =============================================================================
    # Applications & Media
    # =============================================================================
    ./apps          # Discord, Electron apps, document viewers
    ./browser       # Web browser configurations
    ./media         # Audio, video players, and media tools
    
    # =============================================================================
    # Development & Files
    # =============================================================================
    ./development   # Git, Neovim, development tools
    ./file          # File managers and document viewers
    
    # =============================================================================
    # System & Security
    # =============================================================================
    ./system        # Scripts, monitoring, and system utilities
    ./security      # GnuPG, password management, encryption
    ./services      # System services and daemons
    
    # =============================================================================
    # Terminal & Utilities
    # =============================================================================
    ./terminal      # Terminal emulators, shell, multiplexer
    ./utility       # CLI tools and utilities
    ./network       # Remote desktop, file sync, torrent client
  ];
}

