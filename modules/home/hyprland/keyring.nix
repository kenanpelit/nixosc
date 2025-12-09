# modules/home/hyprland/keyring.nix
# ==============================================================================
# Hyprland keyring config: start GNOME Keyring secret service under Hyprland.
# Keep secret-service setup here for Wayland session compatibility.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
in
lib.mkIf cfg.enable {
  # Secret Service - ONLY for Hyprland sessions
  systemd.user.services.gnome-keyring-secrets = {
    Unit = {
      Description = "GNOME Keyring Secret Service - Hyprland Only";
      After  = [ "hyprland-session.target" "dbus.service" ];
      PartOf = [ "hyprland-session.target" ];
      ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
    };
    Service = {
      Type = "simple";
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}
