# modules/core/security/hblock/default.nix
# hBlock per-user HOSTALIASES updater.

{ pkgs, ... }:

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
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${hblockUpdateScript} || true";
    };
  };
}
