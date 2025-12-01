# modules/core/gaming/default.nix
# ==============================================================================
# Gaming Configuration
# ==============================================================================
# Configures gaming-related software and optimizations for physical hosts.
# - Steam (with Remote Play and Proton GE)
# - Gamescope (Compositor for gaming)
#
# ==============================================================================

{ lib, pkgs, isPhysicalHost ? false, ... }:

{
  programs = {
    steam = lib.mkIf isPhysicalHost {
      enable = true;
      remotePlay.openFirewall      = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamescope = lib.mkIf isPhysicalHost {
      enable    = true;
      capSysNice = true;
      args = [
        "--rt"
        "--expose-wayland"
        "--adaptive-sync"
        "--immediate-flips"
        "--force-grab-cursor"
      ];
    };
  };
}
