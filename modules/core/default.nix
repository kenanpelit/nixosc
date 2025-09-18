# modules/core/default.nix
# ==============================================================================
# Core System Configuration (Consolidated Imports)
# ==============================================================================
# PURPOSE:
#   Centralized entry point for all core modules, imported in a consistent order.
#   This file ONLY declares "what comes from where"; actual configuration
#   resides in each module’s own `default.nix`.
#
# SINGLE AUTHORITY PRINCIPLES (very important):
#   - Firewall / Ports        →  modules/core/security   (never define elsewhere)
#   - TCP/IP kernel tuning    →  modules/core/networking (all TCP tuning unified here)
#   - Virtualization / Gaming / Flatpak → modules/core/services (single place)
#   - Users / UIDs / Groups + Home-Manager → modules/core/account
#     (DBus / Keyring stay under `services`, not under `account`)
#
# IMPORT ORDER (based on practical dependencies):
#   1) Identity / Accounts & base system (account, system)
#   2) Nix ecosystem (nix) and base packages (packages)
#   3) Display stack (display) — (Wayland/Hyprland/Fonts/XDG)
#   4) Networking (networking) — (NM/resolved/VPN + TCP sysctl)
#   5) Security (security/sops) — (firewall as single authority)
#   6) Service ecosystem (services) — (flatpak + virt + gaming + core programs)
#
# USAGE GUIDELINES:
#   - To open ports: ONLY inside ./security
#   - To change TCP tuning: ONLY inside ./networking
#   - For Flatpak/Steam/Libvirt/Podman + dconf/zsh/nix-ld: ONLY inside ./services
#   - Home-Manager definitions: ONLY inside ./account (with the user itself)
#
# DEPENDENCIES:
#   - Some modules require `inputs`:
#       • ./display   → needs inputs.hyprland
#       • ./services  → needs inputs.nix-flatpak
#       • ./account   → needs home-manager (requires inputs/username/host)
#     Ensure `specialArgs = { inherit inputs username host; };` is set in flake.
#
# Author: Kenan Pelit
# Last updated: 2025-09-03
# ==============================================================================
{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    # ==========================================================================
    # 1) System Foundation
    # ==========================================================================
    ./account       # Users/UIDs/Groups + Home-Manager (DBus/Keyring in services)
    ./system        # Core system: boot, hardware, thermal, power management

    # ==========================================================================
    # 2) Package Management & Development
    # ==========================================================================
    ./nix           # Nix daemon/GC/optimize, NUR overlay, NH, substituters
    ./packages      # System-wide essential tools and libraries

    # ==========================================================================
    # 3) Desktop Environment & Media
    # ==========================================================================
    ./display       # X11/Wayland/Hyprland, GDM/GNOME, fonts, XDG portals

    # ==========================================================================
    # 4) Network & Connectivity
    # ==========================================================================
    ./networking    # NetworkManager, systemd-resolved, Mullvad/WireGuard, DNS, TCP sysctl

    # ==========================================================================
    # 5) Security & Authentication
    # ==========================================================================
    ./security      # Firewall (SINGLE authority), PAM/Polkit, AppArmor, SSH, hBlock
    ./sops          # Secrets management (sops-nix, key lifecycle)

    # ==========================================================================
    # 6) Services & Applications
    # ==========================================================================
    ./services      # Flatpak (inputs.nix-flatpak), Podman/Libvirt/SPICE, Steam/Gamescope, core programs
  ];
}
