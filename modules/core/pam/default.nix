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
      # Login and Authentication
      login.enableGnomeKeyring = true;
      
      # Screen Lockers
      swaylock.enableGnomeKeyring = true;   # Sway screen locker
      hyprlock.enableGnomeKeyring = true;   # Hyprland screen locker
      
      # System Authentication
      sudo.enableGnomeKeyring = true;       # Sudo operations
      polkit-1.enableGnomeKeyring = true;   # PolicyKit (GNOME privileges)
    };
  };
}

