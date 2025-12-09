# modules/home/radio/default.nix
# ==============================================================================
# Home Manager module for radio.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
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
