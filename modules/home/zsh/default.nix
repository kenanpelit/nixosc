# modules/home/zsh/default.nix
# ==============================================================================
# ZSH Configuration Root
# Author: Kenan Pelit
# Description: Centralized ZSH configuration with modular structure
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
{
  # =============================================================================
  # Module Imports (sorted by load priority and dependencies)
  # =============================================================================
  imports = [
    # Core Configuration (must load first)
    ./zsh.nix              # Base ZSH settings and environment

    # Data and History (load early for availability)
    #./zsh_history.nix      # History configuration
    ./zsh_completions      # Completion system settings

    # Interactive Shell Features
    ./zsh_keybinds.nix     # Key bindings and input handling
    ./zsh_plugins.nix      # Plugin management and settings
    
    # User Interface and Functionality
    ./zsh_functions.nix    # Custom shell functions
    ./zsh_aliases.nix      # Command aliases and shortcuts
    
    # Application Specific (load last)
    ./zsh_tsm.nix         # Transmission CLI configuration
  ];
}
