# modules/core/gaming/default.nix
# ==============================================================================
# Gaming Configuration
# ==============================================================================
# This configuration file manages gaming-related settings including:
# - Steam platform integration
# - Gamescope compositor
# - Gaming performance optimizations
#
# Key components:
# - Steam client and Proton compatibility layer
# - Gamescope session management
# - Remote play functionality
# - Gaming-specific performance settings
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./steam
    ./gamescope
    ./performance
  ];
}
