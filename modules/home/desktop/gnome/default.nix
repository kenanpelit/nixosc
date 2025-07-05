# modules/home/desktop/gnome/default.nix
# ==============================================================================
# GNOME Desktop Environment Configuration - Complete Edition
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
      ];
      description = "List of GNOME Shell extension UUIDs to enable by default";
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
        
        # Additional useful applications
        cheese                      # Webcam application
        totem                       # Video player
        snapshot                    # Camera app
        loupe                       # Modern image viewer
        
        # Extra tools for custom keybindings
        copyq                       # Clipboard manager
        kitty                       # Terminal for keybindings
        nemo                        # Alternative file manager
      ]
    );

    # ==========================================================================
    # DConf Settings (Complete Configuration)
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
        
        # Additional interface settings
        color-scheme = "prefer-dark";
        font-antialiasing = "grayscale";
        font-hinting = "slight";
        show-battery-percentage = true;
        clock-show-weekday = true;
        clock-show-date = true;
        enable-animations = true;
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

        # Window movement within workspace - Hyprland style
        move-window-left = ["<Super><Alt>Left" "<Super><Alt>h"];
        move-window-right = ["<Super><Alt>Right" "<Super><Alt>l"];
        move-window-up = ["<Super><Alt>Up" "<Super><Alt>k"];
        move-window-down = ["<Super><Alt>Down" "<Super><Alt>j"];
      };

      # Shell keybindings - Mevcut ayarlar korundu
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
      # Mutter (Window Manager) Settings - Optimized for Workspace Usage
      # ------------------------------------------------------------------------
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = false;
        workspaces-only-on-primary = false;
        center-new-windows = true;
  
        # Focus ayarları - YENİ
        focus-change-on-pointer-rest = true;
        auto-maximize = false;
        attach-modal-dialogs = true;
      };

      # ------------------------------------------------------------------------
      # Desktop Workspace Settings - CRITICAL for fixed workspaces
      # ------------------------------------------------------------------------
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 9;  # 9 fixed workspaces
        workspace-names = ["1" "2" "3" "4" "5" "6" "7" "8" "9"];

        # Focus ayarları - YENİ
        focus-mode = "click";
        focus-new-windows = "smart";
        auto-raise = false;
        raise-on-click = true;
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
      # Extension Configurations - UPDATED & OPTIMIZED
      # ------------------------------------------------------------------------
      
      # Dash to Panel - Mevcut ayarlar korundu
      "org/gnome/shell/extensions/dash-to-panel" = {
        # Temel panel ayarları
        appicon-margin = 8;
        appicon-padding = 4;
        show-favorites = true;
        show-running-apps = true;
        show-window-previews = true;
        isolate-workspaces = false;
        group-apps = true;
        
        # Panel pozisyon ve boyut (JSON string olarak)
        panel-positions = ''{"CMN-0x00000000":"TOP","DEL-KRXTR88N909L":"TOP"}'';
        panel-sizes = ''{"CMN-0x00000000":22,"DEL-KRXTR88N909L":22}'';
        panel-lengths = ''{"CMN-0x00000000":100,"DEL-KRXTR88N909L":100}'';
        
        # Panel element pozisyonları (mevcut ayarları korur)
        panel-element-positions = ''{"CMN-0x00000000":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"DEL-KRXTR88N909L":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"centered"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'';
        
        # Panel anchor (ortalama)
        panel-anchors = ''{"CMN-0x00000000":"MIDDLE","DEL-KRXTR88N909L":"MIDDLE"}'';
        
        # Diğer ayarlar
        dot-position = "BOTTOM";
        window-preview-title-position = "TOP";
        hotkeys-overlay-combo = "TEMPORARILY";
        
        # Animasyon ayarları
        animate-appicon-hover-animation-extent = "{'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}";
      };

      # Clipboard Indicator - Mevcut ayarlar korundu
      "org/gnome/shell/extensions/clipboard-indicator" = {
        toggle-menu = ["<Super>v"];  # Clipboard manager keybinding ile çakışır, custom keybinding kullanılıyor
        clear-history = [];
        prev-entry = [];
        next-entry = [];
        cache-size = 50;
        display-mode = 0;
      };

      # GSConnect - Mevcut ayarlar korundu
      "org/gnome/shell/extensions/gsconnect" = {
        show-indicators = true;
        show-offline = false;
      };

      # Bluetooth Quick Connect - Mevcut ayarlar korundu
      "org/gnome/shell/extensions/bluetooth-quick-connect" = {
        show-battery-icon-on = true;
        show-battery-value-on = true;
      };

      # No Overview - Minimal config
      "org/gnome/shell/extensions/no-overview" = {
        # No Overview - Otomatik ayar, genelde config gerektirmez
      };

      # VITALS - UPDATED: Network TX eklendi + optimizasyonlar
      "org/gnome/shell/extensions/vitals" = {
        # GÜNCELLENMIŞ: RX + TX network monitoring
        hot-sensors = ["_processor_usage_" "_memory_usage_" "_network-rx_max_" "_network-tx_max_"];
        position-in-panel = 2;  # Center
        use-higher-precision = false;
        alphabetize = true;
        include-static-info = false;
        
        # YENİ: Ek optimizasyonlar
        show-icons = true;          # Sensor ikonlarını göster
        show-battery = true;        # Batarya bilgisini göster (laptop için)
        unit-fahrenheit = false;    # Celsius kullan
        memory-measurement = 0;     # Percentage olarak göster
        network-speed-format = 1;   # Bit/s formatında
        storage-measurement = 0;    # Percentage olarak göster
        hide-zeros = true;          # Sıfır değerleri gizle (temiz görünüm)
        menu-centered = false;      # Menu konumu
      };

      # TILINGSHELL - UPDATED: Windows Suggestions özelliği eklendi
      "org/gnome/shell/extensions/tilingshell" = {
        # Temel tiling ayarları (mevcut)
        enable-tiling-system = true;
        auto-tile = true;
        snap-assist = true;
        
        # Layout ayarları (mevcut)
        default-layout = "split";
        inner-gaps = 4;
        outer-gaps = 4;
        
        # YENİ: Windows Suggestions özelliği (2024-2025 güncellemesi)
        enable-window-suggestions = true;           # Ana özellik aktif
        window-suggestions-for-snap-assist = true; # Snap Assistant için öneriler
        window-suggestions-for-edge-tiling = true; # Edge tiling için öneriler
        window-suggestions-for-keybinding = true;  # Keybinding tiling için öneriler
        
        # YENİ: Suggestions ayarları
        suggestions-timeout = 3000;                # 3 saniye göster
        max-suggestions-to-show = 6;               # Maksimum 6 öneri göster
        enable-suggestions-scroll = true;          # Çok öneri varsa scroll
        
        # Keybindings (mevcut korundu)
        tile-left = ["<Super><Shift>Left"];
        tile-right = ["<Super><Shift>Right"];
        tile-up = ["<Super><Shift>Up"];
        tile-down = ["<Super><Shift>Down"];
        
        toggle-tiling = ["<Super>t"];
        toggle-floating = ["<Super>f"];
        
        # Window focus (mevcut korundu)
        focus-left = ["<Super>Left"];
        focus-right = ["<Super>Right"];
        focus-up = ["<Super>Up"];
        focus-down = ["<Super>Down"];

        # Focus ayarları ekle:
        auto-focus-on-tile = true;        # Tile edildiğinde focus al
        focus-follows-mouse = false;      # Mouse focus'u kapat (karışıklık olmasın)
        respect-focus-hints = true;       # Uygulama focus taleplerini dinle

        # Layout switching (mevcut korundu)
        next-layout = ["<Super>Tab"];
        prev-layout = ["<Super><Shift>Tab"];
        
        # Resize ayarları (mevcut korundu)
        resize-step = 50;
        
        # Visual ayarları (mevcut korundu)
        show-border = true;
        border-width = 2;
        border-color = "rgba(66, 165, 245, 0.8)";
        
        # Animation (mevcut korundu)
        enable-animations = true;
        animation-duration = 150;
        
        # Advanced settings (mevcut korundu)
        respect-workspaces = true;
        tile-dialogs = false;
        tile-modals = false;
        
        # Layout configurations (mevcut korundu)
        layouts-json = ''[{"id":"Layout 1","tiles":[{"x":0,"y":0,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0,"y":0.5,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[2,3]},{"x":0.78,"y":0,"width":0.22,"height":0.5,"groups":[3,4]},{"x":0.78,"y":0.5,"width":0.22,"height":0.5,"groups":[3,4]}]},{"id":"Layout 2","tiles":[{"x":0,"y":0,"width":0.22,"height":1,"groups":[1]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[1,2]},{"x":0.78,"y":0,"width":0.22,"height":1,"groups":[2]}]},{"id":"Layout 3","tiles":[{"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},{"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}]},{"id":"Layout 4","tiles":[{"x":0,"y":0,"width":0.67,"height":1,"groups":[1]},{"x":0.67,"y":0,"width":0.33,"height":1,"groups":[1]}]}]'';
        
        # Selected layouts per workspace (mevcut korundu)
        selected-layouts = [["Layout 4" "Layout 4"] ["Layout 1" "Layout 1"] ["Layout 4" "Layout 4"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"]];
        
        # System overrides (mevcut korundu)
        overridden-settings = ''{"org.gnome.mutter.keybindings":{"toggle-tiled-right":"['<Super>Right']","toggle-tiled-left":"['<Super>Left']"},"org.gnome.desktop.wm.keybindings":{"maximize":"['<Super>Up']","unmaximize":"['<Super>Down', '<Alt>F5']"},"org.gnome.mutter":{"edge-tiling":"true"}}'';
        
        # Version info (mevcut korundu)
        last-version-name-installed = "16.4";
      };

      # SPOTIFY CONTROLS - UPDATED: Doğru UUID + kompakt mod
      "org/gnome/shell/extensions/spotify-controls" = {
        show-track-info = false;           # Mevcut ayarınız korundu
        position = "middle-right";         # Mevcut ayarınız korundu
        show-notifications = true;         # Bildirimler aktif
        track-length = 30;                # Track adı uzunluğu
        show-pause-icon = true;           # Pause ikonu
        show-next-icon = true;            # Next ikonu
        show-prev-icon = true;            # Previous ikonu
        button-color = "default";         # Düğme rengi
        hide-on-no-spotify = true;        # Spotify kapalıyken gizle
        
        # YENİ: Kompakt mod ve optimizasyonlar
        show-volume-control = false;      # Ses kontrolü gösterme (daha temiz panel)
        show-album-art = false;          # Album kapağı gösterme (küçük panel için)
        compact-mode = true;             # Kompakt mod (daha az yer kaplar)
      };

      # Space Bar - Mevcut CSS korundu
      "org/gnome/shell/extensions/space-bar/appearance" = {
        application-styles = ''
          .space-bar {
            -natural-hpadding: 12px;
          }

          .space-bar-workspace-label.active {
            margin: 0 4px;
            background-color: rgba(255,255,255,0.3);
            color: rgba(255,255,255,1);
            border-color: rgba(0,0,0,0);
            font-weight: 700;
            border-radius: 4px;
            border-width: 0px;
            padding: 3px 8px;
          }

          .space-bar-workspace-label.inactive {
            margin: 0 4px;
            background-color: rgba(0,0,0,0);
            color: rgba(255,255,255,1);
            border-color: rgba(0,0,0,0);
            font-weight: 700;
            border-radius: 4px;
            border-width: 0px;
            padding: 3px 8px;
          }

          .space-bar-workspace-label.inactive.empty {
            margin: 0 4px;
            background-color: rgba(0,0,0,0);
            color: rgba(255,255,255,0.5);
            border-color: rgba(0,0,0,0);
            font-weight: 700;
            border-radius: 4px;
            border-width: 0px;
            padding: 3px 8px;
          }
        '';
      };

      # Auto Move Windows - Mevcut ayarlar korundu
      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "brave-browser.desktop:1"           # Browser → Workspace 1
          "kitty.desktop:2"                   # Terminal → Workspace 2  
          "discord.desktop:5"                 # Discord → Workspace 5
          "webcord.desktop:5"                 # Webcord → Workspace 5
          "whatsie.desktop:9"                 # WhatsApp → Workspace 9
          "ferdium.desktop:9"                 # WhatsApp → Workspace 9
          "spotify.desktop:8"                 # Spotify → Workspace 8
          "brave-agimnkijcaahngcdmfeangaknmldooml-Default.desktop:7"  # Brave PWA → Workspace 7
        ];
      };
       
      # App switcher settings - Mevcut ayarlar korundu
      "org/gnome/shell/app-switcher" = {
        current-workspace-only = false;  # Show apps from all workspaces
      };

      "org/gnome/shell/window-switcher" = {
        current-workspace-only = true;   # Show windows from current workspace only
      };

      # ------------------------------------------------------------------------
      # Custom Keybindings - Hyprland Inspired Complete Set
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
      # TERMINAL EMULATORS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>Return";
        command = "kitty";
        name = "Open Terminal (Kitty)";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Alt>Return";
        command = "kitty --class=floating-kitty";
        name = "Open Floating Terminal";
      };

      # =======================================================================
      # FILE MANAGERS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Super>e";
        command = "nautilus";
        name = "Open File Manager";
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
        binding = "<Alt>n";
        command = "bash -c 'current=$(wmctrl -d | grep \"*\" | awk \"{print \\$1}\"); if [ $current -gt 0 ]; then wmctrl -s $((current - 1)); fi'";
        name = "Previous Workspace";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14" = {
        binding = "<Alt>Tab";
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
      # WORKSPACE SWITCHING WITH HISTORY SUPPORT
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

      # Shutdown (Güçlü kombinasyon)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom37" = {
        binding = "<Ctrl><Alt><Shift>s";
        command = "gnome-session-quit --power-off --no-prompt";
        name = "Shutdown Computer";
      };

      # Restart (Güçlü kombinasyon)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom38" = {
        binding = "<Ctrl><Alt><Shift>r";
        command = "gnome-session-quit --reboot --no-prompt";
        name = "Restart Computer";
      };

      # Logout (Daha kolay erişim)
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom39" = {
        binding = "<Ctrl><Alt>q";
        command = "gnome-session-quit --logout --no-prompt";
        name = "Logout";
      };

      # Power Menu (Seçenekli)
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
      # Power Settings - UPDATED with Lid Close Action
      # ------------------------------------------------------------------------
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "suspend";
        sleep-inactive-ac-timeout = 3600; # 60 minutes
        sleep-inactive-battery-type = "suspend";
        sleep-inactive-battery-timeout = 3600; # 30 minutes
        power-button-action = "interactive";
        handle-lid-switch = false;
      };

      # ------------------------------------------------------------------------
      # Session Settings - Screen Blank Disabled
      # ------------------------------------------------------------------------
      "org/gnome/desktop/session" = {
        idle-delay = 0; # Screen blank DISABLED (changed from 15 minutes)
      };

      ## ------------------------------------------------------------------------
      ## Screensaver Settings - Keep lock but no auto-activation
      ## ------------------------------------------------------------------------
      #"org/gnome/desktop/screensaver" = {
      #  lock-enabled = true;
      #  lock-delay = 0;
      #  idle-activation-enabled = false; # Screensaver auto-activation DISABLED
      #};

      # ------------------------------------------------------------------------
      # Touchpad Settings - Traditional Scrolling + Faster Speed
      # ------------------------------------------------------------------------
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
        natural-scroll = false;  # Traditional scrolling (yukarı kaydır = yukarı git)
        disable-while-typing = true;
        click-method = "fingers";  # Two-finger right click
        send-events = "enabled";
        speed = 0.8;  # Biraz daha hızlı (0.0'dan 0.8'e)
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
    # Fix GSD Power Daemon for Lid Switch (Disable to let systemd handle)
    # ==========================================================================
    systemd.user.services.disable-gsd-power = {
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

    # ==========================================================================
    # Session Variables
    # ==========================================================================
    home.sessionVariables = {
      GNOME_SESSION = "1";  # Indicate GNOME session
    };
  };
}
