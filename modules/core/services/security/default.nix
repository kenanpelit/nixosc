# modules/core/services/security/default.nix
# ==============================================================================
# Security Services Configuration
# ==============================================================================
# This configuration manages security-related services including:
# - PolicyKit authorization
# - System-wide security services
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  security.polkit.enable = true;  # PolicyKit authorization manager
}
