# modules/home/terminal/default.nix
# ==============================================================================
# Terminal Configuration
# ==============================================================================
# This module manages terminal environment including:
#
# Components:
# - Terminal Emulators:
#   - Foot: Fast and minimal Wayland terminal
#   - Kitty: GPU-accelerated feature-rich terminal
#   - Wezterm: Cross-platform terminal with extensive features
#
# - Shell Environment:
#   - Zsh: Modern shell with advanced features
#     * Completions and plugins
#     * Custom aliases and functions
#     * History management
#     * Key bindings
#
# - Terminal Multiplexer:
#   - Tmux: Session management and window handling
#
# - Shell Theme:
#   - Powerlevel10k (p10k): Fast and customizable prompt
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  imports = [
    #./foot
    ./kitty
    ./p10k
    ./tmux
    ./wezterm
    ./zsh
  ];
}
