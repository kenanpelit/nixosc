# modules/core/desktop/x11/default.nix
# ==============================================================================
# X Server Configuration
# ==============================================================================
# This configuration manages X11 settings including:
# - X Server setup
# - Display manager configuration
# - Input device settings
#
# Author: Kenan Pelit
# ==============================================================================

{ username, ... }:
{
  services = {
    # X Server Settings
    xserver = {
      enable = true;
      # Keyboard Configuration
      xkb = {
        layout = "tr";
        variant = "f";
        options = "ctrl:nocaps";  # Caps Lock as Ctrl
      };
    };

    # Display Manager Settings
    displayManager.autoLogin = {
      enable = true;
      user = "${username}";
    };

    # Input Device Settings
    libinput.enable = true;  # Enable libinput for input devices
  };
}
