# modules/core/gaming/steam/default.nix
# ==============================================================================
# Steam Configuration
# ==============================================================================
# This configuration manages Steam client settings including:
# - Steam client installation
# - Proton compatibility layer
# - Remote play functionality
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;      # Enable Remote Play
    dedicatedServer.openFirewall = false; # Disable server ports
    gamescopeSession.enable = true;       # Enable Gamescope session
    extraCompatPackages = [ 
      pkgs.proton-ge-bin                 # Additional Proton versions
    ];
  };
}
