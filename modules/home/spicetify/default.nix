# modules/home/spicetify/default.nix
# ==============================================================================
# Spicetify Spotify Client Configuration
# Customizes Spotify client with Catppuccin theme and extensions
# ==============================================================================
{ pkgs, lib, inputs, ... }:
let
  # Get Spicetify packages for current system
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
    # Theme Configuration - Catppuccin
    # ---------------------------------------------------------------------------
    theme = spicePkgs.themes.catppuccin;
    
    # Catppuccin color scheme options:
    # - "mocha" (dark)
    # - "macchiato" (dark)  
    # - "frappe" (dark)
    # - "latte" (light)
    colorScheme = "mocha";
    
    # ---------------------------------------------------------------------------
    # Extensions Configuration
    # ---------------------------------------------------------------------------
    enabledExtensions = with spicePkgs.extensions; [
      # === Core Functionality ===
      adblock              # Block advertisements
      hidePodcasts         # Hide podcast recommendations  
      shuffle              # Enhanced shuffle functionality
      
      # === UI Enhancements ===
      fullAppDisplay       # Show full app in display
      keyboardShortcut     # Additional keyboard shortcuts
      
      # === Additional Features ===
      bookmark             # Bookmark songs and artists
      copyToClipboard      # Copy song info to clipboard
      history              # Show listening history
      volumePercentage     # Show volume as percentage
      
      # === Quality of Life ===
      skipStats            # Skip explicit/liked songs stats
      trashbin             # Restore deleted playlists
    ];
    
    # ---------------------------------------------------------------------------
    # Custom Apps (Optional)
    # ---------------------------------------------------------------------------
    enabledCustomApps = with spicePkgs.apps; [
      # lyrics-plus        # Enhanced lyrics display
      # marketplace        # Extension marketplace
      # reddit             # Reddit integration
    ];
    
    # ---------------------------------------------------------------------------
    # Advanced Settings
    # ---------------------------------------------------------------------------
    # Custom CSS injection for additional tweaks
    # injectCss = true;
    
    # Custom JavaScript injection
    # injectThemeJs = true;
  };
}

