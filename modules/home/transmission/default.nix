# modules/home/transmission/default.nix
{ config, lib, pkgs, ... }:
{
  config = {
    systemd.user.services.transmission = {
      Unit = {
        Description = "Transmission BitTorrent Daemon";
        After = [ "network.target" ];
      };
      Service = {
        Type = "notify";
        ExecStartPre = pkgs.writeShellScript "transmission-setup" ''
          mkdir -p ${config.home.homeDirectory}/Downloads/transmission/{complete,incomplete,watch}
          mkdir -p ${config.home.homeDirectory}/.config/transmission-daemon
        '';
        ExecStart = "${pkgs.transmission_4}/bin/transmission-daemon -f --log-level=error";
        ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.file.".config/transmission-daemon/settings.json" = {
      text = builtins.toJSON {
        download-dir = "${config.home.homeDirectory}/Downloads/transmission/complete";
        incomplete-dir = "${config.home.homeDirectory}/Downloads/transmission/incomplete";
        incomplete-dir-enabled = true;
        rpc-enabled = true;
        rpc-port = 9091;
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1";
        watch-dir = "${config.home.homeDirectory}/Downloads/transmission/watch";
        watch-dir-enabled = true;
        speed-limit-down = 1000;
        speed-limit-down-enabled = false;
        speed-limit-up = 100;
        speed-limit-up-enabled = false;
        start-added-torrents = true;
        trash-original-torrent-files = false;
        umask = 18;
        rpc-authentication-required = false;
        rpc-username = "";
        rpc-password = "";
      };
      force = true;
    };

    # Transmission paketi ekle
    home.packages = with pkgs; [
      transmission_4
    ];
  };
}
