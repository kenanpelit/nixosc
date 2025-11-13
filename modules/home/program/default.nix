# modules/home/program/default.nix
# ==============================================================================
# Core Programs Configuration
# This module configures core system programs and utilities
# ==============================================================================
{ pkgs, lib, ... }:
{
  # =============================================================================
  # Service Configuration
  # =============================================================================
  services.blue.enable = true;  # Enable unified night light manager (Gammastep + HyprSunset)
  
  programs = {
    # ---------------------------------------------------------------------------
    # Terminal Emulators
    # ---------------------------------------------------------------------------
    wezterm.enable = true;  # Modern GPU-accelerated terminal emulator
    kitty.enable = true;    # Fast, feature-rich, GPU based terminal emulator
    
    ## ---------------------------------------------------------------------------
    ## Shell Configuration
    ## ---------------------------------------------------------------------------
    #zsh = {
    #  enable = true;
    #  autosuggestion.enable = true;     # Enable fish-like autosuggestions
    #  enableCompletion = true;          # Enable completion system
    #  syntaxHighlighting.enable = true; # Enable syntax highlighting
    #};
    
    # ---------------------------------------------------------------------------
    # Core Utilities
    # ---------------------------------------------------------------------------
    bat.enable = true;      # Cat clone with syntax highlighting and git integration
    fzf.enable = true;      # Command-line fuzzy finder
    htop.enable = true;     # Interactive process viewer
    ripgrep.enable = true;  # Fast search tool (better grep)
    
    # ---------------------------------------------------------------------------
    # Git Configuration
    # ---------------------------------------------------------------------------
    git = {
      enable = true;
      lfs.enable = true;    # Large File Storage support
      # Delta is now configured separately in git/default.nix
    };
  };
}

