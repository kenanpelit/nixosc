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
 imports = [
   ./xdg-mimes
   ./xdg-portal
 ];
}
