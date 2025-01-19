# modules/home/xdg/default.nix
# ==============================================================================
# XDG Configuration
# ==============================================================================
# This module manages XDG specifications including:
#
# Components:
# - XDG Integration:
#   - MIME types: File type associations
#   - Portals: Desktop integration
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

