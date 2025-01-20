# modules/home/desktop/waypaper/random.nix
{ config, lib, pkgs, ... }:

{
  systemd.user.services.random-wallpaper = {
    Unit = {
      Description = "Change wallpaper randomly";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target" "swww-daemon.service"];
      Requires = ["swww-daemon.service"];
    };

    Service = {
      Type = "oneshot";
      Environment = [
        "DISPLAY=:0"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/kenan/bin:${pkgs.swww}/bin"
      ];
      ExecStart = "/etc/profiles/per-user/kenan/bin/random-wallpaper";
    };
  };

  systemd.user.timers.random-wallpaper = {
    Unit = {
      Description = "Timer for random wallpaper change";
    };

    Timer = {
      OnBootSec = "1m";
      OnUnitActiveSec = "3m";
    };

    Install = {
      WantedBy = ["timers.target"];
    };
  };
}
