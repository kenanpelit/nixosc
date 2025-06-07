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
# Modified: 2025-05-12 (COSMIC compatibility) - COSMIC Desktop commented out
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
    
    # COSMIC Desktop Environment - COMMENTED OUT
    # Modern, intuitive desktop environment developed by System76
    # desktopManager.cosmic.enable = true;
    
    # COSMIC Greeter - COMMENTED OUT
    # Login screen for the COSMIC desktop environment
    # displayManager.cosmic-greeter.enable = true;
    
    # Display Manager Auto-Login Settings
    # Re-enabled since COSMIC Greeter is disabled
    displayManager.autoLogin = {
      enable = true;  # Enable auto-login since COSMIC Greeter is disabled
      user = "${username}";  # Auto-login with the specified username
    };
    
    # Set default session - COSMIC commented out
    # This would ensure COSMIC is launched when logging in
    # displayManager.defaultSession = "cosmic";
    
    # Input Device Settings
    # Enable libinput for touchpad, trackpoint, and other input devices
    libinput.enable = true;  # Modern input device driver for X/Wayland
  };
  
  # COSMIC clipboard manager setting - COMMENTED OUT
  # This enables the data control protocol for Wayland
  # environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
}

