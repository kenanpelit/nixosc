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
# Note: Modules have been consolidated for better organization and maintenance
#
# Author: Kenan Pelit
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  imports = [
    # =============================================================================
    # Desktop and UI
    # =============================================================================
    ./desktop       # Window managers, bars, notifications, launchers
    ./media         # Audio, video players, and media tools
    ./gnome         # GNOME Desktop Environment Configuration  
    
    # =============================================================================
    # Applications
    # =============================================================================
    ./apps          # Discord, Electron apps, document viewers
    ./browser       # Web browser configurations
    
    # =============================================================================
    # Development and Files
    # =============================================================================
    ./development   # Git, Neovim, development tools
    ./file          # File managers and document viewers
    
    # =============================================================================
    # System and Security
    # =============================================================================
    ./system        # Scripts, monitoring, and system utilities
    ./security      # GnuPG, password management, encryption
    
    # =============================================================================
    # Network and Services
    # =============================================================================
    ./network       # Remote desktop, file sync, torrent client
    ./services      # System services and daemons
    
    # =============================================================================
    # Terminal Environment
    # =============================================================================
    ./terminal      # Terminal emulators, shell, multiplexer
    ./utility       # CLI tools and utilities
    
    # =============================================================================
    # System Integration
    # =============================================================================
    ./xdg           # XDG specifications and portals
  ];
}
