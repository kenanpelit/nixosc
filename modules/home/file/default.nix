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
 imports = [
   ./nemo
   ./yazi
 ];
}
