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
        default = 10;
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
    # Hyprland Bluetooth auto-connect: delayed via timer so it doesn't block session startup.
    systemd.user.services.hyprland-bt-autoconnect = lib.mkIf enableHyprland {
      Unit = {
        Description = "Hyprland Bluetooth auto-connect";
        Wants = [ "pipewire.service" "wireplumber.service" ];
        After = [ "hyprland-session.target" "pipewire.service" "wireplumber.service" ];
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = "${toString cfg.autoToggle.timeoutSeconds}s";
        ExecStart = "${pkgs.bash}/bin/bash -lc '/etc/profiles/per-user/${username}/bin/bluetooth_toggle --connect'";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    systemd.user.timers.hyprland-bt-autoconnect = lib.mkIf enableHyprland {
      Unit = {
        Description = "Hyprland Bluetooth auto-connect (delayed)";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
      };
      Timer = {
        OnActiveSec = "${toString cfg.autoToggle.delaySeconds}s";
        AccuracySec = "5s";
        Unit = "hyprland-bt-autoconnect.service";
      };
      Install = {
        WantedBy = [ "hyprland-session.target" ];
      };
    };
  };
}
