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
#   - Sesh: Session management
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 imports = [
   ./bat
   ./candy
   ./copyq
   ./iwmenu
   ./sesh
 ];
}
