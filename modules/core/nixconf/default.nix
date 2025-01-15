# modules/core/nixconf/default.nix
# ==============================================================================
# Nix System Configuration
# ==============================================================================
{ config, lib, ... }:
{
  nix.settings = {
    # Core Features
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "kenan"];
    
    # Store Settings
    auto-optimise-store = true;
    keep-outputs = true;
    keep-derivations = true;
    sandbox = true;
    
    # System Features
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
    
    # Binary Caches
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    
    # Trusted Keys
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
