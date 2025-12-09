# modules/home/subliminal/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for subliminal.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.subliminal;
in
{
  options.my.user.subliminal = {
    enable = lib.mkEnableOption "Subliminal subtitle downloader";
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/subliminal/.keep".text = "";
  };
}
