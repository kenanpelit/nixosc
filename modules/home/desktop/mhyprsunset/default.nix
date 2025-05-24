# modules/home/desktop/mhyprsunset/default.nix
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
  # =============================================================================
  # Servis Seçenekleri
  # =============================================================================
  options.services.mhyprsunset = {
    enable = lib.mkEnableOption "Hypr sunset servisi";
  };
  
  # =============================================================================
  # Servis Uygulaması
  # =============================================================================
  config = lib.mkIf cfg.enable {
    systemd.user.services.mhyprsunset = {
      Unit = {
        Description = "HyprSunset renk sıcaklığı yöneticisi";
        After = ["hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };
      Service = {
        Type = "simple";  # forking'den simple'a değiştirildi
        Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
        ExecStart = "/etc/profiles/per-user/${username}/bin/hypr-blue-hyprsunset-manager daemon";  # daemon modu eklendi
        ExecStop = "/etc/profiles/per-user/${username}/bin/hypr-blue-hyprsunset-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";      # Eklendi
        KillSignal = "SIGTERM";  # Eklendi
      };
      Install = {
        WantedBy = ["hyprland-session.target"];
      };
    };
  };
}
