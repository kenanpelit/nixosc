# modules/home/zsh/default.nix
# ==============================================================================
# ZSH Configuration Root
# Author: Kenan Pelit
# Description: Centralized ZSH configuration with modular structure
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.zsh;
in
{
  options.my.user.zsh = {
    enable = lib.mkEnableOption "zsh configuration";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Module Imports (sorted by load priority and dependencies)
    # =============================================================================
    imports = [
      # Core Configuration (must load first)
      ./zsh.nix              # Base ZSH settings and environment

      # Data and History (load early for availability)
      #./zsh_history.nix      # History configuration

      # Interactive Shell Features
      ./zsh_unified.nix      # Key bindings, custom shell functions, command aliases and shortcuts
      ./zsh_profile.nix
    ];
  };
}
