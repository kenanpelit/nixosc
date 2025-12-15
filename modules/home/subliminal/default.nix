# modules/home/subliminal/default.nix
# ==============================================================================
# Home module for Subliminal subtitle fetcher.
# Installs tool and centralizes subtitle provider config via Home Manager.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.subliminal;
in
{
  options.my.user.subliminal = {
    enable = lib.mkEnableOption "Subliminal subtitle downloader";
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/subliminal/.keep".text = "";
  };
}
