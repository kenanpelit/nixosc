# modules/core/nix/default.nix
# ==============================================================================
# Nix Daemon & Package Management Configuration
# ==============================================================================
#
# Module: modules/core/nix
# Author: Kenan Pelit
# Date:   2025-10-10
#
# Purpose: Centralized Nix daemon, GC, caching, and package management config
#
# Scope:
#   - Nix daemon settings (users, sandboxing, store flags)
#   - Garbage collection & optimization (nh integration)
#   - Experimental features (nix-command + flakes)
#   - Nixpkgs configuration & overlays
#   - Binary caches (substituters & trusted keys)
#   - NH (Nix Helper) configuration
#   - Diagnostic tools
#
# Design Notes:
#   - Cache configuration merged here (no separate cache module needed)
#   - When nh.clean is enabled, nix.gc.automatic disabled to prevent conflicts
#   - All substituters and keys in one place for easier management
#   - Optimized for performance and security while maintaining usability
#
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:

{
  # ============================================================================
  # Nix Daemon & Store Configuration
  # ============================================================================
  
  nix = {
    settings = {
      # --------------------------------------------------------------------------
      # User Access Control
      # --------------------------------------------------------------------------
      # Root and primary user have full Nix access
      
      allowed-users = [ "${username}" "root" ];
      trusted-users = [ "${username}" "root" ];

      # --------------------------------------------------------------------------
      # Build Performance Optimization
      # --------------------------------------------------------------------------
      
      max-jobs = "auto";              # Auto-detect CPU cores for parallel builds
      cores = 0;                      # Use all available cores per job (0 = unlimited)
      
      # --------------------------------------------------------------------------
      # Store Management
      # --------------------------------------------------------------------------
      
      auto-optimise-store = true;     # Automatic deduplication & hard-linking
      keep-outputs        = true;     # Protect build outputs from GC
      keep-derivations    = true;     # Protect .drv files from GC
      sandbox             = true;     # Enable build sandboxing for reproducibility
      
      # --------------------------------------------------------------------------
      # Advanced Build Settings
      # --------------------------------------------------------------------------
      
      builders-use-substitutes = true;  # Allow remote builders to use binary caches
      
      # Faster builds at slight risk (disable fsync for metadata)
      # Set to true for production systems if data integrity is critical
      fsync-metadata = false;
      
      # --------------------------------------------------------------------------
      # Security & Evaluation
      # --------------------------------------------------------------------------
      
      # Allowed URI schemes for fetchers (security)
      allowed-uris = [
        "github:"
        "gitlab:"
        "git+https:"
        "git+ssh:"
        "https:"
      ];

      # --------------------------------------------------------------------------
      # Binary Cache Configuration
      # --------------------------------------------------------------------------
      
      # Network timeout for slow/unstable connections
      connect-timeout = 100;

      # Binary cache sources (in priority order)
      substituters = [
        "https://cache.nixos.org"              # Official NixOS cache (highest priority)
        "https://nix-community.cachix.org"     # Community packages
        "https://hyprland.cachix.org"          # Hyprland compositor & ecosystem
        "https://nix-gaming.cachix.org"        # Gaming-related packages
      ];

      # Public keys for cache verification (must match substituters order)
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
      
      # --------------------------------------------------------------------------
      # Logging & Debugging
      # --------------------------------------------------------------------------
      
      log-lines = 25;                 # Number of log lines to show on build failure
      show-trace = true;              # Show detailed trace on evaluation errors
    };

    # --------------------------------------------------------------------------
    # Garbage Collection
    # --------------------------------------------------------------------------
    # Automatic GC disabled when NH clean is enabled (prevents double runs)
    # Runs every Sunday at 3 AM to minimize disruption
    
    gc = {
      automatic = lib.mkIf (!config.programs.nh.clean.enable) true;
      dates     = "Sun 03:00";        # Sunday 3 AM (weekly maintenance window)
      options   = "--delete-older-than 30d";
    };

    # --------------------------------------------------------------------------
    # Store Optimization
    # --------------------------------------------------------------------------
    # Scheduled deduplication for disk space savings
    # Runs at 3 AM to avoid peak usage hours
    
    optimise = {
      automatic = true;
      dates = [ "03:00" ];            # Daily at 3 AM
    };

    # --------------------------------------------------------------------------
    # Experimental Features
    # --------------------------------------------------------------------------
    # Enable modern Nix features (flakes + new CLI)
    
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # ============================================================================
  # Nixpkgs Configuration
  # ============================================================================
  
  nixpkgs = {
    config = {
      allowUnfree = true;             # Allow proprietary packages (Spotify, Chrome, etc.)
    };
    
    overlays = [
      inputs.nur.overlays.default     # NUR (Nix User Repository) overlay
      # Add custom overlays here as needed:
      # inputs.custom-overlay.overlays.default
    ];
  };

  # ============================================================================
  # NH (Nix Helper) Configuration
  # ============================================================================
  # Modern CLI for Nix operations with improved UX and safety
  
  programs.nh = {
    enable = true;
    
    # Automatic cleanup policy (balanced approach)
    clean = {
      enable = true;
      # Keep profiles from last 14 days, minimum 3 profiles retained
      # This provides 2-week rollback window while keeping disk usage reasonable
      extraArgs = "--keep-since 14d --keep 3";
    };
    
    # Set flake root for convenience (enables `nh os switch` without path)
    flake = "/home/${username}/.nixosc";
  };

  # ============================================================================
  # Diagnostic & Management Tools
  # ============================================================================
  # Essential tools for Nix system maintenance and debugging
  
  environment.systemPackages = with pkgs; [
    nix-tree          # Interactive dependency tree visualization
    # Additional useful tools (uncomment as needed):
    # nix-diff        # Compare derivations
    # nix-du          # Disk usage analyzer for Nix store
    # nvd             # Nix version diff tool
  ];
}

