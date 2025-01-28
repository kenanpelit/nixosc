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
 imports = [
   ./git
   ./lazygit
   ./nvim
   #./ollama
 ];
}
