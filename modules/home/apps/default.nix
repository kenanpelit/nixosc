# modules/home/apps/default.nix
# ==============================================================================
# Apps Configuration
# ==============================================================================
# This module manages application configurations including:
#
# Components:
# - Discord: Chat and communication platform
# - Electron: Cross-platform desktop applications
# - Obsidian: Knowledge management system
# - Youtube-dl: Video downloader tool
# - Zotero: Reference management
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 imports = [
   #./discord
   #./elektron
   ./obsidian
   ./ytdlp
   ./zotfiles
 ];
}

