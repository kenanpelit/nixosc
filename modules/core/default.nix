# modules/core/default.nix
# ==============================================================================
# Core System Configuration
# ==============================================================================
# This configuration manages the import of all core system modules including:
# - System foundation and hardware management
# - Desktop environment and multimedia support
# - Network and security configurations
# - Virtualization and gaming services
# - Development and user environment
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    # =============================================================================
    # System Foundation
    # =============================================================================
    ./account       # User account management and configuration
    ./boot          # Boot loader and kernel configuration
    ./hardware      # Hardware-specific settings and drivers
    ./system        # Core system settings and configuration
    ./power         # Power management and thermal control
    
    # =============================================================================
    # Package Management & Development
    # =============================================================================
    ./nix           # Nix daemon settings and store optimization
    ./nixpkgs       # Package configuration, overlays, and unfree packages
    ./packages      # System-wide package management
    ./cache         # Build cache and substituter configuration
    ./nh            # Nix Helper tool for easier system management
    
    # =============================================================================
    # Desktop Environment & Media
    # =============================================================================
    ./fonts         # Font configuration and rendering optimization
    ./wayland       # Wayland compositor and protocols
    ./x11           # X11 display server configuration
    ./xdg           # Desktop portals and integration
    ./audio         # Audio system, PipeWire, and sound management
    
    # =============================================================================
    # Network & Connectivity
    # =============================================================================
    ./dns           # DNS configuration and nameserver management
    ./firewall      # Firewall rules and network security
    ./powersave     # Network power optimization and WiFi tuning
    ./ssh           # SSH server and client configuration
    ./tcp           # TCP optimization and network performance
    ./vpn           # VPN client configuration and routing
    ./wireless      # WiFi management and wireless networking
    
    # =============================================================================
    # Security & Authentication
    # =============================================================================
    ./keyring       # Credential storage and GNOME keyring integration
    ./pam           # Pluggable Authentication Modules
    ./security      # System security policies and hardening
    ./sops          # Secrets management and encryption
    ./hblock        # DNS-based ad blocking and filtering
    
    # =============================================================================
    # Services & Applications
    # =============================================================================
    ./services      # Core system services and daemons
    ./flatpak       # Flatpak application sandboxing and management
    ./transmission  # BitTorrent client and network configuration
    ./home          # Home directory management and user environment
    ./programs      # Core program defaults and system-wide settings
    
    # =============================================================================
    # Virtualization & Containers
    # =============================================================================
    ./containers    # Container registry and runtime configuration
    ./podman        # Podman container engine and Docker compatibility
    ./spice         # SPICE guest services and USB redirection
    ./vm            # Virtual machine configuration and management
    
    # =============================================================================
    # Gaming & Performance
    # =============================================================================
    ./gamescope     # Gaming compositor and performance optimization
    ./steam         # Steam gaming platform and compatibility layers
  ];
}
