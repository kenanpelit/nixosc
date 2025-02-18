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
 imports = [
   ./audacious
   ./cava
   ./mpd
   ./mpv
   #./spicetify
   ./radio
 ];
}
