# modules/home/desktop/hyprsunset/default.nix
# ==============================================================================
# HyprSunset Service Configuration
# ==============================================================================
# Manages automatic color temperature adjustment for Hyprland
# Similar to Redshift/Gammastep but specifically for Hyprland
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username, ... }:
let
  cfg = config.services.mhyprsunset;
in
{
  options.services.mhyprsunset = {
    enable = lib.mkEnableOption "Hypr sunset service";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.mhyprsunset = {
      Unit = {
        Description = "HyprSunset color temperature manager";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";  # forking yerine oneshot
        RemainAfterExit = true;
        Environment = [
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
          "XDG_RUNTIME_DIR=%i"
        ];
        ExecStart = "${config.home.profileDirectory}/bin/hypr-blue-hyprsunset-manager start";
        ExecStop = "${config.home.profileDirectory}/bin/hypr-blue-hyprsunset-manager stop";
        Restart = "no";  # oneshot için restart kapalı
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}

