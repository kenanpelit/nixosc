# modules/core/nix/default.nix
# ==============================================================================
# Nix Daemon & Package Management Configuration
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:

let
  flakePath = "/home/${username}/.nixosc";
in
{
  # ============================================================================
  # Nix Daemon Configuration (Layer 1: Core Build System)
  # ============================================================================

  nix = {
    settings = {
      # ------------------------------------------------------------------------
      # Access Control
      # ------------------------------------------------------------------------
      allowed-users = [ username "root" ];
      trusted-users = [ username "root" ];

      # ------------------------------------------------------------------------
      # Build Performance
      # ------------------------------------------------------------------------
      max-jobs = "auto";
      cores    = 0;

      # ------------------------------------------------------------------------
      # Store Management
      # ------------------------------------------------------------------------
      auto-optimise-store = true;
      keep-outputs        = true;
      keep-derivations    = true;
      sandbox             = true;

      builders-use-substitutes = true;
      fsync-metadata           = false;

      # ------------------------------------------------------------------------
      # Security (URI Allowlist)
      # ------------------------------------------------------------------------
      allowed-uris = [
        "github:"
        "gitlab:"
        "git+https:"
        "git+ssh:"
        "https:"
      ];

      # ------------------------------------------------------------------------
      # Binary Caches
      # ------------------------------------------------------------------------
      connect-timeout = 100;

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];

      # ------------------------------------------------------------------------
      # Debugging & Diagnostics
      # ------------------------------------------------------------------------
      log-lines  = 25;
      show-trace = true;

      # ------------------------------------------------------------------------
      # Experimental Features (Modern Nix)
      # ------------------------------------------------------------------------
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Optional: To avoid typing --option warn-dirty=false every time:
      # warn-dirty = false;
    };

    # ==========================================================================
    # Garbage Collection (Layer 3: Disk Space Management)
    # ==========================================================================
    gc = {
      # If NH clean is enabled, don't run Nix GC automatically — avoid double work
      automatic = !config.programs.nh.clean.enable;

      dates   = "Sun 03:00";
      options = "--delete-older-than 30d";
    };

    # ==========================================================================
    # Store Optimization (Layer 4: Deduplication)
    # ==========================================================================
    optimise = {
      automatic = true;
      dates     = [ "03:00" ];
    };
  };

  # ============================================================================
  # Nixpkgs Configuration (Layer 5: Package Set)
  # ============================================================================

  nixpkgs = {
    config = {
      allowUnfree = true;

      # If you want fine-tuning:
      # allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      #   "steam" "spotify" "discord"
      # ];
    };

    overlays = [
      # NUR (Nix User Repository)
      inputs.nur.overlays.default

      # Example custom overlay:
      # (final: prev: {
      #   myPackage = prev.myPackage.overrideAttrs (old: {
      #     version = "custom";
      #   });
      # })
    ];
  };

  # ============================================================================
  # NH (Nix Helper) - Modern CLI (Layer 6: UX)
  # ============================================================================

  programs.nh = {
    enable = true;

    clean = {
      enable   = true;
      extraArgs = "--keep-since 14d --keep 3";
    };

    flake = flakePath;
  };

  # ============================================================================
  # Diagnostic & Management Tools (Layer 7: Utilities)
  # ============================================================================

  environment.systemPackages = with pkgs; [
    nix-tree
    # If you want to enable later:
    # nix-diff
    # nix-du
    # nvd
    # nix-index
  ];
}