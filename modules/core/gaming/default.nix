# modules/core/gaming/default.nix
# Steam/Gamescope stack for physical hosts.

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
