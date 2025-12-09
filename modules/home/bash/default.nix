# modules/home/bash/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for bash.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.bash;
in
{
  options.my.user.bash = {
    enable = lib.mkEnableOption "Bash shell configuration";
  };

  # Submodules are gated internally; import unconditionally here
  imports = [
    # Core Configuration
    ./bash.nix              # Base Bash settings
    
    # Interactive Shell Features
    # ./bash_unified.nix      # Aliases, functions, and keybindings (where applicable)
    ./bash_profile.nix      # Login shell configuration (.bash_profile)
    
    # Not directly needed for Bash:
    # ./bash_plugins.nix    # Bash generally uses simpler plugin management
  ];
}
