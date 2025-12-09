# modules/home/obsidian/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for obsidian.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ lib, config, ... }:
let
  cfg = config.my.user.obsidian;
in
{
  options.my.user.obsidian = {
    enable = lib.mkEnableOption "Obsidian configuration";
  };

  config = lib.mkIf cfg.enable {
  };
}
