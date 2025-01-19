# modules/home/media/default.nix
# ==============================================================================
# Media Configuration
# ==============================================================================
# This module manages media applications including:
#
# Components:
# - Audio:
#   - Audacious: Audio player
#   - MPD: Music Player Daemon
#   - Spicetify: Spotify customization
# - Video:
#   - MPV: Media player
# - Visualization:
#   - Cava: Audio visualizer
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
