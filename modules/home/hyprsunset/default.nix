# modules/home/sunset/default.nix
{ config, lib, pkgs, ... }:
{
  options.services.hyprsunset = {
    enable = lib.mkEnableOption "Hypr sunset service";
  };

  config = lib.mkIf config.services.hyprsunset.enable {
    systemd.user.services.hyprsunset = {
      Unit = {
        Description = "HyprSunset color temperature manager";
        After = ["hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };

      Service = {
        Type = "forking";
        Environment = "PATH=/etc/profiles/per-user/kenan/bin:$PATH";
        ExecStart = "/etc/profiles/per-user/kenan/bin/hypr-blue-hyprsunset-manager start";
        ExecStop = "/etc/profiles/per-user/kenan/bin/hypr-blue-hyprsunset-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = ["hyprland-session.target"];
      };
    };
  };
}
