# modules/home/transmission/default.nix
# ==============================================================================
# Transmission BitTorrent Client Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  settingsDir = ".config/transmission-daemon";
  settingsFormat = pkgs.formats.json {};

  # =============================================================================
  # Base Configuration Settings
  # =============================================================================
  baseSettings = {
    # Directory Settings
    download-dir = "${config.home.homeDirectory}/.tor/transmission/complete";
    incomplete-dir = "${config.home.homeDirectory}/.tor/transmission/incomplete";
    incomplete-dir-enabled = true;
    watch-dir = "${config.home.homeDirectory}/.tor/transmission/watch";
    watch-dir-enabled = true;

    # RPC Settings
    rpc-enabled = true;
    rpc-port = 9091;
    rpc-whitelist-enabled = true;
    rpc-whitelist = "127.0.0.1";
    rpc-authentication-required = false;
    rpc-username = "";
    rpc-password = "";

    # Speed Settings
    speed-limit-down = 1000;
    speed-limit-down-enabled = false;
    speed-limit-up = 100;
    speed-limit-up-enabled = false;

    # Behavior Settings
    start-added-torrents = true;
    trash-original-torrent-files = false;
    umask = 18;
  };

  settingsFile = settingsFormat.generate "settings.json" baseSettings;
in
{
  config = {
    # =============================================================================
    # Systemd Service Configuration
    # =============================================================================
    systemd.user.services.transmission = {
      Unit = {
        Description = "Transmission BitTorrent Daemon";
        After = [ "network.target" ];
      };

      Service = {
        Type = "notify";
        ExecStartPre = [
          (pkgs.writeShellScript "transmission-setup" ''
            # Create necessary directories
            mkdir -p ${config.home.homeDirectory}/.tor/transmission/{complete,incomplete,watch}
            mkdir -p ${config.home.homeDirectory}/${settingsDir}
            
            # Backup and copy new settings
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

    # =============================================================================
    # Package Installation
    # =============================================================================
    home.packages = with pkgs; [
      transmission_4
    ];
  };
}
