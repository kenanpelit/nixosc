# modules/home/hyprland/hyprland.nix
# ==============================================================================
# Hyprland main module: enables compositor, sets env vars, integrates plugins,
# and imports detailed configs (binds/layout/services).
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  cfg = config.my.desktop.hyprland;
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
  
  # Clipboard watcher is not needed if cliphist is disabled; keep service absent.

  # Run hypr-init at session start to normalize monitors and audio
  systemd.user.services.hypr-init = {
    Unit = {
      Description = "Hyprland session bootstrap (monitors + audio)";
      After = [ "graphical-session.target" "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep 5 && hypr-init'";
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
