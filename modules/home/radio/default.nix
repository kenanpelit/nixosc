# modules/home/radio/default.nix
# ==============================================================================
# Home module for internet radio tools/scripts.
# Installs player helpers and manages user presets via Home Manager.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.radio;
in
{
  options.my.user.radio = {
    enable = lib.mkEnableOption "Radiotray-NG bookmarks";
  };

  config = lib.mkIf cfg.enable {
    # Copy bookmark file to radiotray-ng config directory
    xdg.configFile."radiotray-ng/bookmarks.json".source = ./bookmarks.json;
  };
}
