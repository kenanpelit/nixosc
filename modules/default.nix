# modules/default.nix
# ==============================================================================
# NixOS System Configuration - Root Configuration
# Author: Kenan Pelit
# ==============================================================================

# This is the root configuration file that manages both system-level and 
# user-level configurations through a modular directory structure.

{ inputs, nixpkgs, self, username, host, lib, ... }:
{
 imports = [
   # Core System Configuration (NixOS)
   # Manages system-level settings, services and functionality
   ./core         

   # Home User Configuration (Home Manager)
   # Handles user-specific configurations and applications
   ./home         
 ];
}

# ==============================================================================
# Directory Structure Overview
# ==============================================================================
#
# /modules/core - System Level Configuration
# ├── desktop/          # Display servers and UI foundations
# │   ├── fonts        # Font configurations and packages
# │   ├── wayland      # Wayland display server setup
# │   ├── x11          # X11 display server configuration
# │   └── xdg          # XDG base directory specification
# │
# ├── gaming/          # Gaming support and optimization
# │   ├── gamescope    # Game-specific display server
# │   ├── performance  # Gaming performance tweaks
# │   └── steam        # Steam gaming platform setup
# │
# ├── media/           # System media capabilities
# │   ├── audio        # Audio subsystem configuration
# │   └── bluetooth    # Bluetooth connectivity
# │
# ├── network/         # Network infrastructure
# │   ├── base         # Basic networking setup
# │   ├── dns          # DNS configuration
# │   ├── firewall     # System firewall rules
# │   ├── powersave    # Network power management
# │   ├── ssh          # SSH server configuration
# │   ├── tcp          # TCP stack optimization
# │   ├── vpn          # VPN service integration
# │   └── wireless     # Wireless networking
# │
# ├── nix/            # Package management 
# │   ├── cache       # Binary cache configuration
# │   ├── config      # Nix package manager settings
# │   ├── nh          # Nix helper utilities
# │   └── settings    # Advanced Nix configurations
# │
# ├── security/       # System security framework
# │   ├── hblock      # Ad/tracker blocking
# │   ├── keyring     # System keyring management
# │   └── pam         # PAM authentication setup
# │
# ├── services/       # System services
# │   ├── base        # Essential system services
# │   ├── flatpak     # Flatpak application support
# │   ├── network     # Network-related services
# │   └── security    # Security services
# │
# ├── system/         # Core system setup
# │   ├── base        # Base system configuration
# │   ├── boot        # Boot loader and kernel
# │   ├── hardware    # Hardware support/drivers
# │   └── power       # Power management
# │
# ├── user/           # User management
# │   ├── account     # User account settings
# │   ├── home        # User home directory setup
# │   ├── packages    # User-specific packages
# │   └── programs    # User program configurations
# │
# └── virtualization/ # Virtualization support
#     ├── container   # Container runtime setup
#     ├── podman      # Podman container support
#     ├── spice       # SPICE protocol support
#     └── vm          # Virtual machine configuration
#
# /modules/home - User Level Configuration
# ├── apps/           # User applications
# │   ├── elektron    # Elektron audio tools
# │   ├── obsidian    # Note-taking application
# │   ├── webcord     # Discord client
# │   └── ytdlp       # Video downloader
# │
# ├── browser/        # Web browsers
# │   ├── chrome      # Chrome configuration
# │   ├── firefox     # Firefox setup
# │   └── zen         # Browser extensions
# │
# ├── desktop/        # Desktop environment
# │   ├── hyprland    # Hyprland compositor
# │   ├── waybar      # Status bar
# │   ├── waypaper    # Wallpaper manager
# │   └── various WMs # Other window managers
# │
# ├── development/    # Development tools
# │   ├── git         # Version control
# │   ├── lazygit     # Git TUI
# │   └── nvim        # Neovim editor
# │
# ├── media/          # Media applications
# │   ├── mpv         # Media player
# │   ├── mpd         # Music player daemon
# │   └── spicetify   # Spotify customization
# │
# ├── security/       # User security
# │   ├── gnupg       # GPG encryption
# │   ├── pass        # Password manager
# │   └── sops        # Secrets management
# │
# ├── system/         # System utilities
# │   ├── btop        # System monitor
# │   ├── fastfetch   # System information
# │   └── scripts     # User scripts
# │
# ├── terminal/       # Terminal environment
# │   ├── foot        # Terminal emulator
# │   ├── tmux        # Terminal multiplexer
# │   └── zsh         # Shell configuration
# │
# └── xdg/            # XDG compliance
#     ├── xdg-dirs    # Directory structure
#     └── xdg-portal  # Desktop integration
#
# Note: Each directory contains a default.nix that manages its specific domain
# ==============================================================================
