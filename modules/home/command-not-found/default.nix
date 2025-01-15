# modules/home/command-not-found.nix
{ pkgs, ... }:
{
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  systemd.user.timers."nix-index-update" = {
    Unit = {
      Description = "Update nix-index database weekly";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services."nix-index-update" = {
    Unit = {
      Description = "Update nix-index database";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix-index}/bin/nix-index";
    };
  };
}
