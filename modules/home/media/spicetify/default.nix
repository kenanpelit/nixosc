# modules/home/media/spicetify/default.nix
# ==============================================================================
# Spicetify Spotify Client Configuration
# ==============================================================================
{ config, pkgs, lib, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
in
{
  # =============================================================================
  # Package Configuration
  # =============================================================================
  nixpkgs.config.allowUnfreePredicate = pkg: 
    builtins.elem (lib.getName pkg) [ "spotify" ];

  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];  # fixed here

  # =============================================================================
  # Spicetify Settings
  # =============================================================================
  programs.spicetify = {
    enable = true;
    theme = {
      name = "TokyoNight";
      src = pkgs.fetchFromGitHub {
        owner = "kenanpelit";
        repo = "Spotify-TokyoNight";
        rev = "d88ca06eaeeb424d19e0d6f7f8e614e4bce962be";
        sha256 = "02aw8kvk4m7radsywpl10gq8x5g23xj5gwspyiawf7mdrazzvf3h";
      };
      injectCss = true;
      replaceColors = true;
      overwriteAssets = true;
      colorScheme = "night";
    };
    enabledExtensions = [
      "adblock.js"
      "hidePodcasts.js"
      "shuffle.js"
    ];
  };
}
