# modules/core/x11/default.nix
# ==============================================================================
# X Server & Display Manager Configuration
# ==============================================================================
# This configuration manages display server settings including:
# - X Server setup (also needed for Wayland)
# - Display manager configuration (GDM for GNOME + Hyprland)
# - Desktop environment setup
# - Session management
#
# Author: Kenan Pelit
# Modified: 2025-08-02 (Cleaned conflicts)
# ==============================================================================
{ username, inputs, pkgs, ... }:
{
  services = {
    # X Server Settings
    xserver = {
      enable = true;
      
      # Keyboard Configuration
      xkb = {
        layout = "tr";
        variant = "f";
        options = "ctrl:nocaps";
      };
    };
    
    # Display Manager - GDM
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      autoLogin.enable = false;
    };
    
    # Desktop Manager - GNOME
    desktopManager = {
      gnome.enable = true;
    };
    
    # Input Device Settings
    libinput.enable = true;
    
    # GNOME Keyring service
    gnome.gnome-keyring.enable = true;
  };
  
  # GNOME session files
  environment.etc = {
    "wayland-sessions/gnome.desktop".text = ''
      [Desktop Entry]
      Name=GNOME
      Comment=This session logs you into GNOME
      Exec=gnome-session
      Type=Application
      DesktopNames=GNOME
    '';
    
    "xdg/gnome-session/sessions/gnome.session".text = ''
      [GNOME Session]
      Name=GNOME
      RequiredComponents=org.gnome.Shell;org.gnome.SettingsDaemon.A11ySettings;org.gnome.SettingsDaemon.Color;org.gnome.SettingsDaemon.Datetime;org.gnome.SettingsDaemon.Housekeeping;org.gnome.SettingsDaemon.Keyboard;org.gnome.SettingsDaemon.MediaKeys;org.gnome.SettingsDaemon.Power;org.gnome.SettingsDaemon.PrintNotifications;org.gnome.SettingsDaemon.Rfkill;org.gnome.SettingsDaemon.ScreensaverProxy;org.gnome.SettingsDaemon.Sharing;org.gnome.SettingsDaemon.Smartcard;org.gnome.SettingsDaemon.Sound;org.gnome.SettingsDaemon.UsbProtection;org.gnome.SettingsDaemon.Wacom;org.gnome.SettingsDaemon.XSettings;
    '';
  };
  
  # Note: Audio config in modules/core/audio
  # Note: D-Bus config in modules/core/services  
  # Note: PAM config in modules/core/pam
  # Note: Wayland environment variables in modules/core/wayland
}

