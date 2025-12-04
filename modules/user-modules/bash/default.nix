# modules/home/bash/default.nix
# ==============================================================================
# Bash Configuration Root
# Author: Kenan Pelit
# Description: Centralized Bash configuration with modular structure
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.bash;
in
{
  options.my.user.bash = {
    enable = lib.mkEnableOption "Bash shell configuration";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Module Imports (sorted by load priority and dependencies)
    # =============================================================================
    imports = [
      # Core Configuration
      ./bash.nix              # Base Bash settings
      
      # Interactive Shell Features
      # ./bash_unified.nix      # Aliases, functions, and keybindings (where applicable)
      ./bash_profile.nix      # Login shell configuration (.bash_profile)
      
      # Not directly needed for Bash:
      # ./bash_plugins.nix    # Bash generally uses simpler plugin management
    ];
  };
}
