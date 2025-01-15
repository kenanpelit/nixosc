# modules/core/xserver/default.nix
# ==============================================================================
# X Server Configuration
# ==============================================================================
{ pkgs, username, ... }:
{
  services = {
    # =============================================================================
    # X Server Settings
    # =============================================================================
    xserver = {
      enable = true;
      # Keyboard Configuration
      xkb = {
        layout = "tr";
        variant = "f";
        options = "ctrl:nocaps";  # Caps Lock as Ctrl
      };
    };

    # =============================================================================
    # Display Manager Settings
    # =============================================================================
    displayManager.autoLogin = {
      enable = true;
      user = "${username}";
    };

    # =============================================================================
    # Input Device Settings
    # =============================================================================
    libinput.enable = true;  # Enable libinput for input devices
  };

  # =============================================================================
  # Systemd Configuration
  # =============================================================================
  # Prevent shutdown hanging
  systemd.extraConfig = "DefaultTimeoutStopSec=10s";
}
