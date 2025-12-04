# modules/home/hyprland/default.nix
# ==============================================================================
# Hyprland Window Manager Configuration Root
# ==============================================================================
{ inputs, lib, config, ... }:
let
  cfg = config.my.desktop.hyprland;
in
{
  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
  };

  # Import Hyprland submodules only when enabled
  imports = lib.optionals cfg.enable [
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
