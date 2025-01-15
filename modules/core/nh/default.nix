# modules/core/nh/default.nix
# ==============================================================================
# Nix Helper (NH) Configuration
# ==============================================================================
{ pkgs, username, inputs, ... }:
{
  # =============================================================================
  # NH Program Configuration
  # =============================================================================
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";  # Retention policy
    };
    flake = "/home/${username}/.nixosc";
  };

  # =============================================================================
  # Nix Settings Configuration
  # =============================================================================
  nix.settings = {
    # Binary Caches
    substituters = [ 
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
    ];

    # Trusted Public Keys
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];

    # Store Configuration
    auto-optimise-store = true;
    
    # Experimental Features
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # =============================================================================
  # Nixpkgs Configuration
  # =============================================================================
  nixpkgs = {
    overlays = [ inputs.nur.overlays.default ];
    config.allowUnfree = true;
  };
}
