# modules/core/default.nix
# ==============================================================================
# System Core Configuration
# ==============================================================================
# This module serves as the entry point for the system-level NixOS configuration.
# It imports all core modules, organized by category:
# - Base System & Hardware
# - Networking & Connectivity
# - Security & Hardening
# - Desktop Environment & Display
# - Virtualization & Containers
# - System Services & Packages
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, nixpkgs, self, username, host, lib, ... }:

{
  imports = [
    # ==========================================================================
    # Base System & Hardware
    # ==========================================================================
    ./system        # Host role and identity
    ./boot          # Bootloader configuration
    ./kernel        # Kernel parameters and modules
    ./sysctl        # Kernel sysctl tuning
    ./hardware      # Hardware support (GPU, Firmware)
    ./power         # Power management services
    ./nix           # Nix daemon and flake settings
    ./locale        # Localization and console settings
    ./account       # User account management

    # ==========================================================================
    # Networking & Connectivity
    # ==========================================================================
    ./networking    # NetworkManager and SSH
    ./vpn           # VPN services (Mullvad, etc.)
    ./tcp           # TCP/IP stack tuning
    ./dns           # DNS configuration
    ./firewall      # Firewall rules (nftables/iptables)
    ./bluetooth     # Bluetooth stack

    # ==========================================================================
    # Security & Hardening
    # ==========================================================================
    ./sops          # Secret management
    ./fail2ban      # Intrusion prevention
    ./audit         # System auditing
    ./apparmor      # Mandatory access control
    ./polkit        # Privilege escalation management
    ./hblock        # DNS-based ad blocking

    # ==========================================================================
    # Desktop Environment & Display
    # ==========================================================================
    ./display       # Display stack options
    ./dm            # Display Manager (GDM)
    ./desktop       # Desktop services (dbus, etc.)
    ./sessions      # Session definitions
    ./portals       # XDG Desktop Portals
    ./fonts         # System fonts
    ./audio         # PipeWire audio stack
    ./logind        # Systemd logind configuration

    # ==========================================================================
    # Virtualization & Containers
    # ==========================================================================
    ./virtualization # Libvirt/QEMU setup
    ./containers     # Podman/Docker setup

    # ==========================================================================
    # Services & Packages
    # ==========================================================================
    ./packages      # Essential system packages
    ./flatpak       # Flatpak support
    ./gaming        # Gaming optimizations (Steam, etc.)
  ];
}
