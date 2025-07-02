# modules/home/desktop/gnome/default.nix
# ==============================================================================
# GNOME Desktop Environment Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:

with lib;

let
  colors = import ./../../../themes/default.nix;
  cfg = config.modules.desktop.gnome or {};
in
{
  # =============================================================================
  # Options (Optional - for flexibility)
  # =============================================================================
  options.modules.desktop.gnome = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GNOME desktop environment configuration";
    };
    
    extensions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of GNOME Shell extension UUIDs to enable";
    };
  };

  config = mkIf (cfg.enable or true) {
    # ==========================================================================
    # Package Installation (Extended)
    # ==========================================================================
    home.packages = (
      with pkgs;
      [
        # Original packages
        evince # pdf
        file-roller # archive
        gnome-text-editor # gedit
        
        # Additional GNOME core applications
        nautilus                    # File manager
        gnome-terminal              # Terminal
        gnome-calculator            # Calculator
        gnome-calendar              # Calendar
        gnome-contacts              # Contacts
        gnome-weather               # Weather
        gnome-clocks                # Clocks & timers
        eog                         # Image viewer
        gnome-font-viewer           # Font viewer
        gnome-system-monitor        # System monitor
        gnome-disk-utility          # Disk utility
        gnome-screenshot            # Screenshot tool
        
        # GNOME utilities
        gnome-tweaks                # Advanced settings
        dconf-editor                # Configuration editor
        gnome-shell-extensions      # Extensions support
        
        # Additional useful applications
        cheese                      # Webcam application
        totem                       # Video player
        snapshot                    # Camera app
        loupe                       # Modern image viewer
      ]
    );

    # ==========================================================================
    # GTK Configuration - REMOVED
    # Using existing GTK module to avoid conflicts
    # ==========================================================================
    # gtk configuration is handled by modules/home/desktop/gtk

    # ==========================================================================
    # DConf Settings (Extended)
    # ==========================================================================
    dconf.settings = {
      # ------------------------------------------------------------------------
      # Text Editor Configuration (Original - Preserved)
      # ------------------------------------------------------------------------
      "org/gnome/TextEditor" = {
        custom-font = "${colors.fonts.editor.family} ${toString colors.fonts.sizes.xl}";
        highlight-current-line = true;
        indent-style = "space";
        restore-session = false;
        show-grid = false;
        show-line-numbers = true;
        show-right-margin = false;
        style-scheme = "builder-dark";
        style-variant = "dark";
        tab-width = "uint32 4";
        use-system-font = false;
        wrap-text = false;
      };
      
      # ------------------------------------------------------------------------
      # Interface Configuration (Extended from Original)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/interface" = {
        # Original font settings (preserved)
        font-name = "${colors.fonts.main.family} ${toString colors.fonts.sizes.sm}";
        document-font-name = "${colors.fonts.main.family} ${toString colors.fonts.sizes.sm}";
        monospace-font-name = "${colors.fonts.terminal.family} ${toString colors.fonts.sizes.sm}";
        
        # Additional interface settings (theme settings removed to avoid conflicts)
        # gtk-theme = "Adwaita-dark";  # REMOVED - handled by GTK module
        # icon-theme = "Adwaita";      # REMOVED - handled by GTK module
        color-scheme = "prefer-dark";
        font-antialiasing = "grayscale";
        font-hinting = "slight";
        show-battery-percentage = true;
        clock-show-weekday = true;
        clock-show-date = true;
        enable-animations = true;
      };

      # ------------------------------------------------------------------------
      # Window Manager Settings - REMOVED to avoid conflicts with GTK module
      # ------------------------------------------------------------------------
      # "org/gnome/desktop/wm/preferences" = {
      #   titlebar-font = "${colors.fonts.main.family} Bold ${toString colors.fonts.sizes.sm}";
      #   button-layout = "appmenu:minimize,maximize,close";
      #   resize-with-right-button = true;
      #   mouse-button-modifier = "<Super>";
      # };

      # Window manager keybindings
      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>q"];
        toggle-fullscreen = ["<Super>f"];
        toggle-maximized = ["<Super>m"];
        minimize = ["<Super>h"];
        show-desktop = ["<Super>d"];
        switch-applications = ["<Alt>Tab"];
        switch-applications-backward = ["<Shift><Alt>Tab"];
        switch-windows = ["<Super>Tab"];
        switch-windows-backward = ["<Shift><Super>Tab"];
      };

      # ------------------------------------------------------------------------
      # Mutter (Window Manager) Settings
      # ------------------------------------------------------------------------
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = true;
        workspaces-only-on-primary = false;
        center-new-windows = true;
      };

      # ------------------------------------------------------------------------
      # Shell Settings
      # ------------------------------------------------------------------------
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
          "org.gnome.Terminal.desktop"
          "org.gnome.TextEditor.desktop"
          "org.gnome.Calculator.desktop"
          "org.gnome.Settings.desktop"
        ];
        enabled-extensions = cfg.extensions or [];
      };

      # Shell keybindings
      "org/gnome/shell/keybindings" = {
        show-applications = ["<Super>a"];
        show-screenshot-ui = ["<Super>Print"];
        toggle-overview = ["<Super>s"];
      };

      # ------------------------------------------------------------------------
      # Custom Keybindings
      # ------------------------------------------------------------------------
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>Return";
        command = "gnome-terminal";
        name = "Open Terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>e";
        command = "nautilus";
        name = "Open File Manager";
      };

      # ------------------------------------------------------------------------
      # Privacy Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/privacy" = {
        report-technical-problems = false;
        send-software-usage-stats = false;
        disable-microphone = false;
        disable-camera = false;
      };

      # ------------------------------------------------------------------------
      # Power Settings
      # ------------------------------------------------------------------------
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "suspend";
        sleep-inactive-battery-timeout = 1800; # 30 minutes
        power-button-action = "interactive";
      };

      # ------------------------------------------------------------------------
      # Touchpad Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
        natural-scroll = true;
        disable-while-typing = true;
      };

      # ------------------------------------------------------------------------
      # Mouse Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/peripherals/mouse" = {
        natural-scroll = false;
        speed = 0.0;
      };

      # ------------------------------------------------------------------------
      # Sound Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/sound" = {
        event-sounds = true;
        theme-name = "freedesktop";
      };

      # ------------------------------------------------------------------------
      # Session Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/session" = {
        idle-delay = 900; # 15 minutes
      };

      # ------------------------------------------------------------------------
      # Screensaver Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/screensaver" = {
        lock-enabled = true;
        lock-delay = 0;
        idle-activation-enabled = true;
      };

      # ------------------------------------------------------------------------
      # Nautilus (File Manager) Settings
      # ------------------------------------------------------------------------
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        search-filter-time-type = "last_modified";
        show-hidden-files = false;
        show-create-link = true;
      };

      "org/gnome/nautilus/list-view" = {
        use-tree-view = true;
        default-zoom-level = "small";
      };

      # ------------------------------------------------------------------------
      # Terminal Settings (using your font theme)
      # ------------------------------------------------------------------------
      "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        visible-name = "Default";
        background-color = "rgb(23,20,33)";
        foreground-color = "rgb(208,207,204)";
        use-theme-colors = false;
        use-system-font = false;
        font = "${colors.fonts.terminal.family} ${toString colors.fonts.sizes.md}";
        cursor-shape = "block";
        cursor-blink-mode = "on";
        audible-bell = false;
        scrollback-unlimited = true;
      };
    };

    # ==========================================================================
    # XDG Settings
    # ==========================================================================
    xdg = {
      enable = true;
      
      # Default applications
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/plain" = "org.gnome.TextEditor.desktop";
          "text/html" = "firefox.desktop";
          "application/pdf" = "org.gnome.Evince.desktop";
          "image/jpeg" = "org.gnome.eog.desktop";
          "image/png" = "org.gnome.eog.desktop";
          "video/mp4" = "org.gnome.Totem.desktop";
          "audio/mpeg" = "org.gnome.Music.desktop";
          "inode/directory" = "org.gnome.Nautilus.desktop";
        };
      };
      
      # User directories
      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };

    # ==========================================================================
    # Services - REMOVED gnome-keyring to avoid conflicts
    # ==========================================================================
    # services = {
    #   # GNOME Keyring - DISABLED (conflicts with pass-secret-service)
    #   gnome-keyring = {
    #     enable = true;
    #     components = [ "pkcs11" "secrets" "ssh" ];
    #   };
    # };

    # ==========================================================================
    # Session Variables - SIMPLIFIED
    # ==========================================================================
    home.sessionVariables = {
      # Let existing GTK module handle theme variables
      GNOME_SESSION = "1";  # Indicate GNOME session
    };
  };
}

