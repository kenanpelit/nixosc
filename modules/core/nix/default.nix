# modules/core/nix/default.nix
# ==============================================================================
# Nix Daemon & Package Management Configuration
# ==============================================================================
#
# Module: modules/core/nix
# Author: Kenan Pelit
# Date:   2025-09-03
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
      # Store Management
      # --------------------------------------------------------------------------
      
      auto-optimise-store = true;    # Deduplication & store optimization
      keep-outputs       = true;      # Protect outputs from GC
      keep-derivations   = true;      # Protect .drv files from GC
      sandbox            = true;      # Enable build sandboxing for reproducibility

      # --------------------------------------------------------------------------
      # Binary Cache Configuration
      # --------------------------------------------------------------------------
      # Network timeout for slow connections to remote caches
      connect-timeout = 100;

      # Binary cache sources (in priority order)
      substituters = [
        "https://cache.nixos.org"              # Official NixOS cache
        "https://nix-community.cachix.org"     # Community packages
        "https://hyprland.cachix.org"          # Hyprland and related
        "https://nix-gaming.cachix.org"        # Gaming-related packages
      ];

      # Public keys for cache verification (matches substituters order)
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };

    # --------------------------------------------------------------------------
    # Garbage Collection
    # --------------------------------------------------------------------------
    # Automatic GC disabled when NH clean is enabled (prevents double runs)
    
    gc = {
      automatic = lib.mkIf (!config.programs.nh.clean.enable) true;
      dates     = "weekly";
      options   = "--delete-older-than 30d";
    };

    # --------------------------------------------------------------------------
    # Store Optimization
    # --------------------------------------------------------------------------
    # Scheduled deduplication for disk space savings
    
    optimise = {
      automatic = true;
      dates = [ "03:00" ];    # Run at 3 AM to avoid peak usage
    };

    # --------------------------------------------------------------------------
    # Experimental Features
    # --------------------------------------------------------------------------
    # Enable flakes and new CLI commands
    
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # ============================================================================
  # Nixpkgs Configuration
  # ============================================================================
  
  nixpkgs = {
    config = {
      allowUnfree = true;     # Allow proprietary packages (Spotify, Chrome, etc.)
    };
    
    overlays = [
      inputs.nur.overlays.default    # NUR (Nix User Repository) overlay
      # Add custom overlays here as needed
    ];
  };

  # ============================================================================
  # NH (Nix Helper) Configuration
  # ============================================================================
  # Modern CLI for Nix operations with better UX
  
  programs.nh = {
    enable = true;
    
    # Automatic cleanup policy
    clean = {
      enable = true;
      # Keep profiles used in last 7 days, minimum 5 profiles
      extraArgs = "--keep-since 7d --keep 5";
    };
    
    # Set flake root for convenience (enables `nh os switch` etc.)
    flake = "/home/${username}/.nixosc";
  };

  # ============================================================================
  # Diagnostic & Management Tools
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    nix-tree      # Visualize dependency graphs
  ];
}
