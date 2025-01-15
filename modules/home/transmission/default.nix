# modules/home/transmission/default.nix
{ config, lib, pkgs, ... }:

let
  settingsDir = ".config/transmission-daemon";
  settingsFormat = pkgs.formats.json {};
  baseSettings = {
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
  settingsFile = settingsFormat.generate "settings.json" baseSettings;
in
{
  config = {
    systemd.user.services.transmission = {
      Unit = {
        Description = "Transmission BitTorrent Daemon";
        After = [ "network.target" ];
      };
      Service = {
        Type = "notify";
        ExecStartPre = [
          (pkgs.writeShellScript "transmission-setup" ''
            mkdir -p ${config.home.homeDirectory}/Downloads/transmission/{complete,incomplete,watch}
            mkdir -p ${config.home.homeDirectory}/${settingsDir}
            
            # Yedekle ve yeni ayarları kopyala
            if [ -f "${config.home.homeDirectory}/${settingsDir}/settings.json" ]; then
              mv "${config.home.homeDirectory}/${settingsDir}/settings.json" \
                 "${config.home.homeDirectory}/${settingsDir}/settings.json.backup"
            fi
            
            install -Dm644 ${settingsFile} "${config.home.homeDirectory}/${settingsDir}/settings.json"
          '')
        ];
        ExecStart = "${pkgs.transmission_4}/bin/transmission-daemon -f --log-level=error";
        ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.packages = with pkgs; [
      transmission_4
    ];
  };
}

