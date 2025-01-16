# modules/home/spicetify/default.nix
# ==============================================================================
# Spicetify Spotify Client Configuration
# ==============================================================================
{ pkgs, lib, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  # =============================================================================
  # Package Configuration
  # =============================================================================
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "spotify" ];
  
  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  # =============================================================================
  # Spicetify Settings
  # =============================================================================
  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
    theme = spicePkgs.themes.dribbblish;
    colorScheme = "catppuccin-mocha";
  };
}
