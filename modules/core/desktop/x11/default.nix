# ==============================================================================
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
# Modified: 2025-05-12 (COSMIC compatibility) - COSMIC Desktop commented out
# Modified: 2025-07-02 (GNOME + Hyprland support)
# ==============================================================================
{ username, inputs, pkgs, ... }:
{
  services = {
    # X Server Settings
    # Base X server configuration needed by both Wayland and X11 desktop environments
    xserver = {
      enable = true;  # Enable X Server (required even for Wayland sessions)
      
      # Display Manager - GDM (GNOME Display Manager)
      # GDM supports both GNOME and Wayland sessions like Hyprland
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;  # Enable Wayland support in GDM
        };
        
        # Auto-login disabled when using GDM (you can choose session at login)
        autoLogin = {
          enable = false;  # Disabled to allow session selection
          # user = "${username}";  # Uncomment if you want auto-login
        };
        
        # Default session - let user choose at login
        # defaultSession = "gnome";  # Uncomment to default to GNOME
      };
      
      # Desktop Manager - Enable GNOME
      desktopManager = {
        gnome.enable = true;
      };
      
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
    
    # GNOME Services
    gnome = {
      gnome-keyring.enable = true;
      sushi.enable = true;          # File previews in Nautilus
      gnome-settings-daemon.enable = true;
    };
    
    # Input Device Settings
    # Enable libinput for touchpad, trackpoint, and other input devices
    libinput.enable = true;  # Modern input device driver for X/Wayland
  };

  # Hyprland Program Configuration
  # This makes Hyprland available as a session in GDM
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    # Enable XWayland for X11 app compatibility
    xwayland.enable = true;
  };

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

  # XDG Portal Configuration for Wayland
  # Portals handle file dialogs, screen sharing, etc. in Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;  # For Hyprland and other wlroots compositors
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome  # For GNOME integration
      xdg-desktop-portal-gtk    # GTK portal for file dialogs
    ];
    config = {
      common = {
        default = [
          "gtk"
        ];
      };
      gnome = {
        default = [
          "gnome"
          "gtk"
        ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
    };
  };

  # Audio Configuration (recommended for GNOME)
  # Disable PulseAudio in favor of PipeWire (better Wayland support)
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # PulseAudio compatibility layer
    # Optional: Enable JACK support for professional audio
    # jack.enable = true;
  };

  # Exclude unwanted GNOME packages (optional)
  # Remove GNOME apps you don't need to keep system clean
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour        # GNOME welcome tour
    epiphany          # GNOME Web browser (you have Firefox)
    geary             # Mail app
    gnome.gnome-music # Music player
    gnome.gnome-photos # Photo organizer
    # Add more apps you don't want here
  ];
}

