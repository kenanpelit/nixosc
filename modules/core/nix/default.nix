# modules/core/nix/default.nix
# ==============================================================================
# Nix Daemon & Package Management Configuration
# ==============================================================================
#
# Module:      modules/core/nix
# Purpose:     Nix daemon settings, garbage collection, binary caches, overlays
# Author:      Kenan Pelit
# Created:     2025-10-10
# Modified:    2025-10-18
#
# Architecture:
#   Nix Daemon → Build Settings → Binary Cache → GC/Optimize → NH Helper
#        ↓            ↓               ↓              ↓             ↓
#   Permissions   Parallelism    Substituters   Cleanup      Modern CLI
#
# Key Features:
#   ✓ Auto-optimized store (deduplication, hard-linking)
#   ✓ Multi-core parallel builds (max performance)
#   ✓ Binary cache hierarchy (NixOS → Community → Hyprland → Gaming)
#   ✓ Automatic garbage collection (30-day retention)
#   ✓ NH (Nix Helper) integration (modern CLI, safe operations)
#   ✓ Flakes + nix-command enabled
#   ✓ NUR overlay support
#
# Design Principles:
#   • Performance First - Maximize build speed and cache hits
#   • Security by Default - Sandboxed builds, verified caches
#   • Space Efficient - Auto-optimize, smart GC policies
#   • Modern Tooling - NH for better UX and safety
#
# Module Boundaries:
#   ✓ Nix daemon configuration        (THIS MODULE)
#   ✓ Binary cache setup              (THIS MODULE)
#   ✓ Garbage collection policies     (THIS MODULE)
#   ✓ Nixpkgs overlays                (THIS MODULE)
#   ✓ NH (Nix Helper) configuration   (THIS MODULE)
#   ✗ System packages                 (packages module)
#   ✗ User-level Nix config           (home-manager)
#
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:

