# ==============================================================================
# Core System Configuration
# Author: kenanpelit
# Description: Main imports for core system configuration
# ==============================================================================

{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    ./audio          # Audio
    ./bluetooth      # Bluetooth
    ./bootloader     # Boot-Grub and EFI settings
    ./flatpak        # Flatpak support
    ./fonts          # Font management
    ./gnupg          # GnuGP
    ./hardware       # Hardware configuration
    ./mullvad        # Mullvad management
    ./network        # Network management
    ./nh             # Nix helper tools
    ./nixconf        # Nix helper tools
    ./packages
    ./pipewire       # Audio system
    ./podman         # Rootless Podman
    ./power          # Power settings
    ./program        # Core programs
    ./security       # Security settings
    ./services       # System services
    ./ssh            # SSH system config
    ./steam          # Gaming setup
    ./system         # Core system config
    ./user           # User management
    ./virtualization # VM support
    ./wayland        # Wayland config
    ./xserver        # X server settings
  ];
}
