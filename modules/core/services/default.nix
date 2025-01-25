# modules/core/services/default.nix
# ==============================================================================
# System Services Configuration
# ==============================================================================
# This configuration file manages system services including:
# - Core system services and daemons
# - Flatpak application management
# - Security and authorization services
# - Network service configuration
#
# Key components:
# - Base system services (gvfs, fstrim, dbus)
# - Flatpak integration and package management
# - Security and PolicyKit settings
# - Network service port configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./flatpak
    ./base
    ./security
    ./network
  ];
}
