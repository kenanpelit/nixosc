# modules/home/zsh/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for zsh.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.zsh;
in
{
  options.my.user.zsh = {
    enable = lib.mkEnableOption "zsh configuration";
  };

  # Submodules are internally gated; import unconditionally
  imports = [
    # Core Configuration (must load first)
    ./zsh.nix              # Base ZSH settings and environment

    # Data and History (load early for availability)
    #./zsh_history.nix      # History configuration

    # Interactive Shell Features
    ./zsh_unified.nix      # Key bindings, custom shell functions, command aliases and shortcuts
    ./zsh_profile.nix
  ];
}
