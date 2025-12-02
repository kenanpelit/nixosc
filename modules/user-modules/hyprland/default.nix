# modules/home/hyprland/default.nix
# ==============================================================================
# Hyprland Window Manager Configuration Root
# ==============================================================================
{ inputs, ... }:
{
 # =============================================================================
 # Module Imports
 # =============================================================================
 imports = [
   # ---------------------------------------------------------------------------
   # Core Modules
   # ---------------------------------------------------------------------------
   # Base Hyprland home-manager module
   inputs.hyprland.homeManagerModules.default
   
   # ---------------------------------------------------------------------------
   # Basic Configuration
   # ---------------------------------------------------------------------------
   ./hyprland.nix   # Main Hyprland configuration
   ./config.nix     # General settings
   
   # ---------------------------------------------------------------------------
   # Extensions & Components 
   # ---------------------------------------------------------------------------
   ./hyprlock.nix   # Screen locker
   ./hypridle.nix   # Idle management
   ./pyprland.nix   # Python plugins
   ./keyring.nix    # Keyring
 ];
}
