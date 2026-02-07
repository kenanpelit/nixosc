# modules/home/connect/default.nix
# ==============================================================================
# Home module for KDE Connect/GSConnect client utilities.
# Installs/connects per-user components for device sync.
# Manage pairing tools here instead of manual installs.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.connect;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  connectTargets = [
    # Run KDE Connect only inside compositor sessions (avoid GNOME GSConnect port conflicts).
    "hyprland-session.target"
    "niri-session.target"
  ];
in
{
  options.my.user.connect = {
    enable = lib.mkEnableOption "KDE Connect";
  };

  config = lib.mkIf cfg.enable {
    # -------------------------------------------------------
    # Packages
    # -------------------------------------------------------
    # KDE Connect core daemon + Valent (GNOME-native KDE Connect implementation)
    # -------------------------------------------------------
    home.packages = [
      pkgs.kdePackages.kdeconnect-kde
      pkgs.valent
    ];

    # Disable upstream XDG autostart entry so kdeconnectd has a single owner unit.
    xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=KDE Connect
      Hidden=true
      NoDisplay=true
      X-GNOME-Autostart-enabled=false
    '';

    systemd.user.services.kdeconnectd = {
      Unit = {
        Description = "KDE Connect Daemon";
        After = connectTargets;
        PartOf = connectTargets;
      };
      Service = {
        Type = "exec";
        ExitType = "cgroup";
        ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = connectTargets;
      };
    };

    # -------------------------------------------------------
    # KDE Connect Indicator (System Tray)
    # -------------------------------------------------------
    systemd.user.services.kdeconnect-indicator = {
      Unit = {
        Description = "KDE Connect Indicator";
        After = connectTargets ++ [ "kdeconnectd.service" ];
        PartOf = connectTargets;
        Requires = [ "kdeconnectd.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = connectTargets;
      };
    };

    # -------------------------------------------------------
    # Post-activation message
    # -------------------------------------------------------
    home.activation.kdeconnectHint = dag.entryAfter [ "writeBoundary" ] ''
      echo ""
      echo "🔗 KDE Connect auto-enabled!"
      echo "📱 Setup: Install KDE Connect on your phone and pair"
      echo "🔧 Commands: kdeconnect-cli --list-available"
      echo "⚙️  System tray icon available for configuration"
      echo ""
    '';
  };
}
