# modules/home/gnome/default.nix
# ==============================================================================
# GNOME Keyring (Secrets-only) as a user systemd service for Hyprland/Wayland
# - Starts only the 'secrets' component to avoid SSH/GPG agent conflicts
# - Requires a running user D-Bus (DBUS_SESSION_BUS_ADDRESS=%t/bus)
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  # User systemd servisi: sadece 'secrets' (SSH/GPG ile çakışmaz)
  systemd.user.services.gnome-keyring-secrets = {
    Unit = {
      Description = "GNOME Keyring (Secrets only)";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
      # DÜZELTME: pkgs.gnome.gnome-keyring → pkgs.gnome-keyring
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}


