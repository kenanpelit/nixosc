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
  # Nixpkgs Configuration
  # =============================================================================
  nixpkgs = {
    overlays = [ inputs.nur.overlays.default ];
  };
}
