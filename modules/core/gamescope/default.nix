# modules/core/gaming/default.nix
# ==============================================================================
# Gamescope Configuration
# ==============================================================================
# This configuration manages Gamescope compositor settings including:
# - Process priority and performance optimization
# - Wayland compositing support
# - Display and input management
#
# Author: Kenan Pelit
# ==============================================================================
{ ... }:
{
  programs.gamescope = {
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
}
