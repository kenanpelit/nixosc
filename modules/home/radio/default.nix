# modules/home/radio/default.nix
# Bookmark management for radiotray-ng
{ config, lib, pkgs, ... }:

{
  # Copy bookmark file to radiotray-ng config directory
  xdg.configFile."radiotray-ng/bookmarks.json".source = ./bookmarks.json;
}