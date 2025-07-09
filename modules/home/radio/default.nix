# modules/home/radio/default.nix
# radiotray-ng için bookmark yönetimi
{ config, lib, pkgs, ... }:

{
  # Bookmark dosyasını radiotray-ng config dizinine kopyala
  xdg.configFile."radiotray-ng/bookmarks.json".source = ./bookmarks.json;
}
