# modules/home/gnome/default.nix
# ==============================================================================
# MINIMAL GNOME Configuration — only the keyring-lag fix service + HM sd-switch
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  gkrFix = pkgs.writeShellScriptBin "gkr-fix" ''
    #!/usr/bin/env bash
    set -euo pipefail

    BUSCTL=${pkgs.systemd}/bin/busctl
    SYSTEMCTL=${pkgs.systemd}/bin/systemctl
    GKD=${pkgs.gnome-keyring}/bin/gnome-keyring-daemon
    GREP=${pkgs.gnugrep}/bin/grep
    ID=${pkgs.coreutils}/bin/id
    SLEEP=${pkgs.coreutils}/bin/sleep
    SEQ=${pkgs.coreutils}/bin/seq

    # XDG_RUNTIME_DIR garanti olsun
    if [ -z "''${XDG_RUNTIME_DIR:-}" ]; then
      export XDG_RUNTIME_DIR="/run/user/$("''${ID}" -u)"
    fi

    BUS_SOCK="''${XDG_RUNTIME_DIR}/bus"
    if [ ! -S "''${BUS_SOCK}" ]; then
      echo "user bus not found: ''${BUS_SOCK}" >&2
      exit 1
    fi
    export DBUS_SESSION_BUS_ADDRESS="unix:path=''${BUS_SOCK}"

    # Halihazırda owned mı?
    if "''${BUSCTL}" --user list 2>/dev/null | "''${GREP}" -qE '^org\.freedesktop\.secrets[[:space:]]+[0-9]+'; then
      # yine de media-keys'i dürtelim
      "''${SYSTEMCTL}" --user try-restart org.gnome.SettingsDaemon.MediaKeys.service 2>/dev/null || true
      "''${SYSTEMCTL}" --user try-restart org.gnome.SettingsDaemon.media-keys.service 2>/dev/null || true
      exit 0
    fi

    # Daemon’u başlat (fork eder)
    "''${GKD}" --replace --components=secrets,ssh,pkcs11 >/dev/null 2>&1 || true

    # DBus adını alana kadar bekle
    for _ in $("''${SEQ}" 1 200); do
      if "''${BUSCTL}" --user list 2>/dev/null | "''${GREP}" -qE '^org\.freedesktop\.secrets[[:space:]]+[0-9]+'; then
        "''${SYSTEMCTL}" --user try-restart org.gnome.SettingsDaemon.MediaKeys.service 2>/dev/null || true
        "''${SYSTEMCTL}" --user try-restart org.gnome.SettingsDaemon.media-keys.service 2>/dev/null || true
        exit 0
      fi
      "''${SLEEP}" 0.05
    done

    # Debug için son durum
    "''${BUSCTL}" --user list 2>/dev/null | "''${GREP}" -E 'org\.freedesktop\.secrets|org\.gnome\.keyring' || true
    exit 1
  '';
in {
  config = {
    home.packages = [ gkrFix ];

    systemd.user.services.gnome-keyring-ensure = {
      Unit = {
        Description = "Own org.freedesktop.secrets via gnome-keyring (post login)";
        After  = [ "dbus.service" ];
        Wants  = [ "dbus.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        # user D-Bus soketine işaret et
        Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
        ExecStart = "${gkrFix}/bin/gkr-fix";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    systemd.user.startServices = "sd-switch";

    home.activation.gkrEnsure = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.systemd}/bin/systemctl --user daemon-reload
      ${pkgs.systemd}/bin/systemctl --user enable --now gnome-keyring-ensure.service || true
    '';
  };
}
