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
  cfg = config.services.hyprsunset;
in
{
  # =============================================================================
  # Service Options
  # =============================================================================
  options.services.hyprsunset = {
    enable = lib.mkEnableOption "Hypr sunset service";
  };

  # =============================================================================
  # Service Implementation
  # =============================================================================
  config = lib.mkIf cfg.enable {  # cfg.enable kullanımı
    systemd.user.services.hyprsunset = {
      Unit = {
        Description = "HyprSunset color temperature manager";
        After = ["hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };

      Service = {
        Type = "forking";
        Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
        ExecStart = "/etc/profiles/per-user/${username}/bin/hypr-blue-hyprsunset-manager start";
        ExecStop = "/etc/profiles/per-user/${username}/bin/hypr-blue-hyprsunset-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = ["hyprland-session.target"];
      };
    };
  };
}
