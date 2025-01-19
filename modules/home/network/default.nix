# modules/home/network/default.nix
# ==============================================================================
# Network Configuration
# ==============================================================================
# This module manages network tools including:
#
# Components:
# - Remote Access:
#   - AnyDesk: Remote desktop client
# - File Transfer:
#   - Rsync: File synchronization
# - Download:
#   - Transmission: Torrent client
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 imports = [
   ./anydesk
   ./rsync
   ./transmission
 ];
}
