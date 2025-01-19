# modules/home/services/default.nix
# ==============================================================================
# Services Configuration
# ==============================================================================
# This module manages system services including:
#
# Components:
# - Input Management:
#   - Fusuma: Multi-touch gestures
#   - Touchegg: Touchscreen gestures
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 imports = [
   ./fusuma
   ./touchegg
 ];
}
