# modules/home/services/default.nix
# ==============================================================================
# Kullanıcı Seviyesi Servis ve Uygulama Yapılandırması
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Ana Servis Yapılandırmaları
  # =============================================================================
  services = {
    # Temel Servisler
    blueman-applet.enable = true;              # Bluetooth yönetimi
    network-manager-applet.enable = false;     # Ağ yönetimi
    
    gammastep.enable = true;                   # Ekran renk sıcaklığı
    hyprsunset.enable = true;

  };

  # =============================================================================
  # Systemd Kullanıcı Servisleri
  # =============================================================================
  systemd.user.services = {
    polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "Polkit GNOME Authentication Agent";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = "1s";
      };
    };
  };

  # =============================================================================
  # Gerekli Paketler
  # =============================================================================
  home.packages = with pkgs; [
    # Polkit kimlik doğrulama için gerekli
    polkit_gnome
  ];
}
