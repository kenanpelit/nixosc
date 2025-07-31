# modules/home/gnome/default.nix
# ==============================================================================
# GNOME Desktop Environment Configuration with Catppuccin Mocha Theme
# ==============================================================================
{ config, lib, pkgs, ... }:

with lib;

let
  # Font ayarları
  fonts = {
    main = {
      family = "Maple Mono";
    };
    editor = {
      family = "Maple Mono";
    };
    terminal = {
      family = "Hack Nerd Font";
    };
    sizes = {
      sm = 12;
      md = 13;
      xl = 15;
    };
  };

  # Catppuccin Mocha Color Palette
  mocha = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    overlay2 = "#9399b2";
    overlay1 = "#7f849c";
    overlay0 = "#6c7086";
    surface2 = "#585b70";
    surface1 = "#45475a";
    surface0 = "#313244";
    mauve = "#cba6f7";
    lavender = "#b4befe";
    blue = "#89b4fa";
    sapphire = "#74c7ec";
    sky = "#89dceb";
    teal = "#94e2d5";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    peach = "#fab387";
    maroon = "#eba0ac";
    red = "#f38ba8";
    pink = "#f5c2e7";
    flamingo = "#f2cdcd";
    rosewater = "#f5e0dc";
  };
  
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
      default = [
        # Mevcut aktif extension'lar - güncel liste
        "clipboard-indicator@tudmotu.com"
        "dash-to-panel@jderose9.github.com"
        "alt-tab-scroll-workaround@lucasresck.github.io"
        "extension-list@tu.berry"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "bluetooth-quick-connect@bjarosze.gmail.com"
        "no-overview@fthx"
        "Vitals@CoreCoding.com"
        "tilingshell@ferrarodomenico.com"
        "weatheroclock@CleoMenezesJr.github.io"
        "spotify-controls@Sonath21"
        "space-bar@luchrioh"
        "sound-percentage@subashghimire.info.np"
        "screenshort-cut@pauloimon"
        "window-centering@hnjjhmtr27"
        "disable-workspace-animation@ethnarque"
        "gsconnect@andyholmes.github.io"
        "mullvadindicator@pobega.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"  # Shell tema için gerekli
      ];
      description = "List of GNOME Shell extension UUIDs to enable by default";
    };
  };

  config = mkIf (cfg.enable or true) {
    # ==========================================================================
    # Package Installation (Extended with Catppuccin Theme Support)
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
        
        # Additional useful applications
        cheese                      # Webcam application
        totem                       # Video player
        snapshot                    # Camera app
        loupe                       # Modern image viewer
        
        # Extra tools for custom keybindings
        copyq                       # Clipboard manager
        kitty                       # Terminal for keybindings
        nemo                        # Alternative file manager
        
        # Theme support packages
        gtk3                        # GTK3 support
        gtk4                        # GTK4 support
        
        # Icon and cursor themes (if available in nixpkgs)
        # Note: Catppuccin themes might need manual installation
      ]
    );

    # ==========================================================================
    # GTK Configuration for Catppuccin Mocha
    # ==========================================================================
    gtk = {
      enable = true;
      
      # Theme settings
      theme = {
        name = "catppuccin-mocha-mauve-standard+normal";
        package = null; # Will be set manually or via overlay
      };
      
      iconTheme = {
        name = "a-candy-beauty-icon-theme";
        package = null; # Will be set manually
      };
      
      cursorTheme = {
        name = "catppuccin-mocha-dark-cursors";
        size = 24;
        package = null; # Will be set manually
      };

      # GTK3 specific settings
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-cursor-theme-name = "catppuccin-mocha-dark-cursors";
        gtk-cursor-theme-size = 24;
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-icon-theme-name = "a-candy-beauty-icon-theme";
        gtk-theme-name = "catppuccin-mocha-mauve-standard+normal";
      };

      # GTK4 specific settings
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-cursor-theme-name = "catppuccin-mocha-dark-cursors";
        gtk-cursor-theme-size = 24;
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-icon-theme-name = "a-candy-beauty-icon-theme";
        gtk-theme-name = "catppuccin-mocha-mauve-standard+normal";
      };
    };

    # ==========================================================================
    # DConf Settings (Complete Configuration with Catppuccin)
    # ==========================================================================
    dconf.settings = {
      # ------------------------------------------------------------------------
      # Text Editor Configuration (Enhanced with Catppuccin)
      # ------------------------------------------------------------------------
      "org/gnome/TextEditor" = {
        custom-font = "${fonts.editor.family} ${toString fonts.sizes.xl}";
        highlight-current-line = true;
        indent-style = "space";
        restore-session = false;
        show-grid = false;
        show-line-numbers = true;
        show-right-margin = false;
        style-scheme = "catppuccin-mocha"; # Updated for Catppuccin
        style-variant = "dark";
        tab-width = "uint32 4";
        use-system-font = false;
        wrap-text = false;
      };
      
      # ------------------------------------------------------------------------
      # Interface Configuration (Catppuccin Mocha Enhanced)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/interface" = {
        # Font settings (preserved)
        font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        document-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        monospace-font-name = "${fonts.terminal.family} ${toString fonts.sizes.sm}";
        
        # Catppuccin Mocha theme settings
        gtk-theme = "catppuccin-mocha-mauve-standard+normal";
        icon-theme = "a-candy-beauty-icon-theme";
        cursor-theme = "catppuccin-mocha-dark-cursors";
        cursor-size = 24;
        
        # Interface settings
        color-scheme = "prefer-dark";
        font-antialiasing = "grayscale";
        font-hinting = "slight";
        show-battery-percentage = true;
        clock-show-weekday = true;
        clock-show-date = true;
        enable-animations = true;
        
        # GNOME 44+ accent color
        accent-color = "purple";
      };

      # ------------------------------------------------------------------------
      # Shell Theme Configuration
      # ------------------------------------------------------------------------
      "org/gnome/shell/extensions/user-theme" = {
        name = "catppuccin-mocha-mauve-standard+normal";
      };

      # ------------------------------------------------------------------------
      # Window Manager Preferences (Enhanced)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 9;  # 9 fixed workspaces
        workspace-names = ["1" "2" "3" "4" "5" "6" "7" "8" "9"];
        
        # Theme settings
        theme = "catppuccin-mocha-mauve-standard+normal";
        titlebar-font = "${fonts.main.family} Bold ${toString fonts.sizes.sm}";
        button-layout = "appmenu:minimize,maximize,close";

        # Focus ayarları
        focus-mode = "click";
        focus-new-windows = "smart";
        auto-raise = false;
        raise-on-click = true;
      };

      # ------------------------------------------------------------------------
      # Background/Wallpaper Settings (Catppuccin)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/background" = {
        # Fallback to solid color if wallpaper not found
        color-shading-type = "solid";
        primary-color = mocha.base;
        picture-options = "zoom";
        # picture-uri will be set by script if wallpaper exists
        # picture-uri-dark will be set by script if wallpaper exists
      };

      "org/gnome/desktop/screensaver" = {
        color-shading-type = "solid";
        primary-color = mocha.mantle;
        lock-enabled = true;
        lock-delay = "uint32 0";
        idle-activation-enabled = true;
        # picture-uri will be set by script if lockscreen wallpaper exists
      };

      # ------------------------------------------------------------------------
      # Terminal Configuration (Catppuccin Mocha)
      # ------------------------------------------------------------------------
      "org/gnome/terminal/legacy/profiles:/:catppuccin-mocha" = {
        visible-name = "Catppuccin Mocha";
        use-theme-colors = false;
        use-theme-transparency = false;
        use-transparent-background = true;
        background-transparency-percent = 10;
        
        # Catppuccin Mocha colors
        background-color = mocha.base;
        foreground-color = mocha.text;
        bold-color = mocha.text;
        bold-color-same-as-fg = true;
        cursor-colors-set = true;
        cursor-background-color = mocha.rosewater;
        cursor-foreground-color = mocha.base;
        highlight-colors-set = true;
        highlight-background-color = mocha.surface2;
        highlight-foreground-color = mocha.text;
        
        # Terminal palette (16 colors)
        palette = [
          mocha.surface1 mocha.red mocha.green mocha.yellow
          mocha.blue mocha.pink mocha.teal mocha.subtext1
          mocha.surface2 mocha.red mocha.green mocha.yellow
          mocha.blue mocha.pink mocha.teal mocha.subtext0
        ];
        
        # Font settings
        use-system-font = false;
        font = "${fonts.terminal.family} ${toString fonts.sizes.md}";
        cursor-shape = "block";
        cursor-blink-mode = "on";
        audible-bell = false;
        scrollback-unlimited = true;
      };

      # Set default terminal profile
      "org/gnome/terminal/legacy" = {
        default-profile = "catppuccin-mocha";
      };

      # ------------------------------------------------------------------------
      # Built-in GNOME Workspace & Window Keybindings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/wm/keybindings" = {
        # Basic window management
        close = ["<Super>q"];
        toggle-fullscreen = ["<Super>f"];
        toggle-maximized = ["<Super>m"];
        minimize = ["<Super>h"];
        show-desktop = ["<Super>d"];
        switch-applications = ["<Alt>Tab"];
        switch-applications-backward = ["<Shift><Alt>Tab"];
        switch-windows = ["<Super>Tab"];
        switch-windows-backward = ["<Shift><Super>Tab"];

        # Workspace switching (1-9) - DISABLED for custom history support
        switch-to-workspace-1 = [];
        switch-to-workspace-2 = [];
        switch-to-workspace-3 = [];
        switch-to-workspace-4 = [];
        switch-to-workspace-5 = [];
        switch-to-workspace-6 = [];
        switch-to-workspace-7 = [];
        switch-to-workspace-8 = [];
        switch-to-workspace-9 = [];
        switch-to-workspace-10 = [];

        # Move window to workspace - FIXED FOR GNOME
        move-to-workspace-1 = ["<Super><Shift>1"];
        move-to-workspace-2 = ["<Super><Shift>2"];
        move-to-workspace-3 = ["<Super><Shift>3"];
        move-to-workspace-4 = ["<Super><Shift>4"];
        move-to-workspace-5 = ["<Super><Shift>5"];
        move-to-workspace-6 = ["<Super><Shift>6"];
        move-to-workspace-7 = ["<Super><Shift>7"];
        move-to-workspace-8 = ["<Super><Shift>8"];
        move-to-workspace-9 = ["<Super><Shift>9"];

        # Navigate workspaces with arrows - DISABLED
        switch-to-workspace-left = [];
        switch-to-workspace-right = [];
        switch-to-workspace-up = [];
        switch-to-workspace-down = [];

        # Move window between workspaces
        move-to-workspace-left = ["<Super><Shift>Left"];
        move-to-workspace-right = ["<Super><Shift>Right"];
        move-to-workspace-up = ["<Super><Shift>Up"];
        move-to-workspace-down = ["<Super><Shift>Down"];

        # Window movement within workspace - REMOVED (conflicts with tiling)
        # move-window-left = ["<Super><Alt>Left" "<Super><Alt>h"];
        # move-window-right = ["<Super><Alt>Right" "<Super><Alt>l"];
        # move-window-up = ["<Super><Alt>Up" "<Super><Alt>k"];
        # move-window-down = ["<Super><Alt>Down" "<Super><Alt>j"];
      };

      # Shell keybindings
      "org/gnome/shell/keybindings" = {
        show-applications = ["<Super>a"];
        show-screenshot-ui = ["<Super>Print"];
        toggle-overview = ["<Super>s"];
        
        # Application switching keybinding'larını kapat (workspace çakışması için)
        switch-to-application-1 = [];
        switch-to-application-2 = [];
        switch-to-application-3 = [];
        switch-to-application-4 = [];
        switch-to-application-5 = [];
        switch-to-application-6 = [];
        switch-to-application-7 = [];
        switch-to-application-8 = [];
        switch-to-application-9 = [];
      };

      # ------------------------------------------------------------------------
      # Mutter (Window Manager) Settings - Optimized
      # ------------------------------------------------------------------------
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = false;
        workspaces-only-on-primary = false;
        center-new-windows = true;
  
        # Focus ayarları
        focus-change-on-pointer-rest = true;
        auto-maximize = false;
        attach-modal-dialogs = true;
      };

      # ------------------------------------------------------------------------
      # Shell Settings & Extensions
      # ------------------------------------------------------------------------
      "org/gnome/shell" = {
        favorite-apps = [
          "brave-browser.desktop"
          "kitty.desktop"
        ];
        enabled-extensions = cfg.extensions;
        disabled-extensions = [];
      };

      # ------------------------------------------------------------------------
      # Extension Configurations - UPDATED & OPTIMIZED with Catppuccin
      # ------------------------------------------------------------------------
      
      # Dash to Panel - Enhanced with Catppuccin colors
      "org/gnome/shell/extensions/dash-to-panel" = {
        # Temel panel ayarları
        appicon-margin = 8;
        appicon-padding = 4;
        show-favorites = true;
        show-running-apps = true;
        show-window-previews = true;
        isolate-workspaces = false;
        group-apps = true;
        
        # Panel boyut ayarları - Scripteki gibi 28px
        panel-sizes = ''{"0":28}'';
        panel-lengths = ''{"0":100}'';
        panel-positions = ''{"0":"TOP"}'';
        panel-anchors = ''{"0":"MIDDLE"}'';
        
        # Catppuccin tema ayarları
        trans-use-custom-bg = true;
        trans-bg-color = mocha.base;
        trans-use-custom-opacity = true;
        trans-panel-opacity = 0.95;
        
        # Diğer ayarlar
        dot-position = "BOTTOM";
        window-preview-title-position = "TOP";
        hotkeys-overlay-combo = "TEMPORARILY";
        
        # Animasyon ayarları
        animate-appicon-hover-animation-extent = "{'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}";
      };

      # Clipboard Indicator
      "org/gnome/shell/extensions/clipboard-indicator" = {
        toggle-menu = ["<Super>v"];
        clear-history = [];
        prev-entry = [];
        next-entry = [];
        cache-size = 50;
        display-mode = 0;
      };

      # GSConnect
      "org/gnome/shell/extensions/gsconnect" = {
        show-indicators = true;
        show-offline = false;
      };

      # Bluetooth Quick Connect
      "org/gnome/shell/extensions/bluetooth-quick-connect" = {
        show-battery-icon-on = true;
        show-battery-value-on = true;
      };

      # VITALS - UPDATED: Network TX eklendi + optimizasyonlar
      "org/gnome/shell/extensions/vitals" = {
        hot-sensors = ["_processor_usage_" "_memory_usage_" "_network-rx_max_" "_network-tx_max_"];
        position-in-panel = 2;  # Center
        use-higher-precision = false;
        alphabetize = true;
        include-static-info = false;
        show-icons = true;
        show-battery = true;
        unit-fahrenheit = false;
        memory-measurement = 0;
        network-speed-format = 1;
        storage-measurement = 0;
        hide-zeros = true;
        menu-centered = false;
      };

      # TILINGSHELL - UPDATED with Catppuccin colors and Windows Suggestions
      "org/gnome/shell/extensions/tilingshell" = {
        # Temel tiling ayarları
        enable-tiling-system = true;
        auto-tile = true;
        snap-assist = true;
        
        # Layout ayarları
        default-layout = "split";
        inner-gaps = 4;
        outer-gaps = 4;
        
        # Windows Suggestions özelliği (2024-2025 güncellemesi)
        enable-window-suggestions = true;
        window-suggestions-for-snap-assist = true;
        window-suggestions-for-edge-tiling = true;
        window-suggestions-for-keybinding = true;
        suggestions-timeout = 3000;
        max-suggestions-to-show = 6;
        enable-suggestions-scroll = true;
        
        # Keybindings
        tile-left = ["<Super><Shift>Left"];
        tile-right = ["<Super><Shift>Right"];
        tile-up = ["<Super><Shift>Up"];
        tile-down = ["<Super><Shift>Down"];
        toggle-tiling = ["<Super>t"];
        toggle-floating = ["<Super>f"];
        
        # Window focus
        focus-left = ["<Super>Left"];
        focus-right = ["<Super>Right"];
        focus-up = ["<Super>Up"];
        focus-down = ["<Super>Down"];
        auto-focus-on-tile = true;
        focus-follows-mouse = false;
        respect-focus-hints = true;

        # Layout switching
        next-layout = ["<Super>Tab"];
        prev-layout = ["<Super><Shift>Tab"];
        
        # Resize ayarları
        resize-step = 50;
        
        # Visual ayarları - Catppuccin Mocha renkleri
        show-border = true;
        border-width = 2;
        border-color = mocha.mauve;
        active-window-border-color = mocha.lavender;
        
        # Animation
        enable-animations = true;
        animation-duration = 150;
        
        # Advanced settings
        respect-workspaces = true;
        tile-dialogs = false;
        tile-modals = false;
        
        # Layout configurations (mevcut korundu)
        layouts-json = ''[{"id":"Layout 1","tiles":[{"x":0,"y":0,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0,"y":0.5,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[2,3]},{"x":0.78,"y":0,"width":0.22,"height":0.5,"groups":[3,4]},{"x":0.78,"y":0.5,"width":0.22,"height":0.5,"groups":[3,4]}]},{"id":"Layout 2","tiles":[{"x":0,"y":0,"width":0.22,"height":1,"groups":[1]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[1,2]},{"x":0.78,"y":0,"width":0.22,"height":1,"groups":[2]}]},{"id":"Layout 3","tiles":[{"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},{"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}]},{"id":"Layout 4","tiles":[{"x":0,"y":0,"width":0.67,"height":1,"groups":[1]},{"x":0.67,"y":0,"width":0.33,"height":1,"groups":[1]}]}]'';
        
        # Selected layouts per workspace
        selected-layouts = [["Layout 4" "Layout 4"] ["Layout 1" "Layout 1"] ["Layout 4" "Layout 4"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"]];
        
        # Version info
        last-version-name-installed = "16.4";
      };

      # SPOTIFY CONTROLS - UPDATED: Kompakt mod
      "org/gnome/shell/extensions/spotify-controls" = {
        show-track-info = false;
        position = "middle-right";
        show-notifications = true;
        track-length = 30;
        show-pause-icon = true;
        show-next-icon = true;
        show-prev-icon = true;
        button-color = "default";
        hide-on-no-spotify = true;
        show-volume-control = false;
        show-album-art = false;
        compact-mode = true;
      };

      # Space Bar - Enhanced Catppuccin Mocha CSS
      "org/gnome/shell/extensions/space-bar/appearance" = {
        application-styles = ''
          .space-bar {
            -natural-hpadding: 12px;
            background-color: ${mocha.base};
          }

          .space-bar-workspace-label.active {
            margin: 0 4px;
            background-color: ${mocha.mauve};
            color: ${mocha.base};
            border-color: transparent;
            font-weight: 700;
            border-radius: 6px;
            border-width: 0px;
            padding: 4px 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
          }

          .space-bar-workspace-label.inactive {
            margin: 0 4px;
            background-color: ${mocha.surface0};
            color: ${mocha.text};
            border-color: transparent;
            font-weight: 500;
            border-radius: 6px;
            border-width: 0px;
            padding: 4px 10px;
            transition: all 0.2s ease;
          }

          .space-bar-workspace-label.inactive:hover {
            background-color: ${mocha.surface1};
            color: ${mocha.subtext1};
          }

          .space-bar-workspace-label.inactive.empty {
            margin: 0 4px;
            background-color: transparent;
            color: ${mocha.overlay0};
            border-color: transparent;
            font-weight: 400;
            border-radius: 6px;
            border-width: 0px;
            padding: 4px 10px;
          }
        '';
      };

      # Auto Move Windows
      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "brave-browser.desktop:1"           # Browser → Workspace 1
          "kitty.desktop:2"                   # Terminal → Workspace 2  
          "discord.desktop:5"                 # Discord → Workspace 5
          "webcord.desktop:5"                 # Webcord → Workspace 5
          "whatsie.desktop:9"                 # WhatsApp → Workspace 9
          "ferdium.desktop:9"                 # Ferdium → Workspace 9
          "spotify.desktop:8"                 # Spotify → Workspace 8
          "brave-agimnkijcaahngcdmfeangaknmldooml-Default.desktop:7"  # Brave PWA → Workspace 7
        ];
      };
       
      # App switcher settings
      "org/gnome/shell/app-switcher" = {
        current-workspace-only = false;  # Show apps from all workspaces
      };

      "org/gnome/shell/window-switcher" = {
        current-workspace-only = true;   # Show windows from current workspace only
      };

      # ------------------------------------------------------------------------
      # Custom Keybindings - Complete Set from Script (CONTINUATION)
      # ------------------------------------------------------------------------
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom28/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom29/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom30/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom31/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom32/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom33/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom34/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom35/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom36/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40/"
        ];
      };

      # =======================================================================
      # TERMINAL EMULATORS & FILE MANAGERS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>Return";
        command = "kitty";
        name = "Terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>b";
        command = "brave";
        name = "Browser";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Super>e";
        command = "kitty --class floating-terminal -e yazi";
        name = "Terminal File Manager (Floating)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        binding = "<Alt><Ctrl>f";
        command = "nemo";
        name = "Open Nemo File Manager";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        binding = "<Alt>f";
        command = "kitty yazi";
        name = "Terminal File Manager (Yazi)";
      };

      # =======================================================================
      # APPLICATION LAUNCHERS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
        binding = "<Super><Alt>space";
        command = "walker";
        name = "Open Walker";
      };

      # =======================================================================
      # AUDIO & MEDIA CONTROL
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
        binding = "<Alt>a";
        command = "osc-soundctl switch";
        name = "Switch Audio Output";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
        binding = "<Alt><Ctrl>a";
        command = "osc-soundctl switch-mic";
        name = "Switch Microphone";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8" = {
        binding = "<Alt>e";
        command = "osc-spotify";
        name = "Spotify Toggle";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9" = {
        binding = "<Alt><Ctrl>n";
        command = "osc-spotify next";
        name = "Spotify Next";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10" = {
        binding = "<Alt><Ctrl>b";
        command = "osc-spotify prev";
        name = "Spotify Previous";
      };

      # =======================================================================
      # MPV MANAGEMENT (GNOME-Flow Integration)
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11" = {
        binding = "<Alt>i";
        command = "gnome-mpv-manager start";
        name = "MPV Start/Focus";
      };

      # =======================================================================
      # SYSTEM TOOLS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12" = {
        binding = "<Alt>l";
        command = "loginctl lock-session";
        name = "Lock Screen";
      };

      # =======================================================================
      # WORKSPACE NAVIGATION
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13" = {
        binding = "<Super><Alt>Left";
        command = "bash -c 'current=$(wmctrl -d | grep \"*\" | awk \"{print \\$1}\"); if [ $current -gt 0 ]; then wmctrl -s $((current - 1)); fi'";
        name = "Previous Workspace";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14" = {
        binding = "<Super><Alt>Right";
        command = "bash -c 'current=$(wmctrl -d | grep \"*\" | awk \"{print \\$1}\"); total=$(wmctrl -d | wc -l); if [ $current -lt $((total - 1)) ]; then wmctrl -s $((current + 1)); fi'";
        name = "Next Workspace";
      };

      # =======================================================================
      # APPLICATIONS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15" = {
        binding = "<Super><Shift>d";
        command = "webcord --enable-features=UseOzonePlatform --ozone-platform=wayland";
        name = "Open Discord";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16" = {
        binding = "<Alt>t";
        command = "gnome-kkenp";
        name = "Start KKENP";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17" = {
        binding = "<Super>n";
        command = "anotes -M";
        name = "Notes Manager";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18" = {
        binding = "<Alt>v";
        command = "copyq toggle";
        name = "Clipboard Manager";
      };

      # =======================================================================
      # VARIOUS TOOLS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19" = {
        binding = "F10";
        command = "hypr-bluetooth_toggle";
        name = "Bluetooth Toggle";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20" = {
        binding = "<Alt>F12";
        command = "osc-mullvad toggle";
        name = "Mullvad Toggle";
      };

      # =======================================================================
      # STARTUP SCRIPTS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21" = {
        binding = "<Super><Alt>Return";
        command = "osc-start_gnome launch --daily";
        name = "Gnome Start";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22" = {
        binding = "<Super><Shift>s";
        command = "gnome-screenshot -i";
        name = "Screenshot Tool";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23" = {
        binding = "<Alt><Shift>i";
        command = "gnome-mpv-manager move";
        name = "MPV Move Window";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24" = {
        binding = "<Alt><Ctrl>i";
        command = "gnome-mpv-manager resize";
        name = "MPV Resize Center";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom25" = {
        binding = "<Alt>y";
        command = "gnome-mpv-manager play-yt";
        name = "Play YouTube from Clipboard";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom26" = {
        binding = "<Alt><Shift>y";
        command = "gnome-mpv-manager save-yt";
        name = "Download YouTube Video";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom27" = {
        binding = "<Alt>p";
        command = "gnome-mpv-manager playback";
        name = "MPV Toggle Playback";
      };

      # =======================================================================
      # WORKSPACE SWITCHING WITH HISTORY SUPPORT (1-9)
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom28" = {
        binding = "<Super>1";
        command = "workspace-switcher 1";
        name = "Workspace 1 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom29" = {
        binding = "<Super>2";
        command = "workspace-switcher 2";
        name = "Workspace 2 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom30" = {
        binding = "<Super>3";
        command = "workspace-switcher 3";
        name = "Workspace 3 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom31" = {
        binding = "<Super>4";
        command = "workspace-switcher 4";
        name = "Workspace 4 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom32" = {
        binding = "<Super>5";
        command = "workspace-switcher 5";
        name = "Workspace 5 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom33" = {
        binding = "<Super>6";
        command = "workspace-switcher 6";
        name = "Workspace 6 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom34" = {
        binding = "<Super>7";
        command = "workspace-switcher 7";
        name = "Workspace 7 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom35" = {
        binding = "<Super>8";
        command = "workspace-switcher 8";
        name = "Workspace 8 (with history)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom36" = {
        binding = "<Super>9";
        command = "workspace-switcher 9";
        name = "Workspace 9 (with history)";
      };

      # =======================================================================
      # POWER MANAGEMENT SHORTCUTS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37" = {
        binding = "<Ctrl><Alt><Shift>s";
        command = "gnome-session-quit --power-off --no-prompt";
        name = "Shutdown Computer";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38" = {
        binding = "<Ctrl><Alt>r";
        command = "gnome-session-quit --reboot --no-prompt";
        name = "Restart Computer";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39" = {
        binding = "<Ctrl><Alt>q";
        command = "gnome-session-quit --logout --no-prompt";
        name = "Logout";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom40" = {
        binding = "<Ctrl><Alt>p";
        command = "gnome-session-quit --power-off";
        name = "Power Menu (with confirmation)";
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
        sleep-inactive-ac-type = "suspend";
        sleep-inactive-ac-timeout = 3600; # 60 minutes
        sleep-inactive-battery-type = "suspend";
        sleep-inactive-battery-timeout = 3600; # 60 minutes
        power-button-action = "interactive";
        handle-lid-switch = false;
      };

      # ------------------------------------------------------------------------
      # Session Settings - Screen Blank Disabled
      # ------------------------------------------------------------------------
      "org/gnome/desktop/session" = {
        idle-delay = "uint32 0"; # Screen blank DISABLED
      };

      # ------------------------------------------------------------------------
      # Touchpad Settings - Traditional Scrolling + Faster Speed
      # ------------------------------------------------------------------------
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
        natural-scroll = false;  # Traditional scrolling
        disable-while-typing = true;
        click-method = "fingers";
        send-events = "enabled";
        speed = 0.8;  # Faster speed
        accel-profile = "default";
        scroll-method = "two-finger-scrolling";
        middle-click-emulation = false;
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
      # Notification Settings
      # ------------------------------------------------------------------------
      "org/gnome/desktop/notifications" = {
        show-in-lock-screen = false;
        show-banners = true;
      };
    }; # dconf.settings sonu

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
          "text/html" = "brave-browser.desktop";
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
    # Session Variables (Enhanced with Catppuccin + System Variables)
    # ==========================================================================
    home.sessionVariables = {
      GNOME_SESSION = "1";
      
      # Catppuccin Mocha Theme Environment Variables
      CATPPUCCIN_THEME = "mocha";
      CATPPUCCIN_ACCENT = "mauve";
      GTK_THEME = "catppuccin-mocha-mauve-standard+normal";
      XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
      XCURSOR_SIZE = "24";
      
      # HiDPI cursor size adjustment
      GDK_SCALE = mkDefault "1";
      GDK_DPI_SCALE = mkDefault "1";
      
      # System Variables - ADDED
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "kitty";
      TERM = "xterm-kitty";
      BROWSER = "brave";
    };

    # ==========================================================================
    # GTK CSS Configuration (Enhanced with Catppuccin)
    # ==========================================================================
    home.file.".config/gtk-3.0/gtk.css".text = ''
      /* Catppuccin Mocha Nemo Customizations */
      .nemo-window {
          background-color: ${mocha.base};
          color: ${mocha.text};
      }

      .nemo-window .toolbar {
          background-color: ${mocha.mantle};
          border-bottom: 1px solid ${mocha.surface0};
      }

      .nemo-window .sidebar {
          background-color: ${mocha.mantle};
          border-right: 1px solid ${mocha.surface0};
      }

      .nemo-window .view {
          background-color: ${mocha.base};
          color: ${mocha.text};
      }

      .nemo-window .view:selected {
          background-color: ${mocha.mauve};
          color: ${mocha.base};
      }

      /* Global GTK3 Catppuccin Customizations */
      window {
          background-color: ${mocha.base};
          color: ${mocha.text};
      }

      .titlebar {
          background-color: ${mocha.mantle};
          color: ${mocha.text};
      }

      button {
          background-color: ${mocha.surface0};
          color: ${mocha.text};
          border: 1px solid ${mocha.surface1};
      }

      button:hover {
          background-color: ${mocha.surface1};
      }

      button:active {
          background-color: ${mocha.mauve};
          color: ${mocha.base};
      }

      entry {
          background-color: ${mocha.surface0};
          color: ${mocha.text};
          border: 1px solid ${mocha.surface1};
      }

      entry:focus {
          border-color: ${mocha.mauve};
      }

      .sidebar {
          background-color: ${mocha.mantle};
          color: ${mocha.text};
      }

      .sidebar:selected {
          background-color: ${mocha.mauve};
          color: ${mocha.base};
      }
    '';

    # ==========================================================================
    # GTK4 CSS Configuration
    # ==========================================================================
    home.file.".config/gtk-4.0/gtk.css".text = ''
      /* Catppuccin Mocha GTK4 Customizations */
      window {
          background-color: ${mocha.base};
          color: ${mocha.text};
      }

      .titlebar {
          background-color: ${mocha.mantle};
          color: ${mocha.text};
      }

      button {
          background-color: ${mocha.surface0};
          color: ${mocha.text};
      }

      button:hover {
          background-color: ${mocha.surface1};
      }

      button:active {
          background-color: ${mocha.mauve};
          color: ${mocha.base};
      }

      entry {
          background-color: ${mocha.surface0};
          color: ${mocha.text};
      }

      entry:focus {
          border-color: ${mocha.mauve};
      }
    '';

    # ==========================================================================
    # Systemd User Services (Enhanced)
    # ==========================================================================
    systemd.user.services = {
      # Disable GSD Power Daemon for Lid Switch
      disable-gsd-power = {
        Unit = {
          Description = "Disable GNOME Settings Daemon Power Plugin for lid switch";
          After = [ "gnome-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && ${pkgs.procps}/bin/pkill -f gsd-power || true'";
          RemainAfterExit = true;
        };
        Install = {
          WantedBy = [ "gnome-session.target" ];
        };
      };

      # Catppuccin Theme Validation Service
      catppuccin-theme-validation = {
        Unit = {
          Description = "Validate Catppuccin Mocha Theme Installation";
          After = [ "gnome-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "validate-catppuccin" ''
            #!/bin/bash
            # Check if Catppuccin theme is properly applied
            current_gtk_theme=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface gtk-theme)
            if [[ "$current_gtk_theme" == *"catppuccin-mocha"* ]]; then
              echo "✅ Catppuccin Mocha GTK theme is active"
            else
              echo "⚠️  Catppuccin Mocha GTK theme is not active: $current_gtk_theme"
            fi
            
            current_icon_theme=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface icon-theme)
            if [[ "$current_icon_theme" == *"candy-beauty"* ]]; then
              echo "✅ Candy Beauty icon theme is active"
            else
              echo "⚠️  Using default icon theme: $current_icon_theme"
            fi
          '';
          RemainAfterExit = true;
        };
        Install = {
          WantedBy = [ "gnome-session.target" ];
        };
      };
    };

    # ==========================================================================
    # Development Note for Theme Installation
    # ==========================================================================
    home.file.".config/gnome-theme-setup.md".text = ''
      # GNOME Catppuccin Mocha Theme Setup

      This NixOS configuration includes Catppuccin Mocha theme settings, but the actual theme files
      need to be installed manually or via overlays.

      ## Required Theme Files:

      ### GTK Theme:
      - Name: catppuccin-mocha-mauve-standard+normal
      - Location: ~/.themes/ or /usr/share/themes/
      - Source: https://github.com/catppuccin/gtk

      ### Icon Theme:
      - Name: a-candy-beauty-icon-theme
      - Location: ~/.icons/ or /usr/share/icons/
      - Source: Various icon theme sources

      ### Cursor Theme:
      - Name: catppuccin-mocha-dark-cursors
      - Location: ~/.icons/ or /usr/share/icons/
      - Source: https://github.com/catppuccin/cursors

      ## Installation Methods:

      1. **Manual Installation:**
         - Download themes from respective repositories
         - Extract to appropriate directories
         - Run: dconf update

      2. **NixOS Overlay (Recommended):**
         - Add Catppuccin overlay to your flake
         - Include theme packages in home.packages

      3. **Script Installation:**
         - Run the included gnome-settings.sh script
         - It will handle theme validation and setup

      ## Verification:
      - Check GTK theme: gsettings get org.gnome.desktop.interface gtk-theme
      - Check icon theme: gsettings get org.gnome.desktop.interface icon-theme
      - Check cursor theme: gsettings get org.gnome.desktop.interface cursor-theme

      ## Custom Keybindings:
      All custom keybindings from the script are included in this NixOS configuration.
      Ensure the referenced applications (walker, osc-*, gnome-mpv-manager, etc.) are installed.
    '';
  }; # config sonu
} # dosya sonu
