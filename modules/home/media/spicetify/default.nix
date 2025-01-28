# modules/home/media/spicetify/default.nix
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
    
    # TokyoNight teması konfigürasyonu
    theme = {
      name = "TokyoNight";
      src = pkgs.fetchFromGitHub {
        owner = "kenanpelit";
        repo = "Spotify-TokyoNight";
        rev = "d88ca06eaeeb424d19e0d6f7f8e614e4bce962be";
        sha256 = "02aw8kvk4m7radsywpl10gq8x5g23xj5gwspyiawf7mdrazzvf3h";
      };
      injectCss = true;
      injectThemeJs = true;
      replaceColors = true;
      sidebarConfig = true;
      homeConfig = true;
      overwriteAssets = true;
    };
    
    colorScheme = "storm";
    
    # En temel eklentiler
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
  };
}
