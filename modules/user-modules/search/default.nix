# modules/home/search/default.nix
# ==============================================================================
# Global Search Configuration
# ==============================================================================
# Configures system-wide search utilities and integrations.
# - Integrates with nix-search-tv for Nix package and option search.
#
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  xdg.configFile."television/nix_channels.toml".text = ''
    [[cable_channel]]
    name = "nixpkgs"
    source_command = "nix-search-tv print"
    preview_command = "nix-search-tv preview {}"
  '';
}

