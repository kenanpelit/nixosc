# modules/home/hyprland/hyprland.nix
# ==============================================================================
# Hyprland main module: enables compositor, sets env vars, integrates plugins,
# and imports detailed configs (binds/layout/services).
# ==============================================================================
{ pkgs, config, lib, ... }:
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

  systemd.user.services.hypr-ready = {
    Unit = {
      Description = "Hyprland ready (IPC/socket)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'for ((i=0;i<200;i++)); do if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then exit 0; fi; sleep 0.05; done; echo \"hypr-ready: timed out waiting for hyprctl\" >&2; exit 1'";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

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

  # Polkit agent (required for auth prompts, e.g. poweroff/reboot from shells).
  systemd.user.services.hyprland-polkit-agent = {
    Unit = {
      Description = "Polkit authentication agent (polkit-gnome)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
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
      After = [ "graphical-session.target" "hyprland-session.target" "hypr-ready.service" ];
      PartOf = [ "hyprland-session.target" ];
      Wants = [ "hypr-ready.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'if [ ${toString cfg.bootstrapDelaySeconds} -gt 0 ]; then sleep ${toString cfg.bootstrapDelaySeconds}; fi; hypr-set init'";
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
    package = cfg.package;
    xwayland = {
      enable = true;
      #hidpi = true;
    };
    systemd.enable = true;
  };
}
