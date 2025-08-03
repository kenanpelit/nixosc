# modules/home/gnome/default.nix
# ==============================================================================
# GNOME Desktop Environment Configuration with Catppuccin Integration
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

  # Catppuccin dinamik renk sistemi
  inherit (config.catppuccin) flavor accent;
  colors = config.lib.catppuccin.mkColors flavor;
  
  # Dinamik tema isimlendirmesi
  themeNames = {
    gtk = "catppuccin-${flavor}-${accent}-standard+normal";
    shell = "catppuccin-${flavor}-${accent}-standard+normal";
    icon = "a-candy-beauty-icon-theme";
    cursor = "catppuccin-${flavor}-dark-cursors";
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
    # GTK Configuration with Dynamic Catppuccin
    # ==========================================================================
    gtk = {
      enable = true;
      
      # Dinamik tema ayarları
      theme = {
        name = themeNames.gtk;
        package = null; # Will be set manually or via overlay
      };
      
      iconTheme = {
        name = themeNames.icon;
        package = null; # Will be set manually
      };
      
      cursorTheme = {
        name = themeNames.cursor;
        size = 24;
        package = null; # Will be set manually
      };

      # GTK3 specific settings with dynamic colors
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-cursor-theme-name = themeNames.cursor;
        gtk-cursor-theme-size = 24;
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-icon-theme-name = themeNames.icon;
        gtk-theme-name = themeNames.gtk;
      };

      # GTK4 specific settings with dynamic colors
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-cursor-theme-name = themeNames.cursor;
        gtk-cursor-theme-size = 24;
        gtk-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        gtk-icon-theme-name = themeNames.icon;
        gtk-theme-name = themeNames.gtk;
      };
    };i

    # ==========================================================================
    # DConf Settings (Complete Configuration with Dynamic Catppuccin)
    # ==========================================================================
    dconf.settings = {
      # ------------------------------------------------------------------------
      # Text Editor Configuration (Enhanced with Dynamic Catppuccin)
      # ------------------------------------------------------------------------
      "org/gnome/TextEditor" = {
        custom-font = "${fonts.editor.family} ${toString fonts.sizes.xl}";
        highlight-current-line = true;
        indent-style = "space";
        restore-session = false;
        show-grid = false;
        show-line-numbers = true;
        show-right-margin = false;
        style-scheme = "catppuccin-${flavor}"; # Dynamic Catppuccin scheme
        style-variant = "dark";
        tab-width = "uint32 4";
        use-system-font = false;
        wrap-text = false;
      };
      
      # ------------------------------------------------------------------------
      # Interface Configuration (Dynamic Catppuccin)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/interface" = {
        # Font settings (preserved)
        font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        document-font-name = "${fonts.main.family} ${toString fonts.sizes.sm}";
        monospace-font-name = "${fonts.terminal.family} ${toString fonts.sizes.sm}";
        
        # Dynamic Catppuccin theme settings
        gtk-theme = themeNames.gtk;
        icon-theme = themeNames.icon;
        cursor-theme = themeNames.cursor;
        cursor-size = 24;
        
        # Interface settings
        color-scheme = "prefer-dark";
        font-antialiasing = "grayscale";
        font-hinting = "slight";
        show-battery-percentage = true;
        clock-show-weekday = true;
        clock-show-date = true;
        enable-animations = true;
        
        # Dynamic accent color based on Catppuccin accent
        accent-color = if accent == "mauve" then "purple"
                      else if accent == "blue" then "blue"
                      else if accent == "green" then "green"
                      else if accent == "red" then "red"
                      else if accent == "yellow" then "yellow"
                      else if accent == "pink" then "pink"
                      else "purple"; # fallback
      };

      # ------------------------------------------------------------------------
      # Shell Theme Configuration (Dynamic)
      # ------------------------------------------------------------------------
      "org/gnome/shell/extensions/user-theme" = {
        name = themeNames.shell;
      };

      # ------------------------------------------------------------------------
      # Window Manager Preferences (Enhanced)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 9;  # 9 fixed workspaces
        workspace-names = ["1" "2" "3" "4" "5" "6" "7" "8" "9"];
        
        # Dynamic theme settings
        theme = themeNames.gtk;
        titlebar-font = "${fonts.main.family} Bold ${toString fonts.sizes.sm}";
        button-layout = "appmenu:minimize,maximize,close";

        # Focus ayarları
        focus-mode = "click";
        focus-new-windows = "smart";
        auto-raise = false;
        raise-on-click = true;
      };

      # ------------------------------------------------------------------------
      # Background/Wallpaper Settings (Dynamic Catppuccin Colors)
      # ------------------------------------------------------------------------
      "org/gnome/desktop/background" = {
        # Dynamic fallback colors
        color-shading-type = "solid";
        primary-color = colors.base.hex;
        picture-options = "zoom";
        # picture-uri will be set by script if wallpaper exists
        # picture-uri-dark will be set by script if wallpaper exists
      };

      "org/gnome/desktop/screensaver" = {
        color-shading-type = "solid";
        primary-color = colors.mantle.hex;
        lock-enabled = true;
        lock-delay = "uint32 0";
        idle-activation-enabled = true;
        # picture-uri will be set by script if lockscreen wallpaper exists
      };

      # ------------------------------------------------------------------------
      # Terminal Configuration (Dynamic Catppuccin)
      # ------------------------------------------------------------------------
      "org/gnome/terminal/legacy/profiles:/:catppuccin-${flavor}" = {
        visible-name = "Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor}";
        use-theme-colors = false;
        use-theme-transparency = false;
        use-transparent-background = true;
        background-transparency-percent = 10;
        
        # Dynamic Catppuccin colors
        background-color = colors.base.hex;
        foreground-color = colors.text.hex;
        bold-color = colors.text.hex;
        bold-color-same-as-fg = true;
        cursor-colors-set = true;
        cursor-background-color = colors.rosewater.hex;
        cursor-foreground-color = colors.base.hex;
        highlight-colors-set = true;
        highlight-background-color = colors.surface2.hex;
        highlight-foreground-color = colors.text.hex;
        
        # Terminal palette (16 colors) - Dynamic
        palette = [
          colors.surface1.hex colors.red.hex colors.green.hex colors.yellow.hex
          colors.blue.hex colors.pink.hex colors.teal.hex colors.subtext1.hex
          colors.surface2.hex colors.red.hex colors.green.hex colors.yellow.hex
          colors.blue.hex colors.pink.hex colors.teal.hex colors.subtext0.hex
        ];
        
        # Font settings
        use-system-font = false;
        font = "${fonts.terminal.family} ${toString fonts.sizes.md}";
        cursor-shape = "block";
        cursor-blink-mode = "on";
        audible-bell = false;
        scrollback-unlimited = true;
      };

      # Set default terminal profile (dynamic)
      "org/gnome/terminal/legacy" = {
        default-profile = "catppuccin-${flavor}";
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
        overlay-key = "";  # Super tuşunu boşalt
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
        # Hot corner'ı kapat
        enable-hot-corners = false;           # ✅ Sol üst köşe tetiklemez
        disabled-extensions = [];
      };

      # ------------------------------------------------------------------------
      # Extension Configurations - UPDATED & OPTIMIZED with Dynamic Catppuccin
      # ------------------------------------------------------------------------
      
      # Dash to Panel - Enhanced with Dynamic Catppuccin colors
      "org/gnome/shell/extensions/dash-to-panel" = {
        # Temel panel ayarları
        appicon-margin = 8;
        appicon-padding = 4;
        show-favorites = true;
        show-running-apps = true;
        show-window-previews = true;
        isolate-workspaces = false;
        group-apps = true;
        show-overview-on-startup = false;
        
        # Panel boyut ayarları - Scripteki gibi 28px
        panel-sizes = ''{"0":28}'';
        panel-lengths = ''{"0":100}'';
        panel-positions = ''{"0":"TOP"}'';
        panel-anchors = ''{"0":"MIDDLE"}'';
        
        # Dynamic Catppuccin tema ayarları
        trans-use-custom-bg = true;
        trans-bg-color = colors.base.hex;
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
      
      # TILINGSHELL - UPDATED with Dynamic Catppuccin colors and Windows Suggestions
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
        
        # Visual ayarları - Dynamic Catppuccin renkleri
        show-border = true;
        border-width = 2;
        border-color = colors.${accent}.hex;
        active-window-border-color = colors.lavender.hex;
        
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

      # Space Bar - Enhanced Dynamic Catppuccin CSS
      "org/gnome/shell/extensions/space-bar/appearance" = {
        application-styles = ''
          .space-bar {
            -natural-hpadding: 12px;
            background-color: ${colors.base.hex};
          }

          .space-bar-workspace-label.active {
            margin: 0 4px;
            background-color: ${colors.${accent}.hex};
            color: ${colors.base.hex};
            border-color: transparent;
            font-weight: 700;
            border-radius: 6px;
            border-width: 0px;
            padding: 4px 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
          }

          .space-bar-workspace-label.inactive {
            margin: 0 4px;
            background-color: ${colors.surface0.hex};
            color: ${colors.text.hex};
            border-color: transparent;
            font-weight: 500;
            border-radius: 6px;
            border-width: 0px;
            padding: 4px 10px;
            transition: all 0.2s ease;
          }

          .space-bar-workspace-label.inactive:hover {
            background-color: ${colors.surface1.hex};
            color: ${colors.subtext1.hex};
          }

          .space-bar-workspace-label.inactive.empty {
            margin: 0 4px;
            background-color: transparent;
            color: ${colors.overlay0.hex};
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
    # Session Variables (Enhanced with Dynamic Catppuccin + System Variables)
    # ==========================================================================
    home.sessionVariables = {
      GNOME_SESSION = "1";
      
      # Dynamic Catppuccin Theme Environment Variables
      CATPPUCCIN_THEME = flavor;
      CATPPUCCIN_ACCENT = accent;
      GTK_THEME = themeNames.gtk;
      XCURSOR_THEME = themeNames.cursor;
      XCURSOR_SIZE = "24";
      
      # HiDPI cursor size adjustment
      GDK_SCALE = mkDefault "1";
      GDK_DPI_SCALE = mkDefault "1";
      
      # System Variables - ADDED
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "kitty";
      TERM = "xterm-256color";
      BROWSER = "brave";
    };

    # ==========================================================================
    # GTK CSS Configuration (Enhanced with Dynamic Catppuccin)
    # ==========================================================================
    home.file.".config/gtk-3.0/gtk.css".text = ''
      /* Dynamic Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} Nemo Customizations */
      .nemo-window {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .nemo-window .toolbar {
          background-color: ${colors.mantle.hex};
          border-bottom: 1px solid ${colors.surface0.hex};
      }

      .nemo-window .sidebar {
          background-color: ${colors.mantle.hex};
          border-right: 1px solid ${colors.surface0.hex};
      }

      .nemo-window .view {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .nemo-window .view:selected {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }

      /* Global GTK3 Dynamic Catppuccin Customizations */
      window {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .titlebar {
          background-color: ${colors.mantle.hex};
          color: ${colors.text.hex};
      }

      button {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
          border: 1px solid ${colors.surface1.hex};
      }

      button:hover {
          background-color: ${colors.surface1.hex};
      }

      button:active {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }

      entry {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
          border: 1px solid ${colors.surface1.hex};
      }

      entry:focus {
          border-color: ${colors.${accent}.hex};
      }

      .sidebar {
          background-color: ${colors.mantle.hex};
          color: ${colors.text.hex};
      }

      .sidebar:selected {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }
    '';

    # ==========================================================================
    # GTK4 CSS Configuration (Dynamic)
    # ==========================================================================
    home.file.".config/gtk-4.0/gtk.css".text = ''
      /* Dynamic Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} GTK4 Customizations */
      window {
          background-color: ${colors.base.hex};
          color: ${colors.text.hex};
      }

      .titlebar {
          background-color: ${colors.mantle.hex};
          color: ${colors.text.hex};
      }

      button {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
      }

      button:hover {
          background-color: ${colors.surface1.hex};
      }

      button:active {
          background-color: ${colors.${accent}.hex};
          color: ${colors.base.hex};
      }

      entry {
          background-color: ${colors.surface0.hex};
          color: ${colors.text.hex};
      }

      entry:focus {
          border-color: ${colors.${accent}.hex};
      }
    '';

    # ==========================================================================
    # Systemd User Services (Enhanced) - TEMPORARILY DISABLED FOR PERFORMANCE
    # ==========================================================================
    systemd.user.services = {
     # NOTE: These services are commented out to improve GNOME startup time
     # They were causing ~8-10 second delay during login
     
     # Disable GSD Power Daemon for Lid Switch
     # disable-gsd-power = {
     #   Unit = {
     #     Description = "Disable GNOME Settings Daemon Power Plugin for lid switch";
     #     After = [ "gnome-session.target" ];
     #   };
     #   Service = {
     #     Type = "oneshot";
     #     ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && ${pkgs.procps}/bin/pkill -f gsd-power || true'";
     #     RemainAfterExit = true;
     #   };
     #   Install = {
     #     WantedBy = [ "gnome-session.target" ];
     #   };
     # };
     
     # Dynamic Catppuccin Theme Validation Service
     # catppuccin-theme-validation = {
     #   Unit = {
     #     Description = "Validate Dynamic Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} ${lib.strings.toUpper (lib.substring 0 1 accent)}${lib.substring 1 (-1) accent} Theme Installation";
     #     After = [ "gnome-session.target" ];
     #   };
     #   Service = {
     #     Type = "oneshot";
     #     ExecStart = pkgs.writeShellScript "validate-catppuccin" ''
     #       #!/bin/bash
     #       # Check if Dynamic Catppuccin theme is properly applied
     #       current_gtk_theme=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface gtk-theme)
     #       expected_theme="catppuccin-${flavor}-${accent}"
     #       if [[ "$current_gtk_theme" == *"$expected_theme"* ]]; then
     #         echo "✅ Dynamic Catppuccin ${lib.strings.toUpper (lib.substring 0 1 flavor)}${lib.substring 1 (-1) flavor} ${lib.strings.toUpper (lib.substring 0 1 accent)}${lib.substring 1 (-1) accent} GTK theme is active"
     #       else
     #         echo "⚠️  Dynamic Catppuccin theme is not active: $current_gtk_theme"
     #         echo "Expected: $expected_theme"
     #       fi
     #       
     #       current_icon_theme=$(${pkgs.glib}/bin/gsettings get org.gnome.desktop.interface icon-theme)
     #       if [[ "$current_icon_theme" == *"candy-beauty"* ]]; then
     #         echo "✅ Candy Beauty icon theme is active"
     #       else
     #         echo "⚠️  Using default icon theme: $current_icon_theme"
     #       fi
     #       
     #       echo "🎨 Current flavor: ${flavor}"
     #       echo "🎯 Current accent: ${accent}"
     #     '';
     #     RemainAfterExit = true;
     #   };
     #   Install = {
     #     WantedBy = [ "gnome-session.target" ];
     #   };
     # };
    };

    # ==========================================================================
    # Development Note for Dynamic Theme Installation
    # ==========================================================================
  }; # config sonu
} # dosya sonu
