# modules/core/gaming/default.nix
# ==============================================================================
# Gaming Configuration
# ==============================================================================
# This configuration manages gaming-related settings including:
# - Steam client and Proton compatibility
# - Gamescope compositor for gaming sessions
# - Performance optimization and firewall rules
# - Remote play functionality
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  programs = {
    # Steam Gaming Platform
    steam = {
      enable = true;
      remotePlay.openFirewall = true;      # Enable Remote Play
      dedicatedServer.openFirewall = false; # Disable server ports
      gamescopeSession.enable = true;       # Enable Gamescope session
      extraCompatPackages = [ 
        pkgs.proton-ge-bin                 # Additional Proton versions
      ];
    };

    # Gamescope Gaming Compositor
    gamescope = {
      enable = true;
      capSysNice = true;    # Allow process priority management
      
      # Gamescope startup arguments
      args = [
        "--rt"              # Enable realtime priority
        "--expose-wayland"  # Wayland compositing support
        "--adaptive-sync"   # Variable refresh rate support
        "--immediate-flips" # Reduce input latency
        "--force-grab-cursor" # Better cursor handling
      ];
    };
  };
}

