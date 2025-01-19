# modules/home/development/default.nix
# ==============================================================================
# Development Configuration
# ==============================================================================
# This module manages development tool configurations including:
#
# Components:
# - Version Control:
#   - Git: Source control management
#   - Lazygit: Terminal UI for git
# - Editors:
#   - Neovim: Terminal-based editor
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
