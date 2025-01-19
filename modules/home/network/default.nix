# modules/home/network/default.nix
# ==============================================================================
# Network Configuration
# ==============================================================================
# This module manages network tools including:
#
# Components:
# - Remote Access:
#   - AnyDesk: Remote desktop client
# - File Transfer:
#   - Rsync: File synchronization
# - Download:
#   - Transmission: Torrent client
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
  imports = builtins.filter
    (x: x != null)
    (map
      (name: if (builtins.match ".*\\.nix" name != null && name != "default.nix")
             then ./${name}
             else if (builtins.pathExists (./. + "/${name}/default.nix"))
             then ./${name}
             else null)
      (builtins.attrNames (builtins.readDir ./.)));
}

