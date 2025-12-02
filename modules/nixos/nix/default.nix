# modules/core/nix/default.nix
# ==============================================================================
# Nix System Configuration
# ==============================================================================
# This module configures the Nix package manager, including:
# - Binary cache settings (substituters and public keys)
# - Garbage collection and store optimization
# - Experimental features (flakes)
# - Nix Helper (nh) integration
#
# ==============================================================================

{ config , lib , pkgs , inputs , cacheSubstituters ? [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://hyprland.cachix.org"
    "https://nix-gaming.cachix.org"
    "https://hyprland-community.cachix.org"
  ]
, cachePublicKeys ? [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
  ]
, ...
}:

let 
  username = config.my.user.name or "kenan";
  flakePath = "/home/${username}/.nixosc";
in {
  nix = {
    settings = {
      allowed-users = [ username "root" ];
      trusted-users = [ username "root" ];
      max-jobs = "auto";
      cores    = 0;

      auto-optimise-store = true;
      keep-outputs        = true;
      keep-derivations    = true;
      sandbox             = true;

      builders-use-substitutes = true;
      fsync-metadata           = false;

      allowed-uris = [
        "github:"
        "gitlab:"
        "git+https:"
        "git+ssh:"
        "https:"
      ];

      connect-timeout = 100;
      substituters        = cacheSubstituters;
      trusted-public-keys = cachePublicKeys;

      log-lines  = 25;
      show-trace = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];
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

  # NH (Nix Helper)
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
