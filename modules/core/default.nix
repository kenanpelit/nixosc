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
   ./account       # User account management, authentication, and keyring integration
   ./boot          # Boot loader and kernel configuration
   #./hardware      # Hardware-specific settings and drivers
   ./system        # Core system settings and configuration
   ./power         # Power management, thermal control, and WiFi optimization
   
   # =============================================================================
   # Package Management & Development
   # =============================================================================
   ./nix           # Nix ecosystem: daemon, store optimization, NH helper, and nixpkgs configuration
   ./packages      # System-wide package management
   ./cache         # Build cache and substituter configuration
   
   # =============================================================================
   # Desktop Environment & Media
   # =============================================================================
   ./fonts         # Font configuration and rendering optimization
   ./display       # X11, Wayland, GDM, GNOME, and Hyprland configuration
   ./xdg           # Desktop portals and integration
   ./audio         # Audio system, PipeWire, and sound management
   
   # =============================================================================
   # Network & Connectivity
   # =============================================================================
   ./networking    # DNS, WiFi, VPN (Mullvad), and network management
   ./tcp           # TCP optimization and network performance
   
   # =============================================================================
   # Security & Authentication
   # =============================================================================
   ./security      # Firewall, PAM, SSH, PolicyKit, and system security hardening
   ./sops          # Secrets management and encryption
   ./hblock        # DNS-based ad blocking and filtering
   
   # =============================================================================
   # Services & Applications
   # =============================================================================
   ./services      # Core system services, Bluetooth, and daemons
   ./flatpak       # Flatpak application sandboxing and management
   ./transmission  # BitTorrent client and network configuration
   ./home          # Home directory management and user environment
   ./programs      # Core program defaults and system-wide settings
   
   # =============================================================================
   # Virtualization & Containers
   # =============================================================================
   ./virtualisation # Container runtime (Podman), VM engine (LibvirtD/QEMU), and virtualisation services, SPICE guest services and USB redirection
   
   # =============================================================================
   # Gaming & Performance
   # =============================================================================
   ./gaming        # Steam platform, Gamescope compositor, and gaming performance optimization
 ];
}

