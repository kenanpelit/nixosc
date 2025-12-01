# modules/home/default.nix
# ==============================================================================
# Home Manager Configuration
# ==============================================================================
# This module imports all home-manager modules and global themes:
# - Desktop environments and window managers
# - Application configurations and settings
# - Development tools and utilities
# - System customization and theming
# - Terminal environments and shell configurations
# - Media and entertainment applications
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    # Global theme modules
    inputs.catppuccin.homeModules.catppuccin

    # =============================================================================
    # Desktop Environment & Window Management
    # =============================================================================
    ./hyprland      # Hyprland Wayland compositor configuration
    ./sway          # Sway tiling window manager
    ./cosmic        # Cosmic tiling desktop
    ./gnome         # Library with common API for various GNOME modules
    ./waybar        # Wayland status bar and system information
    #./hyprpanel     # Bar/Panel for Hyprland with extensive customizability
    ./rofi          # Application launcher and menu system
    ./swaylock      # Screen locker for Wayland sessions
    #./swaync        # Notification center and control
    ./mako          # Lightweight notification daemon for Wayland
    ./swayosd       # On-screen display for system controls
    ./blue          # Blue light filter and screen temperature
    ./waypaper      # Wallpaper management for Wayland
    ./wpaperd       # Wallpaper daemon and rotation
    
    # =============================================================================
    # Terminal Environment & Shell
    # =============================================================================
    ./foot          # Lightweight Wayland terminal emulator
    ./kitty         # GPU-accelerated terminal with advanced features
    ./wezterm       # Cross-platform terminal with multiplexing
    ./tmux          # Terminal multiplexer and session management
    ./zsh           # Z shell configuration and plugins
    ./starship      # Z shell configuration
    #./bash
    
    # =============================================================================
    # Development & Code Editing
    # =============================================================================
    ./nvim          # Neovim editor with LSP and plugins
    ./git           # Git version control configuration
    ./lazygit       # Terminal UI for Git operations
    ./sesh          # Session and project management
    
    # =============================================================================
    # Web Browsers
    # =============================================================================
    ./firefox       # Firefox browser with privacy enhancements
    ./chrome        # Google Chrome configuration
    ./brave         # Brave browser with ad blocking
    ./vivaldi       # Vivaldi browser with ad blocking
    ./zen           # Zen browser setup and customization
    
    # =============================================================================
    # Media & Entertainment
    # =============================================================================
    ./audacious     # Lightweight audio player
    ./mpv           # Versatile media player configuration
    ./vlc           # Versatile media player configuration
    ./mpd           # Music Player Daemon setup
    ./cava          # Console-based audio visualizer
    #./spicetify     # Spotify client customization
    #./radio         # Internet radio streaming
    
    # =============================================================================
    # Communication & Social
    # =============================================================================
    ./webcord       # Discord client with privacy features
    ./elektron      # Electron application management
    
    # =============================================================================
    # File Management & Utilities
    # =============================================================================
    ./nemo          # Graphical file manager
    ./yazi          # Terminal-based file manager
    ./fzf           # Fuzzy finder for files and commands
    ./rsync         # File synchronization and backup
    ./ytdlp         # YouTube and media downloader
    
    # =============================================================================
    # System Monitoring & Information
    # =============================================================================
    ./btop          # Advanced system resource monitor
    ./fastfetch     # Fast system information display
    ./scripts       # Custom shell scripts and utilities
    ./command-not-found # Command suggestion system
    
    # =============================================================================
    # Productivity & Office
    # =============================================================================
    ./obsidian      # Knowledge management and note-taking
    ./clipse        # Advanced clipboard manager
    #./copyq         # Advanced clipboard manager
    ./search        # File and content search utilities
    #./ulauncher     # Extensible application launcher
    ./walker        # Wayland application runner
    #./iwmenu        # Interactive WiFi management menu
    
    # =============================================================================
    # Remote & Network Tools
    # =============================================================================
    ./anydesk       # Remote desktop access client
    ./transmission  # BitTorrent client configuration
    
    # =============================================================================
    # Device Integration & Sharing
    # =============================================================================
    ./connect       # KDE Connect (Hyprland-friendly device integration)

    # =============================================================================
    # Security & Privacy
    # =============================================================================
    ./gnupg         # GPG key management and encryption
    ./password-store # Command-line password manager
    ./sops          # Secrets and configuration management
    
    # =============================================================================
    # System Integration & Theming
    # =============================================================================
    ./catppuccin    # Catppuccin theme configuration for all supported apps
    ./gtk           # GTK application theme and styling
    ./qt            # Qt application theme configuration
    ./xdg-dirs      # XDG user directory specification
    ./xdg-mimes     # MIME type associations and defaults
    ./xdg-portal    # Desktop portal configuration
    ./xserver       # X11 server configuration and settings
    ./candy         # Icon theme colored with sweet gradients

    # =============================================================================
    # Input & Gestures
    # =============================================================================
    ./fusuma        # Multi-touch gesture recognition
    ./touchegg      # Touch and gesture configuration
    
    # =============================================================================
    # AI & Machine Learning
    # =============================================================================
    #./ollama        # Local large language model management
    ./ai            # AI & LLM configuration
    
    # =============================================================================
    # Document & Archive Management
    # =============================================================================
    ./subliminal    # Subtitle download and management
    #./zotfiles      # Zotero reference management integration
    
    # =============================================================================
    # Package Management
    # =============================================================================
    ./flatpak       # User-level Flatpak management (via nix-flatpak HM module)
    ./maple         # Local Maple Mono font package set
    ./packages      # User-specific package configuration
    ./program       # Program-specific settings and overrides
  ];
}
