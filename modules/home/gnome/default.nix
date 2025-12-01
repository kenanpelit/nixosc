# modules/home/gnome/default.nix
# ==============================================================================
# GNOME Desktop Configuration
# ==============================================================================
# Comprehensive configuration for the GNOME desktop environment via dconf.
# - Interface and window manager settings
# - Shell extensions configuration
# - Custom keybindings and shortcuts
# - Terminal, Text Editor, and other app preferences
# - Power, privacy, and hardware settings
#
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  # --- Catppuccin Mocha Palette ---
  colors = {
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

  # --- Fonts ---
  fonts = {
    main = "Monaspace Neon"; 
    terminal = "Hack Nerd Font";
    size_sm = "12";
    size_md = "13";
    size_xl = "15";
  };

  # --- Custom Keybindings List ---
  # Add or remove bindings here. Nix will handle the numbering (custom0, custom1...) automatically.
  customKeybindings = [
    { name = "Terminal"; command = "kitty"; binding = "<Super>Return"; }
    { name = "Browser"; command = "brave"; binding = "<Super>b"; }
    { name = "Terminal File Manager (Floating)"; command = "kitty --class floating-terminal -e yazi"; binding = "<Super>e"; }
    { name = "Open Nemo File Manager"; command = "nemo"; binding = "<Alt><Ctrl>f"; }
    { name = "Terminal File Manager (Yazi)"; command = "kitty yazi"; binding = "<Alt>f"; }
    { name = "Open Walker"; command = "walker"; binding = "<Super><Alt>space"; }
    { name = "Switch Audio Output"; command = "osc-soundctl switch"; binding = "<Alt>a"; }
    { name = "Switch Microphone"; command = "osc-soundctl switch-mic"; binding = "<Alt><Ctrl>a"; }
    { name = "Spotify Toggle"; command = "osc-spotify"; binding = "<Alt>e"; }
    { name = "Spotify Next"; command = "osc-spotify next"; binding = "<Alt><Ctrl>n"; }
    { name = "Spotify Previous"; command = "osc-spotify prev"; binding = "<Alt><Ctrl>b"; }
    { name = "MPV Start/Focus"; command = "gnome-mpv-manager start"; binding = "<Alt>i"; }
    { name = "Lock Screen"; command = "loginctl lock-session"; binding = "<Alt>l"; }
    { name = "Previous Workspace"; command = "ws-prev"; binding = "<Super><Alt>Left"; }
    { name = "Next Workspace"; command = "ws-next"; binding = "<Super><Alt>Right"; }
    { name = "Open Discord"; command = "webcord --enable-features=UseOzonePlatform --ozone-platform=wayland"; binding = "<Super><Shift>d"; }
    { name = "Start KKENP"; command = "start-kkenp"; binding = "<Alt>t"; }
    { name = "Notes Manager"; command = "anotes -M"; binding = "<Super>n"; }
    { name = "Clipboard Manager"; command = "copyq toggle"; binding = "<Alt>v"; }
    { name = "Bluetooth Toggle"; command = "bluetooth_toggle"; binding = "F10"; }
    { name = "Mullvad Toggle"; command = "osc-mullvad toggle"; binding = "<Alt>F12"; }
    { name = "Gnome Start"; command = "semsumo launch --daily"; binding = "<Super><Alt>Return"; }
    { name = "Screenshot Full Save"; command = "screenshot sf"; binding = "Print"; }
    { name = "Screenshot Region Save"; command = "screenshot rf"; binding = "<Shift>Print"; }

    { name = "MPV Move Window"; command = "gnome-mpv-manager move"; binding = "<Alt><Shift>i"; }
    { name = "MPV Resize Center"; command = "gnome-mpv-manager resize"; binding = "<Alt><Ctrl>i"; }
    { name = "Play YouTube from Clipboard"; command = "gnome-mpv-manager play-yt"; binding = "<Alt>y"; }
    { name = "Download YouTube Video"; command = "gnome-mpv-manager save-yt"; binding = "<Alt><Shift>y"; }
    { name = "MPV Toggle Playback"; command = "gnome-mpv-manager playback"; binding = "<Alt>p"; }
    
    # Workspaces 1-9 (Using workspace-switcher wrappers for history)
    { name = "Workspace 1"; command = "workspace-switcher 1"; binding = "<Super>1"; }
    { name = "Workspace 2"; command = "workspace-switcher 2"; binding = "<Super>2"; }
    { name = "Workspace 3"; command = "workspace-switcher 3"; binding = "<Super>3"; }
    { name = "Workspace 4"; command = "workspace-switcher 4"; binding = "<Super>4"; }
    { name = "Workspace 5"; command = "workspace-switcher 5"; binding = "<Super>5"; }
    { name = "Workspace 6"; command = "workspace-switcher 6"; binding = "<Super>6"; }
    { name = "Workspace 7"; command = "workspace-switcher 7"; binding = "<Super>7"; }
    { name = "Workspace 8"; command = "workspace-switcher 8"; binding = "<Super>8"; }
    { name = "Workspace 9"; command = "workspace-switcher 9"; binding = "<Super>9"; }
    
    { name = "Shutdown Computer"; command = "gnome-session-quit --power-off --no-prompt"; binding = "<Ctrl><Alt><Shift>s"; }
    { name = "Restart Computer"; command = "gnome-session-quit --reboot --no-prompt"; binding = "<Ctrl><Alt>r"; }
    { name = "Logout"; command = "gnome-session-quit --logout --no-prompt"; binding = "<Ctrl><Alt>q"; }
    { name = "Power Menu"; command = "gnome-session-quit --power-off"; binding = "<Ctrl><Alt>p"; }
    { name = "GNOME GKR"; command = "gnome-kr-fix"; binding = "<Super><Ctrl>F12"; }
    { name = "WalkerS"; command = "walk"; binding = "<Super>space"; }
    { name = "OSC Reboot"; command = "osc-safe-reboot"; binding = "<Super>BackSpace"; }
  ];

  # Helper to generate dconf entries for custom keybindings from the list above
  customBindingsDconf = builtins.listToAttrs (lib.imap0 (i: binding: {
    name = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}";
    value = {
      name = binding.name;
      command = binding.command;
      binding = binding.binding;
    };
  }) customKeybindings);

  # The list of DConf paths to these bindings, required by GNOME media-keys plugin
  customBindingsPaths = map (i: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}/") (lib.range 0 ((builtins.length customKeybindings) - 1));

