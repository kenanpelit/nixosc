# modules/home/fusuma/default.niri.nix
# ==============================================================================
# Fusuma gesture config for Niri sessions.
# Uses niri-workspace-monitor for workspace/navigation shortcuts.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.fusuma;
in
{
  options.my.user.fusuma.enable = lib.mkEnableOption "Fusuma gesture recognizer (Niri profile)";

  config = lib.mkIf cfg.enable {
    services.fusuma = {
      enable = true;
      package = pkgs.fusuma;
      settings = {
        threshold = {
          swipe = 0.7;
          pinch = 0.3;
        };
        interval = {
          swipe = 0.6;
          pinch = 1.0;
        };
        swipe = {
          "3" = {
            right = {
              command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -tn";
              threshold = 0.6;
            };
            left = {
              command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -tp";
              threshold = 0.6;
            };
            up = {
              command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -wt";
              threshold = 0.6;
            };
            down = {
              command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -mt";
              threshold = 0.6;
            };
          };
          "4" = {
            up.command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -msf";
            down.command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -ms";
            right.command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -wr";
            left.command = "${config.home.profileDirectory}/bin/niri-workspace-monitor -wl";
          };
        };
        pinch = {
          "3" = {
            # Niri-specific fullscreen toggle can be wired here later if needed.
            "in" = { command = "true"; };
            out = { command = "true"; };
          };
        };
      };
    };
  };
}
