# modules/core/program/default.nix
# ==============================================================================
# Core Program Configuration
# ==============================================================================
{ pkgs, lib, ... }: {
  programs = {
    # =============================================================================
    # System Programs
    # =============================================================================
    # Desktop Configuration Database
    dconf.enable = true;

    # Z Shell
    zsh.enable = true;
    
    # Disabled Editors
    vim.enable = false;    # Disable vim as system editor
    nano.enable = false;   # Disable nano as system editor
    
    # =============================================================================
    # Dynamic Linker Configuration
    # =============================================================================
    nix-ld = {
      enable = true;
      libraries = with pkgs; [];  # Additional libraries for dynamic linking
    };
  };
}
