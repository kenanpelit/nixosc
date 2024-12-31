# ==============================================================================
# Core System Configuration
# Author: kenanpelit
# Description: Main imports for core system configuration
# ==============================================================================

{
  inputs,
  nixpkgs,
  self,
  username,
  host,
  lib,
  ...
}:
{
  imports = [
    ./bootloader.nix     # Boot and EFI settings
    ./fonts.nix          # Font management
    ./hardware.nix       # Hardware configuration
    ./xserver.nix        # X server settings
    ./network.nix        # Network management
    ./nh.nix             # Nix helper tools
    ./pipewire.nix       # Audio system
    ./program.nix        # Core programs
    ./security.nix       # Security settings
    ./services.nix       # System services
    ./steam.nix          # Gaming setup
    ./system.nix         # Core system config
    ./flatpak.nix        # Flatpak support
    ./user.nix           # User management
    ./wayland.nix        # Wayland config
    ./virtualization.nix # VM support
  ];
}

