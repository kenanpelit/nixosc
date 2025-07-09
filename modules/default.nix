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
# ├── account/          # User account management and configuration
# ├── audio/            # Audio system configuration (PipeWire/PulseAudio)
# ├── bluetooth/        # Bluetooth stack and device management
# ├── boot/             # Boot loader and kernel configuration
# ├── cache/            # Build cache and substituter configuration
# ├── containers/       # Container registry and runtime configuration
# ├── dns/              # DNS configuration and nameserver management
# ├── firewall/         # Firewall rules and network security
# ├── flatpak/          # Flatpak application sandboxing and management
# ├── fonts/            # Font configuration and rendering optimization
# ├── gamescope/        # Gaming compositor and performance optimization
# ├── hardware/         # Hardware-specific settings and drivers
# ├── hblock/           # DNS-based ad blocking and filtering
# ├── home/             # Home directory management and user environment
# ├── keyring/          # Credential storage and GNOME keyring integration
# ├── nh/               # Nix Helper tool for easier system management
# ├── nix/              # Nix daemon settings and store optimization
# ├── nixpkgs/          # Package configuration, overlays, and unfree packages
# ├── packages/         # System-wide package management
# ├── pam/              # Pluggable Authentication Modules
# ├── podman/           # Podman container engine and Docker compatibility
# ├── power/            # Power management and thermal control
# ├── powersave/        # Network power optimization and WiFi tuning
# ├── programs/         # Core program defaults and system-wide settings
# ├── security/         # System security policies and hardening
# ├── services/         # Core system services and daemons
# ├── sops/             # Secrets management and encryption
# ├── spice/            # SPICE guest services and USB redirection
# ├── ssh/              # SSH server and client configuration
# ├── steam/            # Steam gaming platform and compatibility layers
# ├── system/           # Core system settings and configuration
# ├── tcp/              # TCP optimization and network performance
# ├── transmission/     # BitTorrent client and network configuration
# ├── vm/               # Virtual machine configuration and management
# ├── vpn/              # VPN client configuration and routing
# ├── wayland/          # Wayland compositor and protocols
# ├── wireless/         # WiFi management and wireless networking
# ├── x11/              # X11 display server configuration
# ├── xdg/              # Desktop portals and integration
# └── default.nix       # Core module coordination (imports all above)
#
# ==============================================================================
# Home User Configuration (/modules/home)
# ==============================================================================
#
# ├── anydesk/          # Remote desktop client
# ├── audacious/        # Audio player
# ├── bat/              # Text file viewer with syntax highlighting
# ├── brave/            # Brave web browser
# ├── btop/             # System monitor and process viewer
# ├── candy/            # Icon theme and visual customization
# ├── cava/             # Audio visualizer
# ├── chrome/           # Google Chrome browser configuration
# ├── command-not-found/ # Command suggestions for missing packages
# ├── copyq/            # Clipboard manager
# ├── elektron/         # Elektron audio workstation
# ├── fastfetch/        # System information display tool
# ├── firefox/          # Firefox web browser configuration
# ├── foot/             # Lightweight Wayland terminal emulator
# ├── fusuma/           # Touchpad gesture recognition
# ├── fzf/              # Fuzzy finder for command line
# ├── gammastep/        # Color temperature adjustment
# ├── git/              # Git version control configuration
# ├── gnome/            # GNOME desktop environment settings
# ├── gnupg/            # GPG encryption and key management
# ├── gtk/              # GTK theme and application settings
# ├── hyprland/         # Hyprland compositor configuration
# ├── iwmenu/           # Interactive menu interface
# ├── kitty/            # Terminal emulator
# ├── lazygit/          # Terminal UI for Git
# ├── mhyprsunset/      # Automated sunset/sunrise theme switching
# ├── mpd/              # Music Player Daemon
# ├── mpv/              # Media player
# ├── nemo/             # File manager
# ├── nvim/             # Neovim text editor configuration
# ├── obsidian/         # Knowledge management and note-taking
# ├── ollama/           # Large language model runner
# ├── p10k/             # Powerlevel10k shell theme
# ├── packages/         # User-specific package management
# ├── password-store/   # Password manager (pass)
# ├── program/          # Program-specific configurations
# ├── qt/               # Qt application theme and settings
# ├── radio/            # Radio streaming applications
# ├── rofi/             # Application launcher and window switcher
# ├── rsync/            # File synchronization tool
# ├── scripts/          # Custom utility scripts
# ├── search/           # Search tools and configuration
# ├── sesh/             # Session management tool
# ├── sops/             # Secrets management
# ├── spicetify/        # Spotify client customization
# ├── subliminal/       # Subtitle download tool
# ├── sway/             # Sway window manager configuration
# ├── swaylock/         # Screen locker for Wayland
# ├── swaync/           # Notification center for Sway
# ├── swayosd/          # On-screen display for Sway
# ├── tmux/             # Terminal multiplexer
# ├── touchegg/         # Touchscreen gesture recognition
# ├── transmission/     # BitTorrent client
# ├── ulauncher/        # Application launcher
# ├── walker/           # Application walker/launcher
# ├── waybar/           # Status bar for Wayland compositors
# ├── waypaper/         # Wallpaper manager for Wayland
# ├── webcord/          # Discord client for Linux
# ├── wezterm/          # Terminal emulator
# ├── wpaperd/          # Dynamic wallpaper daemon
# ├── xdg-dirs/         # XDG user directories
# ├── xdg-mimes/        # MIME type associations
# ├── xdg-portal/       # Desktop portal configuration
# ├── xserver/          # X server configuration
# ├── yazi/             # Terminal file manager
# ├── ytdlp/            # YouTube-dl fork for video downloading
# ├── zen/              # Zen browser configuration
# ├── zotfiles/         # Reference management tool
# ├── zsh/              # Z shell configuration
# └── default.nix       # Home module coordination (imports all above)
#
# Each directory contains its own default.nix for modular configuration
# ==============================================================================
