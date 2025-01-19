# modules/home/system/default.nix
# ==============================================================================
# System Configuration
# ==============================================================================
# This module manages system utilities including:
#
# Components:
# - Monitoring:
#   - Btop: System monitor
#   - Command-not-found: Command suggestions
#   - Fastfetch: System information
# - Scripts:
#   - Custom admin scripts
#   - System management tools
#   - Automation utilities
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

