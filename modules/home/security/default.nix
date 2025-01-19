# modules/home/security/default.nix
# ==============================================================================
# Security Configuration
# ==============================================================================
# This module manages security tools including:
#
# Components:
# - Encryption:
#   - GnuPG: OpenPGP implementation
#   - SOPS: Secrets management
# - Password Management:
#   - Password Store: Command line password manager
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


