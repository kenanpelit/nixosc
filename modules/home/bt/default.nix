# modules/home/bt/default.nix
# ==============================================================================
# Bluetooth helpers for the user session.
# - Auto-run bluetooth_toggle on compositor session start (Hyprland/Niri).
# - Keep definitions centralized and avoid HM option conflicts when multiple
#   compositor modules are enabled in the same profile.
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  cfg = config.my.user.bt;
  username = config.home.username;
  hasScripts = config.my.user.scripts.enable or false;
  enableHyprland = config.my.desktop.hyprland.enable or false;
  enableNiri = config.my.desktop.niri.enable or false;
  delaySeconds = cfg.autoToggle.delaySeconds;
  timeoutSeconds = cfg.autoToggle.timeoutSeconds;

  mkAutoToggleService = {
    description,
    wantedBy,
  }: {
    Unit = {
      Description = description;
      After = wantedBy ++ [
        "pipewire.service"
        "wireplumber.service"
      ];
      PartOf = wantedBy;
    };
    Service = {
      Type = "oneshot";
      TimeoutStartSec = "${toString timeoutSeconds}s";
      ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep ${toString delaySeconds} && /etc/profiles/per-user/${username}/bin/bluetooth_toggle --connect'";
    };
    Install = {
      WantedBy = wantedBy;
    };
  };
in
{
  options.my.user.bt = {
    enable = lib.mkEnableOption "Bluetooth helpers (auto toggle/connect on login)";

    autoToggle = {
      delaySeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 20;
        description = "Delay (in seconds) before running bluetooth_toggle at session start.";
      };

      timeoutSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 180;
        description = "Systemd start timeout (in seconds) for bluetooth auto-toggle units.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && hasScripts) {
    systemd.user.services.bluetooth-auto-toggle-hyprland = lib.mkIf enableHyprland (mkAutoToggleService {
      description = "Auto toggle/connect Bluetooth on login (hyprland)";
      wantedBy = [ "hyprland-session.target" ];
    });

    systemd.user.services.bluetooth-auto-toggle-niri = lib.mkIf enableNiri (mkAutoToggleService {
      description = "Auto toggle/connect Bluetooth on login (niri)";
      wantedBy = [ "niri-session.target" ];
    });
  };
}
