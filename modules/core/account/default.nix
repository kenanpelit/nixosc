# modules/core/account/default.nix
# ==============================================================================
# User Account Management Module
# ==============================================================================
#
# Purpose: Centralized user account, groups, and sudo privilege management
# Module: modules/core/account
# Author: Kenan Pelit
# Date:   2025-09-03
#
# Design Principles:
#   - Single source of truth for user configuration
#   - User-linked home-manager profile defined in same module
#   - System services (DBus/Keyring) belong to services module, not here
#
# Ownership Map:
#   - users.users.*     → THIS MODULE (account)
#   - sudo config       → THIS MODULE (account)
#   - home-manager      → THIS MODULE (account)
#   - DBus/Keyring      → services module
#   - Display services  → display module
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
    
    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID for the primary user account";
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
      description  = username;
      uid          = config.my.user.uid;
      shell        = pkgs.zsh;
      
      # Complete group membership list
      # NOTE: Previously duplicated in services/default.nix - now centralized here
      extraGroups = [
        # System administration
        "wheel"            # sudo privileges
        "networkmanager"   # Network Manager permissions
        "storage"          # Storage device access
        
        # Hardware & I/O access
        "input"            # Input device access
        "audio"            # Audio subsystem
        "video"            # Video/GPU access
        
        # Virtualization & containers
        "libvirtd"         # QEMU/KVM virtualization
        "kvm"              # Direct KVM access
        "docker"           # Docker container management
      ];
    };

    # ==========================================================================
    # Sudo Configuration
    # ==========================================================================
    # Passwordless sudo for wheel group (conscious security trade-off)
    
    security.sudo.wheelNeedsPassword = false;

    # ==========================================================================
    # Home-Manager Integration
    # ==========================================================================
    # User environment management through home-manager.
    # Defined here because user account and user environment are tightly coupled.
    
    home-manager = {
      useUserPackages      = true;   # Install packages to user profile
      useGlobalPkgs        = true;   # Use system-wide nixpkgs instance
      backupFileExtension  = "backup"; # Backup extension for existing files
      
      # Pass these variables to all home-manager modules
      extraSpecialArgs = { 
        inherit inputs username host; 
      };
      
      users.${username} = {
        # Import user environment configuration
        # Path: ./modules/home (relative to repo root)
        imports = [ ../../home ];
        
        # Basic home directory setup
        home = {
          username      = username;
          homeDirectory = "/home/${username}";
          stateVersion  = "25.11";  # Home-manager state version
        };
      };
    };

    # --------------------------------------------------------------------------
    # Service Boundaries
    # --------------------------------------------------------------------------
    # IMPORTANT: The following services are NOT managed here:
    #
    # DBus & Keyring Services → modules/core/services/default.nix
    #   - services.dbus.enable = true;
    #   - services.dbus.packages = [ pkgs.gcr gnome-keyring ];
    #   
    # GNOME Keyring → Can be in either services or display module
    #   - services.gnome.gnome-keyring.enable = true;
    #
    # This separation ensures clean module boundaries and single responsibility.
    # --------------------------------------------------------------------------
  };
}

