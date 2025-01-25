# modules/core/security/hblock/default.nix
# ==============================================================================
# hBlock Configuration
# ==============================================================================
# This configuration manages domain blocking including:
# - hBlock service setup
# - Hosts file management
# - Update scheduling
#
# Author: Kenan Pelit
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.services.hblock;
  updateScript = pkgs.writeShellScript "hblock-update" ''
    # Update ~/.config/hblock/hosts file for each user
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        mkdir -p "$CONFIG_DIR"
        echo "# Base entries" > "$HOSTS_FILE"
        echo "localhost 127.0.0.1" >> "$HOSTS_FILE"
        echo "hay 127.0.0.2" >> "$HOSTS_FILE"
        echo "# hBlock entries (Updated: $(date))" >> "$HOSTS_FILE"
        ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
          if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
            echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}" >> "$HOSTS_FILE"
          fi
        done
        chown $USER:users "$HOSTS_FILE"
        chmod 644 "$HOSTS_FILE"
      fi
    done
  '';
in
{
  options.services.hblock = {
    enable = lib.mkEnableOption "hBlock service";
  };

  config = {
    environment = {
      # Shell Configuration
      etc."skel/.bashrc".text = lib.mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';
      # System Packages
      systemPackages = with pkgs; [ 
        hblock
      ];
    };

    systemd = lib.mkIf cfg.enable {
      services.hblock = {
        description = "hBlock - Update user hosts files";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = updateScript;
          RemainAfterExit = true;
        };
      };
      timers.hblock = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = 3600;
          Persistent = true;
        };
      };
    };
  };
}
