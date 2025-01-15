# modules/core/security/default.nix
# ==============================================================================
# System Security Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # Core Security Settings
  # =============================================================================
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

  # =============================================================================
  # GNOME Keyring Service
  # =============================================================================
  services.gnome = {
    gnome-keyring.enable = true;  # Secure credential storage
  };
}