{
  # ============================================================================
  # Nix Daemon Configuration (Layer 1: Core Build System)
  # ============================================================================
  
  nix = {
    settings = {
      # ========================================================================
      # Access Control (Who Can Use Nix)
      # ========================================================================
      # Grant full Nix access to root and primary user
      # Other users can query but not build/install
      
      allowed-users = [ "${username}" "root" ];  # Can use Nix commands
      trusted-users = [ "${username}" "root" ];  # Can modify daemon settings
      
      # Security Note: trusted-users can bypass sandbox and other restrictions
      # Only grant to administrators you fully trust

      # ========================================================================
      # Build Performance (Parallelism)
      # ========================================================================
      # Maximize build speed by utilizing all available CPU resources
      
      # ---- Max Jobs (Parallel Builds) ----
      # "auto": One job per CPU core (e.g., 8-core = 8 parallel builds)
      # Number: Manual limit (useful for memory-constrained systems)
      max-jobs = "auto";
      
      # ---- Cores per Job ----
      # 0: Use all CPU cores for each build (maximum speed)
      # N: Limit each build to N cores (useful for memory/thermal limits)
      cores = 0;
      
      # Example scenarios:
      # - 8-core CPU with max-jobs="auto" cores=0: 8 builds using 64 total cores
      # - 8-core CPU with max-jobs=4 cores=2: 4 builds using 8 total cores
      # - Memory-limited: max-jobs=2 cores=4 (safer for low RAM)

      # ========================================================================
      # Store Management (Disk & Performance)
      # ========================================================================
      
      # ---- Auto-optimize Store ----
      # Automatically deduplicate identical files using hard links
      # Savings: Often 30-50% disk space reduction
      # Cost: Slight CPU overhead during builds (worth it)
      auto-optimise-store = true;
      
      # Manual optimization: nix-store --optimise
      # Check savings: nix-store --optimise --dry-run
      
      # ---- Garbage Collection Protection ----
      # Prevent GC from deleting certain paths
      keep-outputs     = true;  # Keep build outputs (useful for development)
      keep-derivations = true;  # Keep .drv files (allows rebuild inspection)
      
      # Why keep these?
      # - Faster rebuilds (derivations already available)
      # - Debugging (inspect build process)
      # - Development (modify and rebuild quickly)
      
      # ---- Build Sandboxing ----
      # Isolate builds for reproducibility and security
      # Each build gets private /tmp, /dev, network namespace
      sandbox = true;
      
      # Sandbox limitations:
      # - No network access during build (fetch must be in fixed-output derivation)
      # - No access to /home or other user directories
      # - Build determinism enforced

      # ========================================================================
      # Advanced Build Settings
      # ========================================================================
      
      # ---- Remote Builder Cache Access ----
      # Allow distributed builders to use binary caches
      # Useful for: Build farms, remote build servers
      builders-use-substitutes = true;
      
      # ---- Metadata Sync Behavior ----
      # fsync ensures data is written to disk before continuing
      # false: Faster builds (metadata loss on crash is acceptable)
      # true: Safer (use for critical production systems)
      fsync-metadata = false;
      
      # Risk: Power loss during build might corrupt Nix database
      # Recovery: nix-store --verify --check-contents

      # ========================================================================
      # Security (URI Allowlist)
      # ========================================================================
      # Restrict which URI schemes can be used in fetchers
      # Prevents: Malicious derivations accessing file:// or other protocols
      
      allowed-uris = [
        "github:"      # GitHub repositories
        "gitlab:"      # GitLab repositories  
        "git+https:"   # Git over HTTPS
        "git+ssh:"     # Git over SSH
        "https:"       # Direct HTTPS downloads
      ];
      
      # Common additions:
      # "http:"        # HTTP (less secure, enable if needed)
      # "ftp:"         # FTP (legacy, rarely needed)
      # "file:"        # Local files (dangerous, avoid in production)

      # ========================================================================
      # Binary Cache Configuration (Layer 2: Download Before Build)
      # ========================================================================
      # Binary caches provide pre-built packages (avoid compilation)
      # Cache hierarchy: Check in order, use first match
      
      # ---- Network Settings ----
      # Timeout for cache connections (seconds)
      # Higher value for slow/unstable networks
      connect-timeout = 100;
      
      # ---- Cache Sources (Priority Order) ----
      # Checked sequentially - first match wins
      substituters = [
        "https://cache.nixos.org"           # Official NixOS cache (always first)
        "https://nix-community.cachix.org"  # Community packages (Home Manager, etc.)
        "https://hyprland.cachix.org"       # Hyprland compositor ecosystem
        "https://nix-gaming.cachix.org"     # Gaming packages (Proton, emulators)
      ];
      
      # Cache selection logic:
      # 1. Check cache.nixos.org for package
      # 2. If not found, check nix-community
      # 3. If not found, check hyprland
      # 4. If not found, check nix-gaming
      # 5. If still not found, build from source
      
      # Adding custom caches (example):
      # "https://mycache.cachix.org"        # Your private cache
      
      # ---- Cache Verification Keys ----
      # Public keys for signature verification (MUST match substituters)
      # Order matters: Key N verifies substituter N
      trusted-public-keys = [
        # NixOS official (always trusted)
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        
        # Nix Community (Home Manager, devshells, etc.)
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        
        # Hyprland (Wayland compositor)
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        
        # Gaming (Steam, Proton, emulators)
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
      
      # Security: Nix verifies signatures before using cached builds
      # Unsigned binaries are rejected (prevents cache poisoning)

      # ========================================================================
      # Debugging & Diagnostics
      # ========================================================================
      
      # ---- Build Failure Logging ----
      # Number of log lines to show when build fails
      log-lines = 25;
      
      # View full log: nix log /nix/store/<hash>-package
      
      # ---- Evaluation Traces ----
      # Show detailed stack trace on Nix evaluation errors
      # Helps debug: Infinite recursion, type errors, undefined variables
      show-trace = true;
      
      # Example error with trace:
      # error: undefined variable 'foo'
      #   at /path/to/file.nix:42:5
      #   in call to 'myFunction'
    };

    # ==========================================================================
    # Garbage Collection (Layer 3: Disk Space Management)
    # ==========================================================================
    # Automatic cleanup of old/unused store paths
    # Strategy: Keep recent generations, delete old unused paths
    
    gc = {
      # ---- GC Scheduling ----
      # Disabled when NH clean is enabled (prevents duplicate runs)
      automatic = lib.mkIf (!config.programs.nh.clean.enable) true;
      
      # ---- GC Timing ----
      # Sunday 3 AM: Low system usage, won't interrupt work
      dates = "Sun 03:00";
      
      # ---- Retention Policy ----
      # Delete paths older than 30 days (keeps recent rollbacks)
      # Adjust based on disk space and rollback needs:
      # - 7d: Aggressive (small disk, frequent updates)
      # - 30d: Balanced (default, good for most users)
      # - 90d: Conservative (large disk, prefer safety)
      options = "--delete-older-than 30d";
      
      # Manual GC: nix-collect-garbage -d (delete all old)
      # Dry run: nix-store --gc --print-dead
    };

    # ==========================================================================
    # Store Optimization (Layer 4: Deduplication)
    # ==========================================================================
    # Periodic hard-linking of identical files
    # Reduces disk usage significantly (30-50% savings)
    
    optimise = {
      automatic = true;
      
      # ---- Optimization Schedule ----
      # Daily at 3 AM (after GC if both enabled)
      # Low-priority process, won't impact daytime usage
      dates = [ "03:00" ];
      
      # Process:
      # 1. Scan /nix/store for duplicate files
      # 2. Replace duplicates with hard links
      # 3. Free up disk space (identical content shared)
      
      # Manual optimization: nix-store --optimise
      # Check savings: du -sh /nix/store (before/after)
    };

    # ==========================================================================
    # Experimental Features (Modern Nix)
    # ==========================================================================
    # Enable new Nix CLI and flakes support
    
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    
    # Features enabled:
    # - nix-command: New CLI (nix build, nix run, nix develop)
    # - flakes: Reproducible package definitions with lock files
    
    # Old CLI still works: nix-build, nix-shell, nix-env
    # New CLI preferred: Better UX, more powerful, flake-aware
  };

  # ============================================================================
  # Nixpkgs Configuration (Layer 5: Package Set)
  # ============================================================================
  
  nixpkgs = {
    # ==========================================================================
    # Package Policies
    # ==========================================================================
    
    config = {
      # ---- Unfree Packages ----
      # Allow proprietary software (required for many apps)
      # Examples: Chrome, Spotify, Steam, VS Code, NVIDIA drivers
      allowUnfree = true;
      
      # Security note: Unfree packages may have different licenses
      # Check license before using in commercial settings
      
      # Selective unfree (example, commented):
      # allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      #   "steam"
      #   "spotify"
      #   "discord"
      # ];
    };
    
    # ==========================================================================
    # Overlays (Package Modifications)
    # ==========================================================================
    # Overlays modify or add packages to nixpkgs
    
    overlays = [
      # ---- NUR (Nix User Repository) ----
      # Community-maintained packages not in official nixpkgs
      # Contains: Additional software, themes, scripts, etc.
      inputs.nur.overlays.default
      
      # Add custom overlays here:
      # inputs.hyprland.overlays.default      # Hyprland packages
      # inputs.custom-overlay.overlays.default # Your overlay
      
      # Example custom overlay:
      # (final: prev: {
      #   myPackage = prev.myPackage.overrideAttrs (old: {
      #     version = "custom";
      #   });
      # })
    ];
  };

  # ============================================================================
  # NH (Nix Helper) - Modern CLI (Layer 6: User Experience)
  # ============================================================================
  # NH provides improved UX and safety for common Nix operations
  # Replaces: nixos-rebuild, nix-collect-garbage, nix-store --optimise
  
  programs.nh = {
    enable = true;
    
    # ==========================================================================
    # Automatic Cleanup
    # ==========================================================================
    # NH clean is superior to nix.gc (smarter retention, better UX)
    
    clean = {
      enable = true;
      
      # ---- Retention Policy ----
      # Keep profiles from last 14 days OR minimum 3 profiles
      # Whichever is more: Ensures both time-based and count-based retention
      extraArgs = "--keep-since 14d --keep 3";
      
      # Examples:
      # - 5 profiles in 10 days: Keeps all 5 (within 14d)
      # - 2 profiles in 20 days: Keeps both (minimum 3 not met, but only 2 exist)
      # - 10 profiles in 30 days: Keeps 3 newest (outside 14d, minimum 3)
      
      # Other useful flags:
      # --keep-since 7d --keep 5    # Weekly updates, keep 5 profiles
      # --keep-since 30d --keep 10  # Monthly updates, keep 10 profiles
    };
    
    # ==========================================================================
    # Flake Configuration
    # ==========================================================================
    # Set default flake path for NH commands
    # Allows: `nh os switch` instead of `nh os switch /home/user/.nixosc`
    flake = "/home/${username}/.nixosc";
    
    # NH Commands:
    # - nh os switch       # Rebuild and activate (like nixos-rebuild switch)
    # - nh os boot         # Rebuild for next boot
    # - nh os test         # Temporary activation (like nixos-rebuild test)
    # - nh clean all       # Run cleanup (GC + optimize)
    # - nh search <pkg>    # Search packages (better than nix search)
  };

  # ============================================================================
  # Diagnostic & Management Tools (Layer 7: Utilities)
  # ============================================================================
  # Essential tools for Nix system inspection and debugging
  
  environment.systemPackages = with pkgs; [
    # ---- nix-tree ----
    # Interactive dependency tree visualization
    # Usage: nix-tree /nix/store/<hash>-package
    # Shows: All dependencies in tree format (navigate with arrow keys)
    nix-tree
    
    # Additional useful tools (uncomment as needed):
    
    # ---- nix-diff ----
    # Compare two derivations to see what changed
    # Usage: nix-diff /nix/store/<old> /nix/store/<new>
    # Shows: Attribute differences, dependency changes
    # nix-diff
    
    # ---- nix-du ----
    # Disk usage analyzer for Nix store
    # Usage: nix-du | sort -h
    # Shows: Size of each package and its dependencies
    # nix-du
    
    # ---- nvd (Nix Version Diff) ----
    # Compare NixOS generations to see what changed
    # Usage: nvd diff /nix/var/nix/profiles/system-{42,43}-link
    # Shows: Added/removed/updated packages between generations
    # nvd
    
    # ---- nix-index ----
    # Quickly search which package provides a file
    # Usage: nix-locate bin/hello
    # Shows: Packages containing /bin/hello
    # nix-index
  ];
}

# ==============================================================================
# Usage Guide & Best Practices
# ==============================================================================
#
# Daily Operations:
#   ─────────────────────────────────────────────────────────────────────────
#   # Update system (NH - recommended):
#   $ nh os switch
#   
#   # Update system (classic):
#   $ nixos-rebuild switch --flake ~/.nixosc
#   
#   # Clean old generations:
#   $ nh clean all
#   
#   # Search packages:
#   $ nh search firefox
#
# Maintenance:
#   ─────────────────────────────────────────────────────────────────────────
#   # Check store size:
#   $ du -sh /nix/store
#   
#   # Manual garbage collection:
#   $ nix-collect-garbage -d  # Delete all old generations
#   
#   # Manual optimization:
#   $ nix-store --optimise
#   
#   # Verify store integrity:
#   $ nix-store --verify --check-contents
#
# Troubleshooting:
#   ─────────────────────────────────────────────────────────────────────────
#   # Build failed - check full log:
#   $ nix log /nix/store/<hash>-failed-package
#   
#   # Dependency tree:
#   $ nix-tree /nix/store/<hash>-package
#   
#   # Why is package in store:
#   $ nix-store --query --roots /nix/store/<hash>-package
#   
#   # Compare generations:
#   $ nvd diff /nix/var/nix/profiles/system-{42,43}-link
#
# Performance Tuning:
#   ─────────────────────────────────────────────────────────────────────────
#   # Memory-constrained systems (< 8GB RAM):
#   max-jobs = 2;      # Fewer parallel builds
#   cores = 4;         # Limit cores per build
#   
#   # High-end systems (16+ cores, 32GB+ RAM):
#   max-jobs = "auto"; # Use all cores
#   cores = 0;         # Maximum parallelism
#   
#   # Disk-constrained systems (< 100GB free):
#   gc.options = "--delete-older-than 7d";  # Aggressive cleanup
#
# Binary Cache Management:
#   ─────────────────────────────────────────────────────────────────────────
#   # Add private cache:
#   substituters = [
#     "https://cache.nixos.org"
#     "https://mycache.cachix.org"  # Your cache
#   ];
#   trusted-public-keys = [
#     "cache.nixos.org-1:..."
#     "mycache.cachix.org-1:..."   # Your key
#   ];
#   
#   # Get Cachix key:
#   $ cachix use mycache  # Auto-adds to configuration
#
# ==============================================================================
# Troubleshooting Guide
# ==============================================================================
#
# Issue: Builds are slow
# ─────────────────────────────────────────────────────────────────────────────
# Diagnosis:
#   $ nix show-config | grep "max-jobs\|cores"
#   $ nix build --dry-run <package>  # Shows what will be built
# 
# Solutions:
#   1. Check binary caches: nix store ping --store https://cache.nixos.org
#   2. Increase parallelism: max-jobs = "auto", cores = 0
#   3. Add more caches: Cachix caches for common packages
#   4. Use faster CPU: Build on more powerful machine
#
# Issue: Disk space running out
# ─────────────────────────────────────────────────────────────────────────────
# Diagnosis:
#   $ du -sh /nix/store
#   $ nix-store --gc --print-dead | wc -l  # Count dead paths
# 
# Solutions:
#   1. Run GC: nix-collect-garbage -d
#   2. Optimize store: nix-store --optimise
#   3. Shorten retention: gc.options = "--delete-older-than 7d"
#   4. Remove old profiles: nix-env --delete-generations old
#
# Issue: Build fails with "out of memory"
# ─────────────────────────────────────────────────────────────────────────────
# Diagnosis:
#   $ free -h  # Check available RAM
#   $ dmesg | grep -i "killed process"  # Check for OOM killer
# 
# Solutions:
#   1. Reduce parallelism: max-jobs = 1, cores = 4
#   2. Add swap space: 8GB+ swap recommended
#   3. Build one at a time: nix build --max-jobs 1
#   4. Use remote builder: offload to more powerful machine
#
# Issue: Binary cache not working
# ─────────────────────────────────────────────────────────────────────────────
# Diagnosis:
#   $ nix store ping --store https://cache.nixos.org
#   $ nix build --dry-run <package>  # Shows if using cache
# 
# Solutions:
#   1. Check network: curl https://cache.nixos.org/nix-cache-info
#   2. Verify keys: Match trusted-public-keys with substituters
#   3. Force substitution: nix build --substitute
#   4. Clear cache: rm -rf ~/.cache/nix
#
# Issue: NH commands not working
# ─────────────────────────────────────────────────────────────────────────────
# Diagnosis:
#   $ which nh  # Check if installed
#   $ nh --version
# 
# Solutions:
#   1. Verify enabled: programs.nh.enable = true
#   2. Check flake path: programs.nh.flake = "/home/user/.nixosc"
#   3. Use full path: /run/current-system/sw/bin/nh os switch
#   4. Rebuild: nixos-rebuild switch (installs NH)
#
# ==============================================================================
