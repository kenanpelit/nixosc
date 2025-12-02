# modules/home/radio/default.nix
# ==============================================================================
# Radio Tray NG Bookmark Configuration
# ==============================================================================
# Manages bookmarks for the Radiotray-NG internet radio player.
# - Copies the bookmarks.json file to the Radiotray-NG configuration directory.
#
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  # Copy bookmark file to radiotray-ng config directory
  xdg.configFile."radiotray-ng/bookmarks.json".source = ./bookmarks.json;
}