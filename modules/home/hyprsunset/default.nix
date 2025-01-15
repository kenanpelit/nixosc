# modules/home/hyprsunset/default.nix
# ==============================================================================
# HyprSunset Service Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Service Options
  # =============================================================================
  options.services.hyprsunset = {
    enable = lib.mkEnableOption "Hypr sunset service";
  };

  # =============================================================================
  # Service Implementation
  # =============================================================================
  config = lib.mkIf config.services.hyprsunset.enable {
    systemd.user.services.hyprsunset = {
      # ---------------------------------------------------------------------------
      # Unit Configuration
      # ---------------------------------------------------------------------------
      Unit = {
        Description = "HyprSunset color temperature manager";
        After = ["hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };

      # ---------------------------------------------------------------------------
      # Service Configuration
      # ---------------------------------------------------------------------------
      Service = {
        Type = "forking";
        Environment = "PATH=/etc/profiles/per-user/kenan/bin:$PATH";
        ExecStart = "/etc/profiles/per-user/kenan/bin/hypr-blue-hyprsunset-manager start";
        ExecStop = "/etc/profiles/per-user/kenan/bin/hypr-blue-hyprsunset-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
      };

      # ---------------------------------------------------------------------------
      # Installation Settings
      # ---------------------------------------------------------------------------
      Install = {
        WantedBy = ["hyprland-session.target"];
      };
    };
  };
}
