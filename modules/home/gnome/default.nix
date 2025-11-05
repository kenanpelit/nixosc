# modules/home/gnome/default.nix
# ==============================================================================
# GNOME Keyring (Secrets-only) - User systemd service for Hyprland sessions
# ------------------------------------------------------------------------------
# Why:
# - In GNOME sessions, PAM already starts gnome-keyring (including "secrets").
#   Starting another user-level daemon duplicates the login keyring and can
#   slow the session (log spam: "already registered").
# - In Hyprland sessions, we still want a Secret Service provider for apps
#   (e.g., browsers, password managers) without enabling SSH/GPG components.
#
# What this does:
# - Starts only the "secrets" component
# - Binds to a custom hyprland-session.target so it runs ONLY under Hyprland
# - Uses the user D-Bus (%t/bus) to avoid session bus discovery issues
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  # User systemd service: secrets-only, scoped to Hyprland sessions
  systemd.user.services.gnome-keyring-secrets = {
    Unit = {
      Description = "GNOME Keyring (Secrets only)";
      # Start after Hyprland session is considered up; stop with it
      After  = [ "hyprland-session.target" "dbus.service" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      Type = "simple";
      # Ensure a valid user session bus (no auto-discovery penalties)
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
      ExecStart   = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets";
      Restart     = "on-failure";
      RestartSec  = 2;

      # Note: CAP_IPC_LOCK is not required for the secrets component; omit to
      # keep the service minimal and compatible across setups.
      # AmbientCapabilities = "CAP_IPC_LOCK";
    };

    Install = {
      # Enable only for Hyprland; do NOT use default.target to avoid GNOME
      WantedBy = [ "hyprland-session.target" ];
    };
  };
}


