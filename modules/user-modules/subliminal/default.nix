# modules/home/subliminal/default.nix
# ==============================================================================
# Subliminal Subtitle Downloader Configuration
# ==============================================================================
# This module provides a placeholder for Subliminal configuration.
# The actual configuration is managed via a SOPS-encrypted TOML file.
#
# ==============================================================================

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
