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
 imports = [
   ./btop
   ./command-not-found
   ./fastfetch
   ./fzf
   ./gammastep
   ./packages
   ./program
   ./scripts
   ./search
 ];
}
