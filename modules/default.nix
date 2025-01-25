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
# Core System Configuration (/modules/core)
# ==============================================================================
#
# ├── desktop/          # Display servers and user interface foundations
# │   ├── fonts         # System-wide font configuration and packages
# │   ├── wayland       # Wayland display server configuration and protocols
# │   ├── x11           # X11 display server settings and extensions
# │   ├── xdg           # XDG base directory and specifications
# │   └── default.nix   # Combined desktop environment settings
# │
# ├── gaming/           # Gaming support and optimization
# │   ├── gamescope     # Valve's game-specific display compositor
# │   ├── performance   # Gaming performance optimizations
# │   ├── steam         # Steam platform and runtime configuration
# │   └── default.nix   # Gaming environment integration
# │
# ├── media/            # Media subsystems and services
# │   ├── audio         # Audio system configuration (PulseAudio/PipeWire)
# │   ├── bluetooth     # Bluetooth stack and device management
# │   └── default.nix   # Media services coordination
# │
# ├── network/          # Network stack and connectivity
# │   ├── base          # Basic networking configuration
# │   ├── dns           # DNS resolver and configuration
# │   ├── firewall      # Firewall rules and security
# │   ├── powersave     # Network power management
# │   ├── ssh           # SSH server/client configuration
# │   ├── tcp           # TCP stack optimization
# │   ├── vpn           # VPN service configuration
# │   ├── wireless      # Wireless networking setup
# │   └── default.nix   # Network integration
# │
# ├── nix/              # Nix package manager configuration
# │   ├── cache         # Binary cache settings
# │   ├── config        # Nix configuration options
# │   ├── nh            # Nix command wrapper and utilities
# │   ├── settings      # Advanced Nix settings
# │   └── default.nix   # Package manager integration
# │
# ├── security/        # System security framework
# │   ├── hblock       # Ad/tracker blocking at system level
# │   ├── keyring      # System keyring and credential management
# │   ├── pam          # PAM authentication configuration
# │   └── default.nix  # Security integration
# │
# ├── services/        # System-wide services
# │   ├── base         # Core system services
# │   ├── flatpak      # Flatpak application support
# │   ├── network      # Network-related services
# │   ├── security     # Security-related services
# │   └── default.nix  # Service coordination
# │
# ├── system/          # Core system configuration
# │   ├── base         # Base system settings
# │   ├── boot         # Boot loader and early boot
# │   ├── hardware     # Hardware support and drivers
# │   ├── power        # Power management settings
# │   └── default.nix  # System integration
# │
# ├── user/            # User account management
# │   ├── account      # User account configuration
# │   ├── home         # User home directory setup
# │   ├── packages     # User-specific packages
# │   ├── programs     # User program settings
# │   └── default.nix  # User environment integration
# │
# ├── virtualization/  # Virtualization support
# │   ├── container    # Container runtime configuration
# │   ├── podman       # Podman container platform
# │   ├── spice        # SPICE protocol support
# │   ├── vm           # Virtual machine settings
# │   └── default.nix  # Virtualization integration
# │
# └── default.nix      # Core module coordination
#
# ==============================================================================
# Home User Configuration (/modules/home)
# ==============================================================================
#
# ├── apps/            # User applications
# │   ├── elektron     # Elektron audio workstation
# │   ├── obsidian     # Knowledge management
# │   ├── webcord      # Discord client
# │   ├── ytdlp        # Video downloader
# │   ├── zotfiles     # Reference management
# │   └── default.nix  # Application integration
# │
# ├── browser/         # Web browsers
# │   ├── chrome       # Google Chrome configuration
# │   ├── firefox      # Firefox configuration
# │   ├── zen          # Browser customization
# │   └── default.nix  # Browser integration
# │
# ├── desktop/         # Desktop environment
# │   ├── gtk          # GTK theme and settings
# │   ├── hyprland     # Hyprland compositor
# │   ├── hyprsunset   # Auto dark mode
# │   ├── qt           # Qt theme and settings
# │   ├── rofi         # Application launcher
# │   ├── sway         # Sway window manager
# │   ├── swaylock     # Screen locker
# │   ├── swaync       # Notification center
# │   ├── swayosd      # On-screen display
# │   ├── ulauncher    # Application launcher
# │   ├── waybar       # Status bar
# │   ├── waypaper     # Wallpaper manager
# │   ├── wofi         # Application launcher
# │   ├── wpaperd      # Dynamic wallpapers
# │   ├── xserver      # X server config
# │   └── default.nix  # Desktop integration
# │
# ├── development/     # Development tools
# │   ├── git          # Git configuration
# │   ├── lazygit      # Git terminal UI
# │   ├── nvim         # Neovim editor
# │   └── default.nix  # Development integration
# │
# ├── file/            # File management
# │   ├── nemo         # File manager
# │   ├── yazi         # Terminal file manager
# │   └── default.nix  # File manager integration
# │
# ├── gnome/           # GNOME specific settings
# │   └── default.nix  # GNOME integration
# │
# ├── media/           # Media applications
# │   ├── audacious    # Audio player
# │   ├── cava         # Audio visualizer
# │   ├── mpd          # Music player daemon
# │   ├── mpv          # Media player
# │   ├── spicetify    # Spotify customization
# │   └── default.nix  # Media integration
# │
# ├── network/         # Network utilities
# │   ├── anydesk      # Remote desktop
# │   ├── rsync        # File synchronization
# │   ├── transmission # Torrent client
# │   └── default.nix  # Network tool integration
# │
# ├── security/           # Security tools
# │   ├── gnupg           # GPG encryption
# │   ├── password-store  # Password manager
# │   ├── sops            # Secrets management
# │   └── default.nix     # Security integration
# │
# ├── services/       # User services
# │   ├── fusuma      # Touchpad gestures
# │   ├── touchegg    # Touchscreen gestures
# │   └── default.nix # Service integration
# │
# ├── system/               # System utilities
# │   ├── btop              # System monitor
# │   ├── command-not-found # Command suggestions
# │   ├── fastfetch         # System information
# │   ├── fzf               # Fuzzy finder
# │   ├── gammastep         # Color temperature
# │   ├── packages          # System packages
# │   ├── program           # System programs
# │   ├── scripts           # Utility scripts
# │   └── default.nix       # System tool integration
# │
# ├── terminal/        # Terminal environment
# │   ├── foot         # Terminal emulator
# │   ├── kitty        # Terminal emulator
# │   ├── p10k         # Shell theme
# │   ├── tmux         # Terminal multiplexer
# │   ├── wezterm      # Terminal emulator
# │   ├── zsh          # Shell configuration
# │   └── default.nix  # Terminal integration
# │
# ├── utility/         # General utilities
# │   ├── bat          # Text file viewer
# │   ├── candy        # Icon theme
# │   ├── copyq        # Clipboard manager
# │   ├── iwmenu       # Menu interface
# │   ├── sem          # CLI semaphore
# │   ├── sesh         # Session manager
# │   └── default.nix  # Utility integration
# │
# ├── xdg/             # XDG specification
# │   ├── xdg-dirs     # XDG directories
# │   ├── xdg-mimes    # MIME types
# │   ├── xdg-portal   # Desktop portals
# │   └── default.nix  # XDG integration
# │
# └── default.nix      # Home module coordination
#
# Each directory contains its own default.nix for modular configuration
# ==============================================================================
