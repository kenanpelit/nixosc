# modules/core/pam/default.nix
# ==============================================================================
# PAM and Core Security Configuration
# ==============================================================================
# This configuration manages core security settings including:
# - PAM service configuration
# - Sudo settings
# - RTKit configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  security = {
    rtkit.enable = true;     # Realtime Kit for audio
    sudo.enable = true;      # Superuser permissions
    
    # PAM Service Configuration
    pam.services = {
      # Screen Locker Integration
      swaylock.enableGnomeKeyring = true;
      hyprlock.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };
  };
}
