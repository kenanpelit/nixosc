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
    # X Server Settings
    xserver = {
      enable = true;
      
      # Keyboard Configuration
      xkb = {
        layout = "tr";
        variant = "f";
        options = "ctrl:nocaps";
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
    };
    
    # Alternative: Try this syntax if above doesn't work
    desktopManager = {
      gnome.enable = true;
    };
    
    # Input Device Settings
    libinput.enable = true;
  };

  # Manual GNOME session file creation (fallback)
  environment.etc."wayland-sessions/gnome.desktop".text = ''
    [Desktop Entry]
    Name=GNOME
    Comment=This session logs you into GNOME
    Exec=gnome-session
    Type=Application
    DesktopNames=GNOME
  '';

  # Session Variables for Wayland
  # These environment variables ensure applications work properly in Wayland
  environment.sessionVariables = {
    # Wayland-specific variables
    NIXOS_OZONE_WL = "1";  # Enable Wayland for Electron apps (VS Code, Discord, etc.)
    MOZ_ENABLE_WAYLAND = "1";  # Enable Wayland for Firefox (better performance)
    
    # Qt applications
    QT_QPA_PLATFORM = "wayland;xcb";  # Qt Wayland with X11 fallback
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";  # Let window manager handle decorations
    
    # GTK applications (GNOME apps)
    GDK_BACKEND = "wayland,x11";  # GTK Wayland with X11 fallback
    
    # SDL applications (games, multimedia)
    SDL_VIDEODRIVER = "wayland";  # Use Wayland for SDL apps
    
    # Cursor theme
    XCURSOR_THEME = "Adwaita";  # Mouse cursor theme
    XCURSOR_SIZE = "24";        # Cursor size
  };
  
  # COSMIC clipboard manager setting - COMMENTED OUT
  # This enables the data control protocol for Wayland
  # environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  # Audio Configuration (recommended for GNOME)
  # Disable PulseAudio in favor of PipeWire (better Wayland support)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # PulseAudio compatibility layer
    # Optional: Enable JACK support for professional audio
    # jack.enable = true;
  };

}

