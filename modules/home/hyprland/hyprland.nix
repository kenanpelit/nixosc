# modules/home/hyprland/hyprland.nix
# ==============================================================================
# Hyprland main module: enables compositor, sets env vars, integrates plugins,
# and imports detailed configs (binds/layout/services).
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  cfg = config.my.desktop.hyprland;
  clipPersistPkg =
    if builtins.hasAttr "wl-clip-persist" pkgs
    then pkgs."wl-clip-persist"
    else null;
in
lib.mkIf cfg.enable {
  # =============================================================================
  # Required Packages
  # =============================================================================
  # =============================================================================
  # Systemd Integration
  # =============================================================================
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  # Keep session daemons observable/restartable (instead of exec-once).
  systemd.user.services.hypr-nm-applet = {
    Unit = {
      Description = "NetworkManager applet (Hyprland)";
      After = [ "hyprland-session.target" "dbus.service" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.hypr-clipse = {
    Unit = {
      Description = "clipse daemon (hyprland)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.clipse}/bin/clipse -listen";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  systemd.user.services.hypr-clip-persist = lib.mkIf (clipPersistPkg != null) {
    Unit = {
      Description = "wl-clip-persist (hyprland)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${clipPersistPkg}/bin/wl-clip-persist --clipboard both";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };
  
  # Clipboard watcher is not needed if cliphist is disabled; keep service absent.

  # Run hypr-set init at session start to normalize monitors and audio
  systemd.user.services.hypr-init = {
    Unit = {
      Description = "Hyprland session bootstrap (monitors + audio)";
      After = [ "graphical-session.target" "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep 5 && hypr-set init'";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

  # =============================================================================
  # Window Manager Configuration
  # =============================================================================
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      #hidpi = true;
    };
    systemd.enable = true;
  };
}
