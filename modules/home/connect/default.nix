# modules/home/connect/default.nix
# =============================================================================
# Home-Manager module: KDE Connect (Auto-enabled)
# =============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.connect;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
in
{
  options.my.user.connect = {
    enable = lib.mkEnableOption "KDE Connect";
  };

  config = lib.mkIf cfg.enable {
    # -------------------------------------------------------
    # Packages
    # -------------------------------------------------------
    # KDE Connect core daemon
    # -------------------------------------------------------
    systemd.user.services.kdeconnectd = {
      Unit = {
        Description = "KDE Connect Daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnectd";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # -------------------------------------------------------
    # KDE Connect Indicator (System Tray)
    # -------------------------------------------------------
    systemd.user.services.kdeconnect-indicator = {
      Unit = {
        Description = "KDE Connect Indicator";
        After = [ "graphical-session.target" "kdeconnectd.service" ];
        PartOf = [ "graphical-session.target" ];
        Requires = [ "kdeconnectd.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
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
