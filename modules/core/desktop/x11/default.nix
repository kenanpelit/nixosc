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
# Modified: 2025-05-12 (COSMIC compatibility)
# ==============================================================================
{ username, ... }:
{
  services = {
    # X Server Settings
    # Base X server configuration needed by both Wayland and X11 desktop environments
    xserver = {
      enable = true;  # Enable X Server (required even for Wayland sessions)
      
      # Keyboard Configuration
      # Set Turkish F-layout as default with Caps Lock as Ctrl
      xkb = {
        layout = "tr";             # Turkish keyboard layout
        variant = "f";             # F-keyboard variant (Turkish standard)
        options = "ctrl:nocaps";   # Remap Caps Lock as Ctrl for better ergonomics
      };
    };
    
    # COSMIC Desktop Environment
    # Modern, intuitive desktop environment developed by System76
    desktopManager.cosmic.enable = true;
    
    # COSMIC Greeter
    # Login screen for the COSMIC desktop environment
    displayManager.cosmic-greeter.enable = true;
    
    # Display Manager Auto-Login Settings
    # Disabled to allow COSMIC Greeter to work properly
    displayManager.autoLogin = {
      enable = false;  # Disable auto-login to use COSMIC Greeter
      user = "${username}";  # Keep username reference for future use if needed
    };
    
    # Set COSMIC as the default session
    # This ensures COSMIC is launched when logging in
    displayManager.defaultSession = "cosmic";
    
    # Input Device Settings
    # Enable libinput for touchpad, trackpoint, and other input devices
    libinput.enable = true;  # Modern input device driver for X/Wayland
  };
  
  # COSMIC requires clipboard manager to be enabled
  # This enables the data control protocol for Wayland
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
}

