# modules/home/services/default.nix
{ config, lib, pkgs, username, ... }:
{
  options.services.wpaperd = {
    enable = lib.mkEnableOption "Wpaperd service";
  };

  config = {
    # Ana Servis Yapılandırmaları
    services = {
      wpaperd.enable = true;
    };

    systemd.user.services = {
      # Wpaperd Duvar Kağıdı Servisi
      wpaperd = {
        Unit = {
          Description = "Wallpaper daemon for Wayland";
          After = ["hyprland-session.target"];
          PartOf = ["hyprland-session.target"];
        };
        Service = {
          Type = "simple";
          Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
          ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install = {
          WantedBy = ["hyprland-session.target"];
        };
      };
    };

    # Wpaperd Konfigürasyonu
    xdg.configFile."wpaperd/config.toml".text = ''
      [default]
      path = "/home/${username}/Pictures/wallpapers/others"
      mode = "center"
      duration = "1m"
      sorting = "ascending"
      [any]
      path = "/home/${username}/Pictures/wallpapers/others"
      [eDP-1]
      path = "/home/${username}/Pictures/wallpapers/others"
      apply-shadow = true
      sorting = "ascending"
      transition-time = 1000
      [DP-5]
      path = "/home/${username}/Pictures/wallpapers/others"
      apply-shadow = true
      sorting = "descending"
      transition-time = 1000
    '';
  };
}
