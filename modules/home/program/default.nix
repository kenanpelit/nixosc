# modules/home/program/default.nix
# ==============================================================================
# Home module bundling core user programs (base CLI/GUI set).
# Keeps common app enables in one place instead of per-module duplication.
# ==============================================================================

{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.core-programs;
in
{
  options.my.user.core-programs = {
    enable = lib.mkEnableOption "Core programs and utilities";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Service Configuration
    # =============================================================================
    my.user.blue.enable = true;  # Enable unified night light manager (Gammastep + HyprSunset)
    
    programs = {
      # ---------------------------------------------------------------------------
      # Terminal Emulators
      # ---------------------------------------------------------------------------
      wezterm.enable = true;  # Modern GPU-accelerated terminal emulator
      kitty.enable = true;    # Fast, feature-rich, GPU based terminal emulator
      
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
  };
}
