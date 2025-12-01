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
# ├── apparmor/         # Mandatory Access Control (MAC) using AppArmor
# ├── audio/            # PipeWire audio stack configuration
# ├── bluetooth/        # Bluetooth stack and device management
# ├── boot/             # Bootloader (GRUB) and EFI configuration
# ├── containers/       # Podman container engine configuration
# ├── desktop/          # Essential desktop integration services
# ├── display/          # Display stack options and desktop environment toggles
# ├── dm/               # Display Manager (GDM) and session selection
# ├── dns/              # systemd-resolved DNS configuration
# ├── fail2ban/         # Intrusion prevention service
# ├── firewall/         # System firewall rules (nftables)
# ├── flatpak/          # Flatpak application management
# ├── fonts/            # System-wide font configuration
# ├── gaming/           # Gaming-related software and optimizations
# ├── hardware/         # Hardware-specific settings and drivers
# ├── hblock/           # DNS-based ad blocking
# ├── kernel/           # Linux kernel parameters and modules
# ├── locale/           # Localization, timezone, and console keyboard
# ├── logind/           # systemd-logind power and lid switch policy
# ├── networking/       # NetworkManager and SSH client settings
# ├── nix/              # Nix daemon settings and store optimization
# ├── packages/         # Essential system-wide packages
# ├── polkit/           # Privilege escalation management
# ├── portals/          # XDG portals for Wayland integration
# ├── power/            # Advanced power management services
# ├── sessions/         # Desktop session definitions for GDM
# ├── sops/             # System-level secrets management
# ├── sysctl/           # Kernel sysctl tuning
# ├── system/           # Core system metadata and global defaults
# ├── tcp/              # TCP/IP network tuning
# ├── virtualization/   # Libvirt/QEMU virtualization stack
# ├── vpn/              # VPN client configuration (Mullvad)
# └── default.nix       # Orchestrates all core module imports

# ==============================================================================
# Home User Configuration (/modules/home)
# ==============================================================================
#
# ├── ai/                 # AI/LLM CLI tools (Claude, Gemini, OpenAI)
# ├── anydesk/            # Remote desktop client configuration
# ├── audacious/          # Audacious music player settings
# ├── bash/               # Bash shell configuration and profiles
# ├── blue/               # Blue light filter (Gammastep/HyprSunset)
# ├── btop/               # Btop system monitor settings
# ├── candy/              # Icon theme (A-Candy-Beauty)
# ├── catppuccin/         # Global Catppuccin theme configuration
# ├── cava/               # Cava audio visualizer
# ├── chrome/             # Google Chrome browser configuration
# ├── clipse/             # Clipse clipboard manager
# ├── command-not-found/  # Nix-index for command suggestions
# ├── connect/            # KDE Connect integration
# ├── cosmic/             # COSMIC desktop environment user config
# ├── copyq/              # CopyQ clipboard manager
# ├── elektron/           # Electron app wrappers
# ├── fastfetch/          # Fastfetch system info tool
# ├── firefox/            # Firefox browser configuration
# ├── flatpak/            # User-level Flatpak management
# ├── foot/               # Foot terminal emulator
# ├── fzf/                # FZF fuzzy finder
# ├── git/                # Git configuration and aliases
# ├── gnome/              # GNOME desktop environment settings
# ├── gnupg/              # GnuPG setup and gpg-agent
# ├── gtk/                # GTK theme and settings
# ├── hyprland/           # Hyprland Wayland compositor configuration
# ├── hyprpanel/          # Hyprpanel status bar (if enabled)
# ├── iwmenu/             # Interactive WiFi menu (iwgtk based)
# ├── kitty/              # Kitty terminal emulator
# ├── lazygit/            # Lazygit TUI for Git
# ├── mako/               # Mako Wayland notification daemon
# ├── mpd/                # Music Player Daemon (MPD)
# ├── mpv/                # MPV media player configuration
# ├── nemo/               # Nemo file manager
# ├── nvim/               # Neovim text editor
# ├── obsidian/           # Obsidian note-taking app
# ├── ollama/             # Ollama LLM service (user-level)
# ├── packages/           # User-specific packages (system-independent)
# ├── password-store/     # Pass password manager
# ├── program/            # Core program defaults (user-level)
# ├── qt/                 # Qt theme and settings
# ├── radio/              # Radiotray-ng bookmarks
# ├── rofi/               # Rofi application launcher
# ├── rsync/              # Rsync home directory backup excludes
# ├── scripts/            # Custom shell scripts (bin/start)
# ├── search/             # Global search utilities
# ├── sesh/               # Terminal session manager
# ├── sops/               # User-level SOPS secrets management
# ├── spicetify/          # Spicetify for Spotify theming
# ├── starship/           # Starship shell prompt
# ├── subliminal/         # Subliminal subtitle downloader
# ├── sway/               # Sway tiling window manager
# ├── swaylock/           # Swaylock screen locker
# ├── swaync/             # Sway Notification Center
# ├── swayosd/            # Sway On-Screen Display
# ├── tmux/               # Tmux terminal multiplexer
# ├── touchegg/           # Touchégg gesture management
# ├── transmission/       # Transmission BitTorrent client
# ├── ulauncher/          # Ulauncher application launcher
# ├── vivaldi/            # Vivaldi browser configuration
# ├── walker/             # Walker Wayland launcher
# ├── waybar/             # Waybar status bar
# ├── waypaper/           # Waypaper wallpaper manager
# ├── webcord/            # WebCord (Discord client)
# ├── wezterm/            # WezTerm terminal emulator
# ├── wpaperd/            # Wpaperd dynamic wallpaper daemon
# ├── xdg-dirs/           # XDG user directories
# ├── xdg-mimes/          # XDG MIME type associations
# ├── xdg-portal/         # XDG portal configuration
# ├── xserver/            # X11/XWayland session environment
# ├── yazi/               # Yazi terminal file manager
# ├── ytdlp/              # yt-dlp video downloader
# ├── zen/                # Zen browser configuration
# ├── zotfiles/           # Zotero attachment management
# └── zsh/                # Zsh shell configuration
#
# Each directory contains its own default.nix for modular configuration
