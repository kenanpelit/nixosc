# modules/home/gnome/default.nix
# ==============================================================================
# MINIMAL GNOME Configuration - Packages, Themes, Fonts Only
# Settings will be applied via external script
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
{
  config = {
    # GNOME açıldıktan sonra keyring'i sahiplendiren servis (lag fix)
    systemd.user.services.gnome-keyring-ensure = {
      Unit = {
        Description = "Own org.freedesktop.secrets via gnome-keyring (post login)";
        After  = [ "graphical-session.target" "dbus.service" ];
        Wants  = [ "graphical-session.target" "dbus.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --replace --foreground --components=secrets,ssh,pkcs11";
        Restart = "on-failure";
        RestartSec = 1;
      };
      # Hem oturum açıldığında hem de user default.target’ta devreye girsin
      Install.WantedBy = [ "graphical-session.target" "default.target" ];
    };

    # HM switch sırasında user servislerini gerçekten başlat
    systemd.user.startServices = "sd-switch";
  };
}