in
{
  # ==============================================================================
  # DCONF SETTINGS
  # ==============================================================================
  dconf.settings = {
    # --- Interface (Handled by modules/home/gtk/default.nix) ---
    "org/gnome/desktop/interface" = {
      show-battery-percentage = true;
      clock-show-weekday = true;
      clock-show-date = true;
      accent-color = "purple";
    };

    # --- Window Manager ---
    "org/gnome/desktop/wm/preferences" = {
      # REMOVED: button-layout = "appmenu:minimize,maximize,close"; (Conflict: User wants "appmenu" from GTK module)
      # REMOVED: theme & titlebar-font to avoid potential conflicts as well.
      
      num-workspaces = 9;
      workspace-names = ["1" "2" "3" "4" "5" "6" "7" "8" "9"];
      focus-mode = "click";
      focus-new-windows = "smart";
      auto-raise = false;
      raise-on-click = true;
    };

    # --- Shell Extensions ---
    "org/gnome/shell" = {
      enabled-extensions = [
        "alt-tab-scroll-workaround@lucasresck.github.io"
      	"audio-switch-shortcuts@dbatis.github.com"
      	"auto-move-windows@gnome-shell-extensions.gcampax.github.com"
      	"azwallpaper@azwallpaper.gitlab.com"
      	"bluetooth-quick-connect@bjarosze.gmail.com"
      	"clipboard-indicator@tudmotu.com"
      	"copyous@boerdereinar.dev"
      	"dash-to-panel@jderose9.github.com"
      	"disable-three-finger-gestures-redux@cygnusx-1-org.github.com"
      	"disable-workspace-animation@ethnarque"
      	"extension-list@tu.berry"
      	"gsconnect@andyholmes.github.io"
      	"headphone-internal-switch@gustavomalta.github.com"
      	"just-perfection-desktop@just-perfection"
      	"launcher@hedgie.tech"
      	"mediacontrols@cliffniff.github.com"
      	"no-overview@fthx"
      	"notification-configurator@exposedcat"
      	"notification-icons@jiggak.io"
      	"no-titlebar-when-maximized@alec.ninja"
      	"space-bar@luchrioh"
      	"tilingshell@ferrarodomenico.com"
      	"tophat@fflewddur.github.io"
      	"trayIconsReloaded@selfmade.pl"
      	"veil@dagimg-dot"
      	"vpn-indicator@fthx"
      	"weatheroclock@CleoMenezesJr.github.io"
      	"zetadev@bootpaper"
      ];
      favorite-apps = ["brave-browser.desktop" "kitty.desktop"];
      disabled-extensions = [];
    };

    # --- Keybindings Management ---
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = customBindingsPaths;
    };

    # --- Dash to Panel ---
    "org/gnome/shell/extensions/dash-to-panel" = {
      panel-element-positions-monitors-sync = true;
      trans-use-custom-bg = true;
      trans-bg-color = colors.base;
      trans-use-custom-opacity = true;
      trans-panel-opacity = 0.95;
      appicon-margin = 8;
      appicon-padding = 4;
      show-favorites = true;
      show-running-apps = true;
      show-window-previews = true;
      isolate-workspaces = false;
      group-apps = true;
      dot-position = "BOTTOM";
      window-preview-title-position = "TOP";
      hotkeys-overlay-combo = "TEMPORARILY";
      intellihide = false;
      # JSON configs
      # FIX: panel-positions was incorrectly set to '28' (size) instead of 'TOP'
      panel-positions = ''{"CMN-0x00000000":"TOP","DEL-KRXTR88N909L":"TOP"}''; 
      panel-sizes = ''{"CMN-0x00000000":28,"DEL-KRXTR88N909L":28}'';
      panel-lengths = ''{"CMN-0x00000000":100,"DEL-KRXTR88N909L":100}'';
      panel-anchors = ''{"CMN-0x00000000":"MIDDLE","DEL-KRXTR88N909L":"MIDDLE"}'';
    };

    # --- Tiling Shell ---
    "org/gnome/shell/extensions/tilingshell" = {
      border-color = colors.mauve;
      active-window-border-color = colors.lavender;
      enable-tiling-system = true;
      auto-tile = true;
      snap-assist = true;
      default-layout = "split";
      inner-gaps = 4;
      outer-gaps = 4;
      show-border = true;
      border-width = 2;
      enable-animations = true;
      
      # Keybindings
      tile-left = ["<Super><Shift>Left"];
      tile-right = ["<Super><Shift>Right"];
      tile-up = ["<Super><Shift>Up"];
      tile-down = ["<Super><Shift>Down"];
      toggle-tiling = ["<Super>t"];
      toggle-floating = ["<Super>f"];
      
      # Focus
      focus-left = ["<Super>Left"];
      focus-right = ["<Super>Right"];
      focus-up = ["<Super>Up"];
      focus-down = ["<Super>Down"];
    };

    # --- Space Bar ---
    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = false;
    };
    "org/gnome/shell/extensions/space-bar/appearance" = {
      application-styles = ''
        .space-bar {
          -natural-hpadding: 12px;
          background-color: ${colors.base};
        }

        .space-bar-workspace-label.active {
          margin: 0 4px;
          background-color: ${colors.mauve};
          color: ${colors.base};
          border-color: transparent;
          font-weight: 700;
          border-radius: 6px;
          border-width: 0px;
          padding: 4px 10px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }

        .space-bar-workspace-label.inactive {
          margin: 0 4px;
          background-color: ${colors.surface0};
          color: ${colors.text};
          border-color: transparent;
          font-weight: 500;
          border-radius: 6px;
          border-width: 0px;
          padding: 4px 10px;
          transition: all 0.2s ease;
        }

        .space-bar-workspace-label.inactive:hover {
          background-color: ${colors.surface1};
          color: ${colors.subtext1};
        }

        .space-bar-workspace-label.inactive.empty {
          margin: 0 4px;
          background-color: transparent;
          color: ${colors.overlay0};
          border-color: transparent;
          font-weight: 400;
          border-radius: 6px;
          border-width: 0px;
          padding: 4px 10px;
        }
      '';
    };


    # --- Text Editor ---
    "org/gnome/TextEditor" = {
      custom-font = "${fonts.main} ${fonts.size_xl}";
      style-scheme = "catppuccin-mocha";
      style-variant = "dark";
      show-line-numbers = true;
      highlight-current-line = true;
      indent-style = "space";
      tab-width = 4;
      restore-session = false;
      show-grid = false;
      show-right-margin = false;
      use-system-font = false;
      wrap-text = false;
    };

    # --- Terminal Profile (Legacy) ---
    "org/gnome/terminal/legacy/profiles:/:catppuccin-mocha" = {
      visible-name = "Catppuccin Mocha";
      background-color = colors.base;
      foreground-color = colors.text;
      use-theme-colors = false; # Set to false to use custom colors
      use-theme-transparency = false; # Set to false to use custom transparency
      use-transparent-background = true;
      background-transparency-percent = 10;
      bold-color = colors.text;
      bold-color-same-as-fg = true;
      cursor-colors-set = true;
      cursor-background-color = colors.rosewater;
      cursor-foreground-color = colors.base;
      highlight-colors-set = true;
      highlight-background-color = colors.surface2;
      highlight-foreground-color = colors.text;
      palette = [
        colors.surface1 colors.red colors.green colors.yellow colors.blue colors.pink colors.teal colors.subtext1
        colors.surface2 colors.red colors.green colors.yellow colors.blue colors.pink colors.teal colors.subtext0
      ];
    };
    
    # --- Night Light ---
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = false;
      night-light-temperature = 2800;
      night-light-schedule-from = 0.0;
      night-light-schedule-to = 0.0; # 24h in some GNOME versions
    };

    # --- Mutter ---
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = false;
      workspaces-only-on-primary = false;
      center-new-windows = true;
      focus-change-on-pointer-rest = true;
      auto-maximize = false;
      attach-modal-dialogs = true;
    };

    # --- App Switcher ---
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = false;
    };
    "org/gnome/shell/window-switcher" = {
      current-workspace-only = true;
    };

    # --- Clipboard Indicator ---
    "org/gnome/shell/extensions/clipboard-indicator" = {
      toggle-menu = ["<Super>v"];
      clear-history = []; # @as []
      prev-entry = []; # @as []
      next-entry = []; # @as []
      cache-size = 50;
      display-mode = 0;
    };

    # --- GSConnect ---
    "org/gnome/shell/extensions/gsconnect" = {
      show-indicators = true;
      show-offline = false;
    };

    # --- Bluetooth Quick Connect ---
    "org/gnome/shell/extensions/bluetooth-quick-connect" = {
      show-battery-icon-on = true;
      show-battery-value-on = true;
    };

    # --- Vitals ---
    "org/gnome/shell/extensions/vitals" = {
      hot-sensors = ["_processor_usage_" "_memory_usage_" "_network-rx_max_" "_network-tx_max_"];
      position-in-panel = 2;
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

    # --- Spotify Controls ---
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

    # --- Auto Move Windows ---
    "org/gnome/shell/extensions/auto-move-windows" = {
      application-list = [
        "brave-browser.desktop:1"
        "kitty.desktop:2"
        "discord.desktop:5"
        "webcord.desktop:5"
        "whatsie.desktop:9"
        "ferdium.desktop:9"
        "spotify.desktop:8"
        "brave-agimnkijcaahngcdmfeangaknmldooml-Default.desktop:7"
      ];
    };

    # --- Privacy ---
    "org/gnome/desktop/privacy" = {
      report-technical-problems = false;
      send-software-usage-stats = false;
      disable-microphone = false;
      disable-camera = false;
    };

    # --- Power ---
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "suspend";
      sleep-inactive-ac-timeout = 3600;
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 3600;
      power-button-action = "interactive";
      handle-lid-switch = false;
    };

    # --- Session ---
    "org/gnome/desktop/session" = {
      idle-delay = 0; # uint32 0
    };
    
    # --- Touchpad ---
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      natural-scroll = false;
      disable-while-typing = true;
      click-method = "fingers";
      send-events = "enabled";
      speed = 0.8;
      accel-profile = "default";
      scroll-method = "two-finger-scrolling";
      middle-click-emulation = false;
    };

    # --- Mouse ---
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
      speed = 0.0;
    };

    # --- Sound ---
    "org/gnome/desktop/sound" = {
      event-sounds = true;
      theme-name = "freedesktop";
    };

    # --- Screensaver ---
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 0; # uint32 0
      idle-activation-enabled = true;
    };
    
    # --- Lockdown (for lock screen) ---
    "org/gnome/desktop/lockdown" = {
      disable-lock-screen = false;
    };

    # --- Nautilus ---
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

    # --- Notifications ---
    "org/gnome/desktop/notifications" = {
      show-in-lock-screen = false;
      show-banners = true;
    };

  } // customBindingsDconf; # Merge generated custom keybindings

  # ==============================================================================
  # GNOME AUTOSTART ENTRIES
  # ==============================================================================
  # Run gnome-monitor-set only for GNOME sessions using the XDG autostart
  # mechanism. Hyprland and other desktops will ignore OnlyShowIn=GNOME.
  xdg.configFile."autostart/gnome-monitor-set.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=GNOME Monitor Set
    Comment=Set external monitor as primary on GNOME login
    Exec=gnome-monitor-set
    OnlyShowIn=GNOME;
    X-GNOME-Autostart-enabled=true
  '';
}
