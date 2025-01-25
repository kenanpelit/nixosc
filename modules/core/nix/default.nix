# modules/core/nix/default.nix
# ==============================================================================
# Nix Environment Configuration
# ==============================================================================
# This configuration file manages all Nix-related settings including:
# - Nix package manager configuration
# - NH (Nix Helper) integration
# - Binary cache settings
# - System features and experimental options
#
# Key components:
# - Nix system settings and optimizations
# - NH tool configuration
# - Cache and substituter management
# - User permissions and sandbox settings
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./nh
    ./cache
    ./config
    ./settings
  ];
}
