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

    device = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Input device path to bind (e.g. `/dev/input/event8`). If null, lisgd
        will auto-detect.
      '';
    };
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
        ExecStart = ''
          ${pkgs.lisgd}/bin/lisgd \
            ${lib.optionalString (cfg.device != null) "--device=${cfg.device}"} \
            -g "3,RL,*,*,R,hypr-workspace-monitor -wl" \
            -g "3,LR,*,*,R,hypr-workspace-monitor -wr" \
            -g "3,DU,*,*,R,hypr-workspace-monitor -wt" \
            -g "3,UD,*,*,R,hypr-workspace-monitor -mt" \
            -g "4,RL,*,*,R,hypr-workspace-monitor -msf" \
            -g "4,LR,*,*,R,hypr-workspace-monitor -ms"
        '';

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
