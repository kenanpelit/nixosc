# modules/core/default.nix
# ==============================================================================
# Core System Configuration
# ==============================================================================
# This configuration manages the import of all core system modules including:
# - System core and hardware management
# - Desktop environment and multimedia support
# - Network and security configurations
# - User environment and services
#
# Module Structure:
# 1. System Foundation
#    - system/     → {base, boot, hardware, power}
#    - nix/        → {cache, config, nh, settings}
# 
# 2. User Interface
#    - desktop/    → {fonts, wayland, x11, xdg}
#    - media/      → {audio, bluetooth}
#
# 3. Network & Security
#    - network/    → {base, dns, firewall, powersave, ssh, tcp, vpn, wireless}
#    - security/   → {hblock, keyring, pam}
#
# 4. System Services
#    - services/   → {base, flatpak, network, security}
#    - user/       → {account, home, packages, programs}
#
# 5. Virtualization & Gaming
#    - virtualization/ → {container, podman, spice, vm}
#    - gaming/        → {gamescope, performance, steam}
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    # =============================================================================
    # System Foundation
    # =============================================================================
    ./system         # Core system, boot, hardware, and power management
    ./nix           # Nix package manager and cache configuration
    
    # =============================================================================
    # User Interface
    # =============================================================================
    ./desktop       # Display servers, fonts, and desktop integration
    ./media         # Audio and Bluetooth configuration
    
    # =============================================================================
    # Network & Security
    # =============================================================================
    ./network       # Network stack, VPN, SSH, and wireless
    ./security      # System security, keyring, and PAM
    
    # =============================================================================
    # System Services
    # =============================================================================
    ./services      # System services and Flatpak integration
    ./user          # User accounts and package management
    
    # =============================================================================
    # Virtualization & Gaming
    # =============================================================================
    ./virtualization # Container and VM configuration
    ./gaming         # Steam and gaming performance
  ];
}
