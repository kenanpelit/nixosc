# modules/core/hblock/default.nix
# ==============================================================================
# hBlock DNS Ad-Blocking
# ==============================================================================
# Configures system-wide ad-blocking updates for user HOSTALIASES.
# - Updates hBlock list periodically
# - Configures per-user HOSTALIASES file
# - Provides shell aliases for manual updates
#
# ==============================================================================

{ pkgs, lib, ... }:

let
  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    for USER_HOME in /home/*; do
      [[ -d "$USER_HOME" ]] || continue
      USER="$(basename "$USER_HOME")"
      USER_UID=$(id -u "$USER" 2>/dev/null || echo 0)
      [[ "$USER_UID" -lt 1000 ]] && continue

      CONFIG_DIR="$USER_HOME/.config/hblock"
      HOSTS_FILE="$CONFIG_DIR/hosts"
      TEMP_FILE="$CONFIG_DIR/hosts.tmp"
      mkdir -p "$CONFIG_DIR"

      {
        echo "# Base entries"
        echo "localhost 127.0.0.1"
        echo "hay 127.0.0.2"
        echo "# hBlock entries (Updated: $(date))"
        ${pkgs.hblock}/bin/hblock -O - 2>/dev/null | while read -r LINE; do
          if [[ $LINE =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.+)$ ]]; then
            dom="''${BASH_REMATCH[2]}"
            echo "''${dom} ''${dom}"
          fi
        done
      } > "$TEMP_FILE"

      mv "$TEMP_FILE" "$HOSTS_FILE" && chown "$USER:users" "$HOSTS_FILE" && chmod 0644 "$HOSTS_FILE" || rm -f "$TEMP_FILE"
    done
  '';
in
{
  systemd.services.hblock-update = {
    description = "hBlock per-user HOSTALIASES updater";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ ]; # started via timer
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${hblockUpdateScript} || true";
    };
  };

  systemd.timers.hblock-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 01:00";
      Persistent = true;
      Unit = "hblock-update.service";
    };
  };

  environment.systemPackages = [ pkgs.hblock ];

  environment.etc."skel/.bashrc".text = lib.mkAfter ''
    # hBlock DNS blocking via HOSTALIASES
    export HOSTALIASES="$HOME/.config/hblock/hosts"
  '';

  environment.shellAliases = {
    hblock-update-now = "sudo ${hblockUpdateScript}";
    hblock-status     = "wc -l ~/.config/hblock/hosts";
    hblock-check      = "head -20 ~/.config/hblock/hosts";
  };
}
