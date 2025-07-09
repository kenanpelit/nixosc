# modules/home/system/search/default.nix
{ config, lib, pkgs, ... }:

{
  xdg.configFile."television/nix_channels.toml".text = ''
    [[cable_channel]]
    name = "nixpkgs"
    source_command = "nix-search-tv print"
    preview_command = "nix-search-tv preview {}"
  '';
}

