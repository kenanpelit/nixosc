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
        # Mevcut yüklü extension'lar
        "clipboard-indicator@tudmotu.com"
        "dash-to-panel@jderose9.github.com"
        "alt-tab-scroll-workaround@lucasresck.github.io"
        "extension-list@tu.berry"
        "gsconnect@andyholmes.github.io"
        "simple-workspaces-bar@null-git"
        "bluetooth-quick-connect@bjarosze.gmail.com"
        "no-overview@fthx"
        "Vitals@CoreCoding.com"
        "tilingshell@ferrarodomenico.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "weatheroclock@CleoMenezesJr.github.io"
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
        
        # Mevcut extension'lar için gerekli paketler (varsa)
        # Bu extension'lar zaten yüklü olduğu için ek paket gerekmeyebilir
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

        # Workspace switching (1-9) - FIXED FOR GNOME
        switch-to-workspace-1 = ["<Super>1"];
        switch-to-workspace-2 = ["<Super>2"];
        switch-to-workspace-3 = ["<Super>3"];
        switch-to-workspace-4 = ["<Super>4"];
        switch-to-workspace-5 = ["<Super>5"];
        switch-to-workspace-6 = ["<Super>6"];
        switch-to-workspace-7 = ["<Super>7"];
        switch-to-workspace-8 = ["<Super>8"];
        switch-to-workspace-9 = ["<Super>9"];

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

        # Navigate workspaces with arrows
        switch-to-workspace-left = ["<Super><Ctrl>Left" "<Super>Page_Up"];
        switch-to-workspace-right = ["<Super><Ctrl>Right" "<Super>Page_Down"];
        switch-to-workspace-up = ["<Super><Ctrl>Up"];
        switch-to-workspace-down = ["<Super><Ctrl>Down"];

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

      # ------------------------------------------------------------------------
      # Mutter (Window Manager) Settings - Optimized for Workspace Usage
      # ------------------------------------------------------------------------
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = false;  # Fixed workspaces like Hyprland
        workspaces-only-on-primary = false;
        center-new-windows = true;
      };

      # ------------------------------------------------------------------------
      # Desktop Workspace Settings - CRITICAL for fixed workspaces
      # ------------------------------------------------------------------------
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 9;  # 9 fixed workspaces
        workspace-names = ["1" "2" "3" "4" "5" "6" "7" "8" "9"];
      };

      # ------------------------------------------------------------------------
      # Shell Settings & Extensions (Mevcut Extension'lar)
      # ------------------------------------------------------------------------
      "org/gnome/shell" = {
        favorite-apps = [
          "brave-browser.desktop"
          "kitty.desktop"
        ];
        enabled-extensions = cfg.extensions;
        disabled-extensions = []; # Mevcut extension'ları etkinleştir
      };

      # Mevcut Extension Settings (Doğru Path ve Ayarlar)
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

      "org/gnome/shell/extensions/clipboard-indicator" = {
        # Clipboard indicator ayarları
        toggle-menu = ["<Super>v"];  # Keybinding duplicate olabilir, dikkat!
        clear-history = [];
        prev-entry = [];
        next-entry = [];
        cache-size = 50;
        display-mode = 0;
      };

      "org/gnome/shell/extensions/gsconnect" = {
        # GSConnect ayarları
        show-indicators = true;
        show-offline = false;
      };

      "org/gnome/shell/extensions/simple-workspaces-bar" = {
        # Simple Workspaces Bar ayarları
        position-in-panel = "left";
        show-empty-workspaces = false;
        toggle-overview = false;
      };

      "org/gnome/shell/extensions/bluetooth-quick-connect" = {
        # Bluetooth Quick Connect ayarları
        show-battery-icon-on = true;
        show-battery-value-on = true;
      };

      "org/gnome/shell/extensions/no-overview" = {
        # No Overview - Otomatik ayar, genelde config gerektirmez
      };

      "org/gnome/shell/extensions/vitals" = {
        # Vitals system monitor ayarları
        hot-sensors = ["_processor_usage_" "_memory_usage_" "_network-rx_max_"];
        position-in-panel = 2;  # Center
        use-higher-precision = false;
        alphabetize = true;
        include-static-info = false;
      };

      "org/gnome/shell/extensions/tilingshell" = {
        # Tiling Shell ayarları (Gerçek ayarlar)
        
        # Temel tiling ayarları
        enable-tiling-system = true;
        auto-tile = true;
        snap-assist = true;
        
        # Layout ayarları
        default-layout = "split";
        inner-gaps = 4;
        outer-gaps = 4;
        
        # Keybindings (Hyprland benzeri)
        tile-left = ["<Super><Shift>Left"];
        tile-right = ["<Super><Shift>Right"];
        tile-up = ["<Super><Shift>Up"];
        tile-down = ["<Super><Shift>Down"];
        
        toggle-tiling = ["<Super>t"];
        toggle-floating = ["<Super>f"];
        
        # Window focus (Hyprland benzeri)
        focus-left = ["<Super>Left"];
        focus-right = ["<Super>Right"];
        focus-up = ["<Super>Up"];
        focus-down = ["<Super>Down"];
        
        # Layout switching
        next-layout = ["<Super>Tab"];
        prev-layout = ["<Super><Shift>Tab"];
        
        # Resize ayarları
        resize-step = 50;
        
        # Visual ayarları
        show-border = true;
        border-width = 2;
        border-color = "rgba(66, 165, 245, 0.8)";
        
        # Animation
        enable-animations = true;
        animation-duration = 150;
        
        # Advanced settings
        respect-workspaces = true;
        tile-dialogs = false;
        tile-modals = false;
        
        # Layout configurations (JSON string)
        layouts-json = ''[{"id":"Layout 1","tiles":[{"x":0,"y":0,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0,"y":0.5,"width":0.22,"height":0.5,"groups":[1,2]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[2,3]},{"x":0.78,"y":0,"width":0.22,"height":0.5,"groups":[3,4]},{"x":0.78,"y":0.5,"width":0.22,"height":0.5,"groups":[3,4]}]},{"id":"Layout 2","tiles":[{"x":0,"y":0,"width":0.22,"height":1,"groups":[1]},{"x":0.22,"y":0,"width":0.56,"height":1,"groups":[1,2]},{"x":0.78,"y":0,"width":0.22,"height":1,"groups":[2]}]},{"id":"Layout 3","tiles":[{"x":0,"y":0,"width":0.33,"height":1,"groups":[1]},{"x":0.33,"y":0,"width":0.67,"height":1,"groups":[1]}]},{"id":"Layout 4","tiles":[{"x":0,"y":0,"width":0.67,"height":1,"groups":[1]},{"x":0.67,"y":0,"width":0.33,"height":1,"groups":[1]}]}]'';
        
        # Selected layouts per workspace
        selected-layouts = [["Layout 4" "Layout 4"] ["Layout 1" "Layout 1"] ["Layout 4" "Layout 4"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"] ["Layout 1" "Layout 1"]];
        
        # System overrides (otomatik değişiklikler)
        overridden-settings = ''{"org.gnome.mutter.keybindings":{"toggle-tiled-right":"['<Super>Right']","toggle-tiled-left":"['<Super>Left']"},"org.gnome.desktop.wm.keybindings":{"maximize":"['<Super>Up']","unmaximize":"['<Super>Down', '<Alt>F5']"},"org.gnome.mutter":{"edge-tiling":"true"}}'';
        
        # Version info
        last-version-name-installed = "16.4";
      };

      "org/gnome/shell/extensions/auto-move-windows" = {
        # Auto Move Windows - Workspace Assignment
        application-list = [
          "brave-browser.desktop:1"           # Browser → Workspace 1
          "kitty.desktop:2"                   # Terminal → Workspace 2  
          "discord.desktop:4"                 # Discord → Workspace 4
          "webcord.desktop:4"                 # Webcord → Workspace 4
          "whatsie.desktop:9"                 # WhatsApp → Workspace 9
          "ferdium.desktop:9"                 # WhatsApp → Workspace 9
          "spotify.desktop:8"                 # Spotify → Workspace 8
          "brave-agimnkijcaahngcdmfeangaknmldooml-Default.desktop:7"  # Brave PWA → Workspace 7
        ];
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

      # App switcher settings
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
        binding = "<Super>space";
        command = "rofi-launcher";
        name = "Open Rofi Launcher";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
        binding = "<Alt>space";
        command = "walker";
        name = "Open Walker";
      };

      # =======================================================================
      # AUDIO & MEDIA CONTROL
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
        binding = "<Alt>a";
        command = "osc-soundctl switch";
        name = "Switch Audio Output";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8" = {
        binding = "<Alt><Ctrl>a";
        command = "osc-soundctl switch-mic";
        name = "Switch Microphone";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9" = {
        binding = "<Alt>e";
        command = "osc-spotify";
        name = "Spotify Toggle";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10" = {
        binding = "<Alt><Ctrl>n";
        command = "osc-spotify next";
        name = "Spotify Next";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11" = {
        binding = "<Alt><Ctrl>b";
        command = "osc-spotify prev";
        name = "Spotify Previous";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom12" = {
        binding = "<Alt>i";
        command = "hypr-vlc_toggle";
        name = "VLC Toggle";
      };

      # =======================================================================
      # WALLPAPER MANAGEMENT
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom13" = {
        binding = "<Super>w";
        command = "wallpaper-manager select";
        name = "Select Wallpaper";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom14" = {
        binding = "<Alt>0";
        command = "wallpaper-manager";
        name = "Random Wallpaper";
      };

      # =======================================================================
      # SYSTEM TOOLS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom15" = {
        binding = "<Alt>l";
        command = "gnome-screensaver-command -l";
        name = "Lock Screen";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom16" = {
        binding = "<Super>BackSpace";
        command = "power-menu";
        name = "Power Menu";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom17" = {
        binding = "<Super>c";
        command = "hyprpicker -a";
        name = "Color Picker";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom18" = {
        binding = "<Super>n";
        command = "swaync-client -t -sw";
        name = "Notification Center";
      };

      # =======================================================================
      # APPLICATIONS
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom19" = {
        binding = "<Super><Shift>d";
        command = "webcord --enable-features=UseOzonePlatform --ozone-platform=wayland";
        name = "Open Discord";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom20" = {
        binding = "<Alt>t";
        command = "start-kkenp";
        name = "Start KKENP";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom21" = {
        binding = "<Super>m";
        command = "anotes";
        name = "Notes Manager";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom22" = {
        binding = "<Super>v";
        command = "copyq toggle";
        name = "Clipboard Manager";
      };

      # =======================================================================
      # WORKSPACE NAVIGATION (Additional Custom)
      # =======================================================================
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom23" = {
        binding = "<Alt>n";
        command = "gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.wm.actionMoveWorkspace(Meta.MotionDirection.LEFT)'";
        name = "Previous Workspace";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom24" = {
        binding = "<Alt>Tab";
        command = "gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Main.wm.actionMoveWorkspace(Meta.MotionDirection.RIGHT)'";
        name = "Next Workspace";
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
    # Session Variables
    # ==========================================================================
    home.sessionVariables = {
      GNOME_SESSION = "1";  # Indicate GNOME session
    };
  };
}

