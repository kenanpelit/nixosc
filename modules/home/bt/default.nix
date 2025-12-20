# modules/home/bt/default.nix
# ==============================================================================
# Bluetooth helpers for the user session.
# - Auto-run bluetooth_toggle on compositor session start (Hyprland/Niri).
# - Keep definitions centralized and avoid HM option conflicts when multiple
#   compositor modules are enabled in the same profile.
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  username = config.home.username;
  hasScripts = config.my.user.scripts.enable or false;
  enableHyprland = config.my.desktop.hyprland.enable or false;
  enableNiri = config.my.desktop.niri.enable or false;

  mkAutoToggleService = {
    description,
    wantedBy,
  }: {
    Unit = {
      Description = description;
      After = wantedBy;
      PartOf = wantedBy;
    };
    Service = {
      Type = "oneshot";
      TimeoutStartSec = 30;
      ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep 5 && /etc/profiles/per-user/${username}/bin/bluetooth_toggle'";
    };
    Install = {
      WantedBy = wantedBy;
    };
  };
in
lib.mkIf hasScripts {
  systemd.user.services.bluetooth-auto-toggle-hyprland = lib.mkIf enableHyprland (mkAutoToggleService {
    description = "Auto toggle/connect Bluetooth on login (hyprland)";
    wantedBy = [ "hyprland-session.target" ];
  });

  systemd.user.services.bluetooth-auto-toggle-niri = lib.mkIf enableNiri (mkAutoToggleService {
    description = "Auto toggle/connect Bluetooth on login (niri)";
    wantedBy = [ "niri-session.target" ];
  });
}

