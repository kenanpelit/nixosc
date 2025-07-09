# modules/core/nh/default.nix
# ==============================================================================
# NH (Nix Helper) Configuration
# ==============================================================================
# This configuration manages NH settings including:
# - NH tool enablement
# - Cleaning policies
# - Flake path configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ username, ... }:
{
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";  # Retention policy
    };
    flake = "/home/${username}/.nixosc";
  };
}
