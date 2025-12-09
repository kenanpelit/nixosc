# modules/home/command-not-found/default.nix
# ==============================================================================
# Home module enabling command-not-found suggestions in the shell.
# Centralizes the hook so shells get helpful package hints uniformly.
# ==============================================================================

{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.command-not-found;
in
{
  options.my.user.command-not-found = {
    enable = lib.mkEnableOption "command-not-found handler";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
