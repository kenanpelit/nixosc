# modules/home/default.nix
# ==============================================================================
# Home Manager Configuration
# ==============================================================================
# This configuration manages the import of all home-manager modules including:
# - Desktop environments and window managers
# - Application configurations and settings
# - Development tools and utilities
# - System customization and theming
# - Terminal environments and shells
# - Media and entertainment applications
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  imports = [
    # =============================================================================
    # Desktop Environment & Window Management
    # =============================================================================
    ./hyprland      # Hyprland Wayland compositor configuration
    ./sway          # Sway tiling window manager
    ./waybar        # Wayland status bar and system information
    ./rofi          # Application launcher and menu system
    ./swaylock      # Screen locker for Wayland sessions
    #./swaync        # Notification center and control
    ./mako          # Lightweight notification daemon for Wayland
    ./swayosd       # On-screen display for system controls
    ./gammastep     # Blue light filter and screen temperature
    ./mhyprsunset   # Advanced screen temperature control
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
    ./p10k          # Powerlevel10k prompt theme
    
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
    ./zen           # Zen browser setup and customization
    
    # =============================================================================
    # Media & Entertainment
    # =============================================================================
    ./audacious     # Lightweight audio player
    ./mpv           # Versatile media player configuration
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
    ./bat           # Syntax-highlighted file viewer
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
    ./copyq         # Advanced clipboard manager
    ./search        # File and content search utilities
    #./ulauncher     # Extensible application launcher
    #./walker        # Wayland application runner
    ./iwmenu        # Interactive WiFi management menu
    
    # =============================================================================
    # Remote & Network Tools
    # =============================================================================
    ./anydesk       # Remote desktop access client
    ./transmission  # BitTorrent client configuration
    
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

    # =============================================================================
    # Input & Gestures
    # =============================================================================
    ./fusuma        # Multi-touch gesture recognition
    ./touchegg      # Touch and gesture configuration
    
    # =============================================================================
    # AI & Machine Learning
    # =============================================================================
    #./ollama        # Local large language model management
    
    # =============================================================================
    # Document & Archive Management
    # =============================================================================
    ./candy         # Document and archive viewer
    ./subliminal    # Subtitle download and management
    ./zotfiles      # Zotero reference management integration
    
    # =============================================================================
    # Package Management
    # =============================================================================
    ./packages      # User-specific package configuration
    ./program       # Program-specific settings and overrides
  ];
}
