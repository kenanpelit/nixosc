# modules/home/hyprland/default.nix
# ==============================================================================
# Home module for Hyprland user config: binds, env, plugins, extras.
# Manages compositor settings via Home Manager instead of loose dotfiles.
# ==============================================================================

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
