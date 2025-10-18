# modules/core/account/default.nix
# ==============================================================================
# User Account Management - Centralized Configuration
# ==============================================================================
#
# Module:      modules/core/account
# Purpose:     Single source of truth for user account, groups, and privileges
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-10-18
#
# Architecture:
#   User Account → Groups → Sudo Config → Home-Manager Integration
#
# Design Principles:
#   1. Single Responsibility - Only user account configuration
#   2. No Service Configuration - Services belong in their own modules
#   3. Clear Boundaries - Explicit ownership mapping
#   4. Security Conscious - Documented trade-offs
#
# Module Boundaries:
#   ✓ User account definition           (THIS MODULE)
#   ✓ Group membership                  (THIS MODULE)
#   ✓ Sudo configuration                (THIS MODULE)
#   ✓ Home-Manager integration          (THIS MODULE)
#   ✗ DBus/Keyring services            (services module)
#   ✗ Display manager                   (display module)
#   ✗ Virtualization services           (virtualization module)
#
# Security Model:
#   • Passwordless sudo for wheel group (convenience vs security trade-off)
#   • No docker group (using rootless Podman - more secure)
#   • Auto-assigned UID (prevents multi-user conflicts)
#   • Full disk encryption recommended (mitigates physical access risks)
#
# ==============================================================================

{ pkgs, lib, username, config, inputs, host, ... }:

{
  # ============================================================================
  # Module Options (Configurable)
  # ============================================================================
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Primary user account name";
    };
    
    description = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "User full name or description";
    };
  };

  config = {
    # ==========================================================================
    # User Account Configuration
    # ==========================================================================
    users.users.${username} = {
      isNormalUser = true;
      description  = config.my.user.description;
      shell        = pkgs.zsh;
      
      # UID Assignment: Auto-managed by NixOS
      # Prevents conflicts in multi-user scenarios
      # uid = 1000;  # Not needed - system assigns automatically
      
      # ------------------------------------------------------------------------
      # Group Membership (Complete & Authoritative List)
      # ------------------------------------------------------------------------
      # CRITICAL: This is the ONLY location for user group definitions
      # Do NOT duplicate group assignments in other modules
      
      extraGroups = [
        # ---- System Administration ----
        "wheel"            # Sudo access (see security.sudo config below)
        "networkmanager"   # Network config without sudo (WiFi, VPN)
        "storage"          # External storage devices (USB, SD cards)
        
        # ---- Hardware Access ----
        "input"            # Input devices (keyboard, mouse, gamepad)
        "audio"            # Audio system (PulseAudio/PipeWire)
        "video"            # GPU access (hardware accel, screen capture)
        
        # ---- Virtualization & Containers ----
        "libvirtd"         # QEMU/KVM management (virt-manager)
        "kvm"              # Hardware virtualization access
        # Note: No "docker" group - using rootless Podman
        # Podman runs without group membership (better security isolation)
        
        # ---- Optional Groups (Uncomment if needed) ----
        # "plugdev"        # USB devices (Android ADB, programmer devices)
        # "dialout"        # Serial ports (Arduino, microcontrollers)
        # "scanner"        # Scanner hardware access
        # "lp"             # Printer access
        # "adbusers"       # Android Debug Bridge
      ];
    };

    # ==========================================================================
    # Sudo Configuration - Passwordless for Wheel Group
    # ==========================================================================
    # Security Trade-off Analysis:
    #   Pros:
    #     • Faster workflow (no password interruptions)
    #     • Better for automation/scripts
    #     • Reduces password fatigue
    #   Cons:
    #     • Physical access = instant root privilege
    #     • No audit trail of sudo usage intent
    #   Mitigations:
    #     • Full disk encryption (LUKS)
    #     • Screen lock on idle
    #     • Physical device security
    #     • User awareness training
    
    security.sudo = {
      # Wheel group members can sudo without password
      wheelNeedsPassword = false;
      
      # Optional: Credential caching timeout (uncomment to enable)
      # After first sudo, credentials cached for X minutes
      # extraConfig = ''
      #   Defaults timestamp_timeout=30
      # '';
    };

    # ==========================================================================
    # Home-Manager Integration
    # ==========================================================================
    # User environment management (dotfiles, packages, services)
    # Defined here because user account and environment are tightly coupled
    
    home-manager = {
      # Use system nixpkgs (ensures version consistency)
      useGlobalPkgs = true;
      
      # Install packages to user profile (isolated from system)
      useUserPackages = true;
      
      # Backup existing files on conflict (prevents data loss)
      backupFileExtension = "backup";
      
      # Pass flake inputs to all home-manager modules
      extraSpecialArgs = { 
        inherit inputs username host; 
      };
      
      # ------------------------------------------------------------------------
      # User Environment
      # ------------------------------------------------------------------------
      users.${username} = {
        # Import user configuration tree
        # Location: modules/home/ (managed separately)
        imports = [ ../../home ];
        
        # Home directory configuration
        home = {
          username      = username;
          homeDirectory = "/home/${username}";
          stateVersion  = "25.11";  # Track home-manager state
        };
        
        # Allow home-manager to self-manage
        programs.home-manager.enable = true;
      };
    };

    # ==========================================================================
    # Module Boundaries - Service Ownership Map
    # ==========================================================================
    # This module does NOT manage the following (explicit exclusions):
    #
    # 1. DBus & Session Services
    #    Location: modules/core/services/default.nix
    #    - services.dbus.enable
    #    - services.dbus.packages = [ gcr gnome-keyring ]
    #
    # 2. GNOME Keyring & PAM
    #    Location: modules/core/services OR display module
    #    - services.gnome.gnome-keyring.enable
    #    - security.pam.services.*.enableGnomeKeyring
    #
    # 3. Display Manager & Desktop
    #    Location: modules/core/display/default.nix
    #    - services.displayManager.*
    #    - services.desktopManager.*
    #
    # 4. Virtualization Runtime
    #    Location: modules/core/virtualization (if exists)
    #    - virtualisation.podman.enable
    #    - virtualisation.docker.enable = false
    #
    # 5. Network Services
    #    Location: modules/core/networking
    #    - networking.networkmanager.enable
    #
    # Why this separation?
    #   ✓ Clean module boundaries (Single Responsibility Principle)
    #   ✓ Easy dependency tracking (no hidden couplings)
    #   ✓ Prevents circular imports (clear hierarchy)
    #   ✓ Maintainable configuration (one module = one concern)
    #   ✓ Reusable modules (can enable/disable independently)
    #
    # ==========================================================================
  };
}

# ==============================================================================
# Usage Examples
# ==============================================================================
#
# Override user description per-host:
#   my.user.description = "Kenan Pelit - Development Workstation";
#
# Add optional groups (in THIS module):
#   extraGroups = [ ... "adbusers" "scanner" ];
#
# Enable sudo password (override security):
#   security.sudo.wheelNeedsPassword = true;
#
# Check user groups:
#   groups ${username}
#   id ${username}
#
# ==============================================================================

