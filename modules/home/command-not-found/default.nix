# modules/home/command-not-found.nix
# ==============================================================================
# Command Not Found Handler Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # Nix-Index Configuration
  # =============================================================================
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # =============================================================================
  # Automated Update Timer
  # =============================================================================
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

  # =============================================================================
  # Update Service Configuration
  # =============================================================================
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
