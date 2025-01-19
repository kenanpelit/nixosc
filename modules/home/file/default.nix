# modules/home/file/default.nix
# ==============================================================================
# File Configuration
# ==============================================================================
# This module manages file management configurations including:
#
# Components:
# - File Managers:
#   - Nemo: Graphical file manager
#   - Yazi: Terminal file manager
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
