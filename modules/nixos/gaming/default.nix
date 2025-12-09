# modules/nixos/gaming/default.nix
# ------------------------------------------------------------------------------
# NixOS module for gaming (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

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
