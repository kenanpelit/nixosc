# modules/home/command-not-found/default.nix
# ==============================================================================
# Home Manager module for command-not-found.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
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
