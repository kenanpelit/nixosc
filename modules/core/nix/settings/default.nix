# modules/core/nix/settings/default.nix
# ==============================================================================
# Nix Settings Configuration
# ==============================================================================
# This configuration manages core Nix settings including:
# - User permissions
# - Store optimization
# - Garbage collection
# - System features
# - Experimental features
#
# Author: Kenan Pelit
# Last Updated: 2025-05-16
# ==============================================================================
{ config, lib, pkgs, username, ... }:
{
  nix = {
    settings = {
      # System Users
      # Allow specific users to perform Nix operations
      allowed-users = [ "${username}" "root" ];
      # Grant trusted user status for maintenance operations like garbage collection
      trusted-users = [ "${username}" "root" ];
      
      # Store Configuration
      # Enable automatic hard-linking of same-content files
      auto-optimise-store = true;
      # Keep build outputs in the Nix store to prevent rebuilding
      keep-outputs = true;
      # Keep build instructions to improve development experience
      keep-derivations = true;
      # Enable sandboxed builds for better security and reproducibility
      sandbox = true;
      # Maximum number of parallel jobs during builds
      max-jobs = "auto";
      # Parallel builds across cores
      cores = 0;
      
      # Rate-limit download bandwidth to 50 MiB/s to avoid network saturation
      download-speed-rate = "50M";
      
      # Extra experimental features (if supported by your Nix version)
      extra-experimental-features = [
        "ca-derivations"
      ];
      
      # System Features
      system-features = [
        "nixos-test"   # Enable NixOS tests
        "benchmark"    # Allow benchmarking tools
        "big-parallel" # Support highly parallel builds
        "kvm"          # Enable KVM acceleration
      ];
    };
    
    # Garbage Collection
    # Automatically clean up old Nix store items to save disk space
    gc = {
      automatic = lib.mkIf (!config.programs.nh.clean.enable) true;  # Only enable if nh.clean is not enabled
      dates = "weekly";   # Run GC once per week
      options = "--delete-older-than 30d";  # Remove generations older than 30 days
      # Keep last 5 generations irrespective of their age
      persistent = true;
    };
    
    # Storage Optimization
    # Run optimization task once a day to identify and hard-link duplicate files
    optimise = {
      automatic = true;
      dates = [ "03:00" ]; # Run at 3 AM
    };
    
    # Experimental Features
    # Enable commands like 'nix run', 'nix shell', and support for flakes
    # Only set if not already defined in the flake configuration
    extraOptions = lib.mkIf (!config.nix ? extraOptions) ''
      # Enable experimental features
      experimental-features = nix-command flakes
      
      # Allow more time for builds
      timeout = 3600
      
      # Use Nix's fallback to build derivations when not in the binary cache
      fallback = true
      
      # Whether to warn about dirty Git trees when using flakes
      warn-dirty = true
    '';
    
    # Registry configuration for centralized flake management
    # Only apply if not already defined in the flake
    registry = lib.mkIf (!config.nix ? registry) {
      nixpkgs.flake = lib.mkDefault (import ../../../flake/sources.nix).nixpkgs;
    };
    
    # Nix path configuration - only apply if not already set
    nixPath = lib.mkIf (!config.nix ? nixPath) [
      "nixpkgs=${config.nix.registry.nixpkgs.flake}"
      "home-manager=${config.nix.registry.home-manager.flake}"
    ];
  };
  
  # System-wide package environment to include basic Nix utilities
  # Only add these if they're not already included in the flake's systemPackages
  environment.systemPackages = with pkgs; [
    # Nix-specific utilities that help with maintenance
    nix-index
    nix-tree
    nix-diff
  ];
}

