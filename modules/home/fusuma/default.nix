# modules/home/fusuma/default.nix
# ==============================================================================
# Home module for Fusuma touchpad gestures.
# Installs fusuma and deploys gesture config as user service.
# Tweak gesture mappings here instead of editing config.yml manually.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.fusuma;
in
{
  options.my.user.fusuma = {
    enable = lib.mkEnableOption "Fusuma gesture recognizer";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Service Configuration
    # =============================================================================
    services.fusuma = {
      enable = true;
      package = pkgs.fusuma;
      # =============================================================================
      # Gesture Settings
      # =============================================================================
      settings = {
        # ---------------------------------------------------------------------------
        # Sensitivity Settings
        # ---------------------------------------------------------------------------
        threshold = {
          swipe = 0.7;
          pinch = 0.3;
        };
        # ---------------------------------------------------------------------------
        # Timing Settings
        # ---------------------------------------------------------------------------
        interval = {
          swipe = 0.6;
          pinch = 1.0;
        };
        # ---------------------------------------------------------------------------
        # Gesture Mappings
        # ---------------------------------------------------------------------------
        swipe = {
          "3" = {
            right = {
              command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -tn";
              threshold = 0.6;
            };
            left = {
              command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -tp";
              threshold = 0.6;
            };
            up = {
              command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -wt";
              threshold = 0.6;
            };
            down = {
              command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -mt";
              threshold = 0.6;
            };
          };
          "4" = {
            up.command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -msf";
            down.command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -ms";
            right.command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -wr";
            left.command = "${config.home.profileDirectory}/bin/universal-workspace-monitor -wl";
          };
        };
        pinch = {
          "3" = {
            "in" = { command = "${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 1"; };
            out = { command = "${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 0"; };
          };
        };
      };
    };
  };
}
