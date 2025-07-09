# modules/core/programs/default.nix
# ==============================================================================
# Core Program Configuration
# ==============================================================================
# This configuration manages core program settings including:
# - Desktop configuration database
# - Shell configuration
# - Editor configuration
# - Dynamic linker settings
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  programs = {
    # Desktop Configuration Database
    dconf.enable = true;
    # Z Shell
    zsh.enable = true;

    # Disabled Editors
    vim.enable = false;    # Disable vim as system editor
    nano.enable = false;   # Disable nano as system editor

    # Dynamic Linker Configuration
    nix-ld = {
      enable = true;
      libraries = with pkgs; [];  # Additional libraries for dynamic linking
    };
  };
}
