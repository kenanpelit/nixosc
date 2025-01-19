# modules/home/utility/default.nix
# ==============================================================================
# Utility Configuration
# ==============================================================================
# This module manages utility applications including:
#
# Components:
# - CLI Tools:
#   - Bat: Cat clone with syntax highlighting
#   - FZF: Fuzzy finder
# - Clipboard:
#   - CopyQ: Clipboard manager
# - System Tools:
#   - Iwmenu: Network management
#   - Sem/Sesh: Session management
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
