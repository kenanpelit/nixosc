{ config, lib, ... }:

{
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "kenan"];
    auto-optimise-store = true;
    keep-outputs = true;
    keep-derivations = true;
    sandbox = true;
    system-features = ["nixos-test" "benchmark" "big-parallel" "kvm"];
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
