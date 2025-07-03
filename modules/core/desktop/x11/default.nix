# modules/core/desktop/x11/default.nix
# ==============================================================================
# X Server & Display Manager Configuration
# ==============================================================================
# This configuration manages display server settings including:
# - X Server setup (also needed for Wayland)
# - Display manager configuration (GDM for GNOME + Hyprland)
# - Input device settings
# - Session management
#
# Author: Kenan Pelit
# Modified: 2025-07-02 (GNOME + Hyprland support)
# ==============================================================================
{ username, inputs, pkgs, ... }:
{
  services = {
    # ==========================================================================
    # D-Bus Configuration - DÜZELTME (sadece eksik paketler eklendi)
    # ==========================================================================
    dbus = {
      enable = true;
      packages = with pkgs; [
        gnome-settings-daemon
        gnome-session
        gnome-keyring  # Secret service için
      ];
    };

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
    
    # GNOME Keyring (secret service için)
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
  
  # Session Variables for Wayland
  environment.sessionVariables = {
    # Wayland-specific variables
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    
    # Qt applications
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    
    # GTK applications
    GDK_BACKEND = "wayland,x11";
    
    # SDL applications
    SDL_VIDEODRIVER = "wayland";
    
    # Cursor theme
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };
  
  # Audio Configuration
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # PAM for GNOME Keyring
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };
}

