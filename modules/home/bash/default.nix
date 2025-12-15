# modules/home/bash/default.nix
# ==============================================================================
# Home module for Bash shell defaults: rc/profile, aliases, completions.
# Centralizes bash configuration under Home Manager instead of loose dotfiles.
# Edit prompt/options here to keep bash setup consistent per user.
# ==============================================================================

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
