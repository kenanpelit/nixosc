# modules/core/gaming/gamescope/default.nix
# ==============================================================================
# Gamescope Configuration
# ==============================================================================
# This configuration manages Gamescope compositor settings including:
# - Process priority management
# - Wayland compositing
# - Performance settings
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  programs.gamescope = {
    enable = true;
    capSysNice = true;    # Process priority management
    args = [
      "--rt"              # Enable realtime priority
      "--expose-wayland"  # Wayland compositing
    ];
  };
}
