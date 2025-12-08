# modules/home/hyprland/hyprland.nix
# ==============================================================================
# Hyprland Main Configuration
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  cfg = config.my.desktop.hyprland;
  clipseLogPath = "${config.home.homeDirectory}/.local/state/clipse/clipse.log";
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
  
  # Dedicated clipboard history watcher service
  systemd.user.services.cliphist-watcher = {
    Unit = {
      Description = "Cliphist clipboard watcher";
      After = [ "graphical-session.target" "hyprland-session.target" ];
      PartOf = [ "graphical-session.target" "hyprland-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "always";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" "hyprland-session.target" ];
    };
  };

  # Clipse listener as a user service
  systemd.user.services.clipse-listen = {
    Unit = {
      Description = "Clipse listener";
      After = [ "graphical-session.target" "hyprland-session.target" ];
      PartOf = [ "graphical-session.target" "hyprland-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.clipse}/bin/clipse -listen";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" "hyprland-session.target" ];
  };

  # Auto-run bluetooth_toggle shortly after session start
  systemd.user.services.bluetooth-auto-toggle = {
    Unit = {
      Description = "Auto toggle/connect Bluetooth on login";
      After = [ "graphical-session.target" "hyprland-session.target" ];
      PartOf = [ "graphical-session.target" "hyprland-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && /etc/profiles/per-user/${config.home.username}/bin/bluetooth_toggle'";
    };

    Install = {
      WantedBy = [ "graphical-session.target" "hyprland-session.target" ];
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
