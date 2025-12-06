# modules/home/mpv/default.nix
# ==============================================================================
# MPV Media Player Configuration (direct files, no tar extraction)
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.mpv;

  mpvConf = builtins.readFile ./config/mpv.conf;
  inputConf = builtins.readFile ./config/input.conf;

  # Helper to copy whole script/script-opts folders
  mkConfigDir = path: {
    source = path;
    recursive = true;
  };
in
{
  options.my.user.mpv = {
    enable = lib.mkEnableOption "mpv configuration (no tar blobs; direct files)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mpv ];

    xdg.configFile = {
      "mpv/mpv.conf".text = mpvConf;
      "mpv/input.conf".text = inputConf;
      "mpv/fonts" = mkConfigDir ./config/fonts;
      "mpv/scripts" = mkConfigDir ./config/scripts;
      "mpv/script-opts" = mkConfigDir ./config/script-opts;
      "mpv/script-modules" = mkConfigDir ./config/script-modules;
    };
  };
}
