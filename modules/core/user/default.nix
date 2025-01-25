# modules/core/user/default.nix
# ==============================================================================
# User Environment Configuration
# ==============================================================================
# This configuration file manages all user-related settings including:
# - User account configuration
# - System-wide packages
# - Core program settings
# - Home Manager integration
#
# Key components:
# - User account and group management
# - Comprehensive package collection
# - Program defaults and configurations
# - Home environment setup
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./account
    ./home
    ./programs
    ./packages
  ];
}
