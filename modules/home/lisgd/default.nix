# modules/home/lisgd/default.nix
# ==============================================================================
# lisgd Gesture Daemon for Hyprland (hypr-workspace-monitor bindings)
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.my.user.lisgd;
in
{
  options.my.user.lisgd = {
    enable = lib.mkEnableOption "lisgd gesture daemon";
  };

  config = lib.mkIf cfg.enable {
    # Ensure binary is available
    home.packages = [ pkgs.lisgd ];

    systemd.user.services.lisgd = {
      Unit = {
        Description = "lisgd - libinput swipe gesture daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        # Gestures mirror the old touchegg setup
        ExecStart = toString (
          lib.concatStringsSep " " [
            "${pkgs.lisgd}/bin/lisgd"
            "-g '3,LEFT,hypr-workspace-monitor -wl'"
            "-g '3,RIGHT,hypr-workspace-monitor -wr'"
            "-g '3,UP,hypr-workspace-monitor -wt'"
            "-g '3,DOWN,hypr-workspace-monitor -mt'"
            "-g '4,LEFT,hypr-workspace-monitor -msf'"
            "-g '4,RIGHT,hypr-workspace-monitor -ms'"
          ]
        );

        Restart = "on-failure";
        RestartSec = "2s";

        Environment = [
          "XDG_RUNTIME_DIR=/run/user/%U"
          "XDG_CURRENT_DESKTOP=Hyprland"
          "XDG_SESSION_TYPE=wayland"
          "PATH=${config.home.profileDirectory}/bin:${
            lib.makeBinPath [
              pkgs.hyprland
              pkgs.jq
              pkgs.coreutils
            ]
          }"
        ];

        PassEnvironment = [
          "WAYLAND_DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "XDG_RUNTIME_DIR"
          "HYPRLAND_SOCKET"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
