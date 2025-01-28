# modules/home/media/spicetify/default.nix
# ==============================================================================
# Spicetify Spotify Client Configuration
# ==============================================================================
{ pkgs, lib, inputs, ... }:
let
  # Spicetify paketlerini inputs'ten çeker
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system} or null;
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
  imports = if spicePkgs != null then
    [ inputs.spicetify-nix.homeManagerModules.default ]
  else
    [];

  # =============================================================================
  # Spicetify Settings
  # =============================================================================
  programs.spicetify = lib.mkIf (spicePkgs != null) {
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
      colorScheme = "night";  # night, storm veya day
    };
    enabledExtensions = with spicePkgs.extensions or []; [
      adblock
      hidePodcasts
      shuffle
    ];
  };
}
