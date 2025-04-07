# modules/home/browser/default.nix
# ==============================================================================
# Browser Configuration
# ==============================================================================
# This module manages browser configurations including:
#
# Components:
# - Firefox:
# - Zen:
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 imports = [
   ./brave
   ./firefox
   ./zen
   ./chrome
 ];
}
