# modules/home/hyprland/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for hyprland.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ inputs, lib, config, ... }:
let
  cfg = config.my.desktop.hyprland;
in
{
  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
  };

  # Submodules are internally gated; import unconditionally
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
    #./hyprlock.nix   # Screen locker
    ./hypridle.nix   # Idle management
    ./pyprland.nix   # Python plugins
    ./keyring.nix    # Keyring
  ];
}
