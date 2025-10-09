# modules/core/account/default.nix
# ==============================================================================
# User Account Management Module
# ==============================================================================
#
# Purpose: Centralized user account, groups, and sudo privilege management
# Module: modules/core/account
# Author: Kenan Pelit
# Date:   2025-10-09
#
# Design Principles:
#   - Single source of truth for user configuration
#   - User-linked home-manager profile defined in same module
#   - System services (DBus/Keyring) belong to services module, not here
#   - Rootless containers (Podman) - no docker group needed
#
# Ownership Map:
#   - users.users.*     → THIS MODULE (account)
#   - sudo config       → THIS MODULE (account)
#   - home-manager      → THIS MODULE (account)
#   - DBus/Keyring      → services module
#   - Display services  → display module
#
# Security Notes:
#   - Passwordless sudo: Conscious trade-off for convenience
#   - No docker group: Using rootless Podman instead (more secure)
#   - UID auto-assigned: Prevents conflicts in multi-user scenarios
#
# ==============================================================================

{ pkgs, lib, username, config, inputs, host, ... }:

{
  # ============================================================================
  # Module Options
  # ============================================================================
  # Configurable options for user account management.
  # These can be overridden per-host if needed.
  
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "The primary user account name";
    };
    
    description = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Full name or description for the user";
    };
  };

  config = {
    # ==========================================================================
    # User Account Configuration
    # ==========================================================================
    # Primary user account definition with all necessary groups.
    # This is the SINGLE authority for user groups - no duplication elsewhere.
    
    users.users.${username} = {
      isNormalUser = true;
      description  = config.my.user.description;
      shell        = pkgs.zsh;
      
      # Let NixOS assign UID automatically (prevents conflicts)
      # uid = 1000;  # Not needed - NixOS handles this
      
      # --------------------------------------------------------------------------
      # Group Membership (Complete List)
      # --------------------------------------------------------------------------
      # IMPORTANT: This is the ONLY place where user groups are defined.
      # Do NOT add groups in other modules (networking, services, etc.)
      
      extraGroups = [
        # ---- System Administration ----
        "wheel"            # Sudo privileges (passwordless via config below)
        "networkmanager"   # Network configuration without sudo
        "storage"          # Access to storage devices
        
        # ---- Hardware & I/O Access ----
        "input"            # Input devices (keyboards, mice, gamepads)
        "audio"            # Audio subsystem (PulseAudio/PipeWire)
        "video"            # GPU access (for hardware acceleration)
        
        # ---- Virtualization ----
        "libvirtd"         # QEMU/KVM virtual machine management
        "kvm"              # Direct KVM access (hardware virtualization)
        
        # ---- Containers ----
        # Note: No "docker" group - using rootless Podman instead
        # Podman doesn't require group membership (more secure)
        
        # ---- Optional Groups (uncomment if needed) ----
        # "plugdev"        # USB device access (Android ADB, etc.)
        # "dialout"        # Serial port access (Arduino, etc.)
        # "scanner"        # Scanner device access
        # "lp"             # Printer access
        # "adbusers"       # Android Debug Bridge
      ];
    };

    # ==========================================================================
    # Sudo Configuration
    # ==========================================================================
    # Passwordless sudo for wheel group members
    # 
    # Security Trade-off:
    #   - Pro: Convenience, faster workflow
    #   - Con: Physical access = instant root
    #   - Mitigation: Full disk encryption, screen lock, physical security
    
    security.sudo = {
      wheelNeedsPassword = false;
      
      # Optional: Add timeout for sudo credential caching
      # extraConfig = ''
      #   Defaults timestamp_timeout=30
      # '';
    };

    # ==========================================================================
    # Home-Manager Integration
    # ==========================================================================
    # User environment management through home-manager.
    # Defined here because user account and user environment are tightly coupled.
    
    home-manager = {
      # Use system-wide nixpkgs instance (consistency)
      useGlobalPkgs = true;
      
      # Install packages to user profile (not system profile)
      useUserPackages = true;
      
      # Backup existing files when home-manager conflicts
      backupFileExtension = "backup";
      
      # Pass these variables to all home-manager modules
      extraSpecialArgs = { 
        inherit inputs username host; 
      };
      
      # --------------------------------------------------------------------------
      # User Environment Configuration
      # --------------------------------------------------------------------------
      users.${username} = {
        # Import user environment configuration
        # Path: modules/home (relative to flake root)
        imports = [ ../../home ];
        
        # Basic home directory setup
        home = {
          username      = username;
          homeDirectory = "/home/${username}";
          
          # Home-manager state version
          stateVersion  = "25.11";
        };
        
        # Enable home-manager to manage itself
        programs.home-manager.enable = true;
      };
    };

    # --------------------------------------------------------------------------
    # Module Boundaries & Service Ownership
    # --------------------------------------------------------------------------
    # IMPORTANT: The following services are NOT managed here:
    #
    # 1. DBus & Related Services → modules/core/services/default.nix
    #    - services.dbus.enable = true;
    #    - services.dbus.packages = [ pkgs.gcr pkgs.gnome-keyring ];
    #
    # 2. GNOME Keyring → modules/core/services or display module
    #    - services.gnome.gnome-keyring.enable = true;
    #    - security.pam.services.*.enableGnomeKeyring = true;
    #
    # 3. Display Manager → modules/core/display/default.nix
    #    - services.xserver.displayManager.*
    #    - services.displayManager.*
    #
    # 4. Container Runtime → modules/core/virtualization (if exists)
    #    - virtualisation.podman.enable = true;
    #    - virtualisation.docker.enable = false;  # Not using Docker
    #
    # This separation ensures:
    #   - Clean module boundaries
    #   - Single responsibility principle
    #   - Easy to reason about dependencies
    #   - No circular imports
    # --------------------------------------------------------------------------
  };
}

