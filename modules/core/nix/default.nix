# modules/core/nix/default.nix
# ==============================================================================
# Nix Environment Configuration
# ==============================================================================
# This configuration file manages all Nix-related settings including:
# - Nix package manager configuration
# - NH (Nix Helper) integration
# - Binary cache settings
# - System features and experimental options
#
# Key components:
# - Nix system settings and optimizations
# - NH tool configuration
# - Cache and substituter management
# - User permissions and sandbox settings
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, username, inputs, config, lib, ... }:
{
  # =============================================================================
  # NH (Nix Helper) Configuration
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
  # Nixpkgs Configuration
  # =============================================================================
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [ inputs.nur.overlays.default ];
  };

  # =============================================================================
  # Nix Settings
  # =============================================================================
  nix = {
    settings = {
      # Connection Settings
      connect-timeout = 100;
      
      # System Users
      allowed-users = [ "${username}" ];
      trusted-users = [ "${username}" ];
      
      # Store Configuration
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      sandbox = true;
      
      # Features
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      
      # Cache Configuration
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
    };
    
    # Experimental Features
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}

