# modules/home/transmission/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./transmission.nix
    ./settings.nix
  ];
}
