# modules/home/subliminal/default.nix
# ==============================================================================
# Subliminal Subtitle Downloader Configuration
# ==============================================================================
# This module provides a placeholder for Subliminal configuration.
# The actual configuration is managed via a SOPS-encrypted TOML file.
#
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  home.file.".config/subliminal/.keep".text = "";
}
