# modules/nixos/gaming/default.nix
# ==============================================================================
# NixOS gaming stack: Steam/gamemode/gamescope toggles and drivers.
# Centralize gaming-related services and performance settings per host.
# Adjust here to keep play environment consistent across machines.
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  isPhysicalHost = config.my.host.isPhysicalHost;
in
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
