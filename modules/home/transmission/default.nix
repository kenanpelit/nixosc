# modules/home/transmission/default.nix
{ config, pkgs, ... }:
{
  # Transmission ayarları
  home.file.".config/transmission-daemon/settings.json".text = builtins.toJSON {
    download-dir = "${config.home.homeDirectory}/Downloads/transmission";
    incomplete-dir = "${config.home.homeDirectory}/Downloads/transmission/.incomplete";
    incomplete-dir-enabled = true;
    rpc-authentication-required = false;
    rpc-bind-address = "127.0.0.1";
    rpc-enabled = true;
    rpc-port = 9091;
    rpc-url = "/transmission/";
    rpc-username = "";
    rpc-password = "";
    rpc-whitelist = "127.0.0.1";
    rpc-whitelist-enabled = true;
    speed-limit-down = 1000;
    speed-limit-down-enabled = false;
    speed-limit-up = 100;
    speed-limit-up-enabled = false;
    start-added-torrents = true;
    trash-original-torrent-files = false;
    umask = 18;
    watch-dir = "${config.home.homeDirectory}/Downloads/transmission/watch";
    watch-dir-enabled = true;
  };

  # User servisi güncellemesi
  systemd.user.services.transmission = {
    Unit = {
      Description = "Transmission BitTorrent Daemon";
      After = [ "network.target" ];
    };
    Service = {
      Type = "notify";
      ExecStart = "${pkgs.transmission_4}/bin/transmission-daemon -f --log-error";
      ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
