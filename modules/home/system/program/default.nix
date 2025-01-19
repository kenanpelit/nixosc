# modules/home/program/default.nix
# ==============================================================================
# Core Programs Configuration
# ==============================================================================
{ pkgs, lib, ... }:
{
  programs = {
    # =============================================================================
    # Terminal Emulators
    # =============================================================================
    wezterm.enable = true;
    kitty.enable = true;

    # =============================================================================
    # Shell Configuration
    # =============================================================================
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
    };

    # =============================================================================
    # Core Utilities
    # =============================================================================
    bat.enable = true;      # Better cat
    fzf.enable = true;      # Fuzzy finder
    htop.enable = true;     # Process viewer
    ripgrep.enable = true;  # Better grep
    tmux.enable = true;     # Terminal multiplexer

    # =============================================================================
    # Git Configuration
    # =============================================================================
    git = {
      enable = true;
      delta.enable = true;  # Better diff viewer
      lfs.enable = true;    # Large file storage
    };
  };

  # =============================================================================
  # Nixpkgs Configuration for Insecure Packages
  # =============================================================================
  nixpkgs.config.permittedInsecurePackages = [
    "electron"
  ];
}

