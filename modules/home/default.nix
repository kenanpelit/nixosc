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
# Module Structure:
# 1. Desktop Environment & Window Management
#    - hyprland/     → Hyprland compositor configuration
#    - sway/         → Sway window manager settings
#    - waybar/       → Status bar for Wayland compositors
#    - rofi/         → Application launcher and menu system
#    - swaylock/     → Screen locker for Wayland
#    - swaync/       → Notification center for Sway
#    - swayosd/      → On-screen display for volume/brightness
#    - gammastep/    → Blue light filter for Wayland
#    - mhyprsunset/  → Screen temperature adjustment
#    - waypaper/     → Wallpaper manager for Wayland
#    - wpaperd/      → Wallpaper daemon
#
# 2. Terminal Environment & Shell
#    - foot/         → Lightweight Wayland terminal
#    - kitty/        → GPU-accelerated terminal emulator
#    - wezterm/      → Terminal with advanced features
#    - tmux/         → Terminal multiplexer
#    - zsh/          → Z shell configuration
#    - p10k/         → Powerlevel10k prompt theme
#
# 3. Development & Code Editing
#    - nvim/         → Neovim editor configuration
#    - git/          → Git version control settings
#    - lazygit/      → Terminal UI for git commands
#    - sesh/         → Session management tool
#
# 4. Web Browsers
#    - firefox/      → Firefox browser configuration
#    - chrome/       → Google Chrome settings
#    - brave/        → Brave browser configuration
#    - zen/          → Zen browser setup
#
# 5. Media & Entertainment
#    - audacious/    → Audio player configuration
#    - mpv/          → Video player settings
#    - mpd/          → Music Player Daemon
#    - cava/         → Console audio visualizer
#    - spicetify/    → Spotify customization
#    - radio/        → Internet radio player
#
# 6. Communication & Social
#    - webcord/      → Discord client configuration
#    - elektron/     → Electron app management
#
# 7. File Management & Utilities
#    - nemo/         → File manager configuration
#    - yazi/         → Terminal file manager
#    - bat/          → Enhanced cat command
#    - fzf/          → Fuzzy finder
#    - rsync/        → File synchronization
#    - ytdlp/        → YouTube downloader
#
# 8. System Monitoring & Information
#    - btop/         → System resource monitor
#    - fastfetch/    → System information display
#    - scripts/      → Custom shell scripts
#    - command-not-found/ → Command suggestion system
#
# 9. Productivity & Office
#    - obsidian/     → Knowledge management
#    - copyq/        → Clipboard manager
#    - search/       → File search utilities
#    - ulauncher/    → Application launcher
#    - walker/       → Wayland application runner
#    - iwmenu/       → WiFi management menu
#
# 10. Remote & Network Tools
#     - anydesk/     → Remote desktop client
#     - transmission/→ BitTorrent client
#
# 11. Security & Privacy
#     - gnupg/       → GPG encryption and signing
#     - password-store/ → Password management
#     - sops/        → Secrets management
#
# 12. System Integration & Theming
#     - gtk/         → GTK theme configuration
#     - qt/          → Qt application theming
#     - xdg-dirs/    → XDG user directories
#     - xdg-mimes/   → MIME type associations
#     - xdg-portal/  → Desktop portal configuration
#     - xserver/     → X11 server settings
#
# 13. Input & Gestures
#     - fusuma/      → Touchpad gesture recognition
#     - touchegg/    → Touch gesture configuration
#
# 14. AI & Machine Learning
#     - ollama/      → Local AI model management
#
# 15. Document & Archive Management
#     - candy/       → Document viewer
#     - subliminal/  → Subtitle downloader
#     - zotfiles/    → Zotero file management
#
# 16. Package Management
#     - packages/    → User package configuration
#     - program/     → Program-specific settings
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
    ./swaync        # Notification center and control
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
    ./radio         # Internet radio streaming
    
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
    ./ulauncher     # Extensible application launcher
    ./walker        # Wayland application runner
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
