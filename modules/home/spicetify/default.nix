# modules/home/media/spicetify/default.nix
# ==============================================================================
# Spicetify Spotify Client Configuration
# Customizes Spotify client with themes and extensions
# ==============================================================================
{ pkgs, lib, inputs, ... }:
let
  # Get Spicetify packages for current system
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
 
  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  
  # =============================================================================
  # Spicetify Configuration
  # =============================================================================
  programs.spicetify = {
    enable = true;
    
    # ---------------------------------------------------------------------------
    # Theme Configuration - TokyoNight
    # ---------------------------------------------------------------------------
    theme = {
      name = "TokyoNight";
      src = pkgs.fetchFromGitHub {
        owner = "kenanpelit";
        repo = "Spotify-TokyoNight";
        rev = "d88ca06eaeeb424d19e0d6f7f8e614e4bce962be";
        sha256 = "02aw8kvk4m7radsywpl10gq8x5g23xj5gwspyiawf7mdrazzvf3h";
      };
      injectCss = true;        # Inject custom CSS
      injectThemeJs = true;    # Inject theme's JavaScript
      replaceColors = true;    # Replace Spotify's default colors
      sidebarConfig = true;    # Apply theme to sidebar
      homeConfig = true;       # Apply theme to home page
      overwriteAssets = true;  # Override Spotify's assets
    };
    
    # Color scheme selection
    colorScheme = "storm";
    
    # ---------------------------------------------------------------------------
    # Extensions Configuration
    # ---------------------------------------------------------------------------
    enabledExtensions = with spicePkgs.extensions; [
      adblock       # Block advertisements
      hidePodcasts  # Hide podcast recommendations
      shuffle       # Enhanced shuffle functionality
    ];
  };
}

