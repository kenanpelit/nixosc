# modules/home/cosmic/default.nix
# ==============================================================================
# COSMIC Desktop Environment - User Configuration
# ==============================================================================
#
# Module: modules/home/cosmic
# Author: Kenan Pelit  
# Date:   2025-10-02
#
# Purpose: User-level COSMIC desktop customization
#
# Scope:
#   - Keyboard shortcuts (custom bindings)
#   - XKB keyboard layout (Turkish F)
#   - Panel and dock appearance
#   - Terminal, file manager settings
#   - Workspace configuration (9 workspaces)
#
# Out of Scope (handled elsewhere):
#   - COSMIC installation: modules/core/display (services.desktopManager.cosmic)
#   - Portal configuration: modules/core/display (xdg.portal.config.cosmic)
#   - System-wide settings: NixOS configuration
#
# Design Philosophy:
#   - Minimal package installation (system provides core COSMIC apps)
#   - Low-priority session variables (allow other DEs to override)
#   - RON format for COSMIC-native configs
#   - JSON format for cross-platform configs
#
# COSMIC Beta Note:
#   - Some settings may change in future releases
#   - Config file locations are stable as of Beta 1
#   - Custom shortcuts use CosmicSettings.Shortcuts path
#
# ==============================================================================

{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # Session Environment Variables
  # ============================================================================
  # Using lib.mkDefault for low priority - allows other desktop modules to override
  # This prevents conflicts when switching between GNOME/Hyprland/COSMIC
  
  home.sessionVariables = {
    # Wayland-specific settings
    MOZ_ENABLE_WAYLAND = "1";           # Firefox Wayland support
    SDL_VIDEODRIVER = lib.mkDefault "wayland";  # SDL apps use Wayland
    
    # COSMIC-specific features
    COSMIC_DATA_CONTROL_ENABLED = "1";  # Clipboard/data control
    NIXOS_OZONE_WL = "1";               # Chromium/Electron Wayland

    # Cursor settings
    XCURSOR_SIZE = "24";                # Cursor size (default: 32)
    XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
  };
  
  # Note: QT_QPA_PLATFORM and GDK_BACKEND are managed by qt and gtk modules
  # This prevents conflicts and ensures consistent behavior across all desktops

  # ============================================================================
  # COSMIC Configuration Files
  # ============================================================================
  # Config files are placed in ~/.config/cosmic/
  # Format: RON (Rusty Object Notation) for COSMIC-native configs
  #         JSON for cross-platform compatibility
  
  xdg.configFile = {
    
    # ==========================================================================
    # Keyboard Layout Configuration (RON format)
    # ==========================================================================
    # XKB configuration for input handling
    
    "cosmic/com.system76.CosmicComp/v1/xkb_config" = {
      text = ''
        (
          rules: "",
          model: "",
          layout: "tr",                    // Turkish keyboard layout
          variant: "f",                    // F-type variant (ergonomic)
          options: Some("ctrl:nocaps"),   // Caps Lock → Control
        )
      '';
    };

    # ==========================================================================
    # Default Keyboard Shortcuts Override (RON format)
    # ==========================================================================
    # Override COSMIC's default keybindings
    # This replaces the system defaults at /run/current-system/sw/share/cosmic/.../defaults
    # Critical: Print key must be bound to our screenshot script
    
    "cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults" = {
      text = ''
        {
            (modifiers: [Super, Alt], key: "Escape"): Terminate,
            (modifiers: [Super, Shift], key: "Escape"): System(LogOut),
            (modifiers: [Super, Ctrl], key: "Escape"): Debug,
            (modifiers: [Super], key: "Escape"): System(LockScreen),
            (modifiers: [Super], key: "q"): Close,

            (modifiers: [Super], key: "Left"): Focus(Left),
            (modifiers: [Super], key: "Right"): Focus(Right),
            (modifiers: [Super], key: "Up"): Focus(Up),
            (modifiers: [Super], key: "Down"): Focus(Down),
            (modifiers: [Super], key: "h"): Focus(Left),
            (modifiers: [Super], key: "j"): Focus(Down),
            (modifiers: [Super], key: "k"): Focus(Up),
            (modifiers: [Super], key: "l"): Focus(Right),
            (modifiers: [Super], key: "u"): Focus(Out),
            (modifiers: [Super], key: "i"): Focus(In),
            (modifiers: [Super, Shift], key: "Left"): Move(Left),
            (modifiers: [Super, Shift], key: "Right"): Move(Right),
            (modifiers: [Super, Shift], key: "Up"): Move(Up),
            (modifiers: [Super, Shift], key: "Down"): Move(Down),
            (modifiers: [Super, Shift], key: "h"): Move(Left),
            (modifiers: [Super, Shift], key: "j"): Move(Down),
            (modifiers: [Super, Shift], key: "k"): Move(Up),
            (modifiers: [Super, Shift], key: "l"): Move(Right),

            (modifiers: [Super], key: "1"): Workspace(1),
            (modifiers: [Super], key: "2"): Workspace(2),
            (modifiers: [Super], key: "3"): Workspace(3),
            (modifiers: [Super], key: "4"): Workspace(4),
            (modifiers: [Super], key: "5"): Workspace(5),
            (modifiers: [Super], key: "6"): Workspace(6),
            (modifiers: [Super], key: "7"): Workspace(7),
            (modifiers: [Super], key: "8"): Workspace(8),
            (modifiers: [Super], key: "9"): Workspace(9),
            (modifiers: [Super], key: "0"): LastWorkspace,
            (modifiers: [Super, Shift], key: "1"): MoveToWorkspace(1),
            (modifiers: [Super, Shift], key: "2"): MoveToWorkspace(2),
            (modifiers: [Super, Shift], key: "3"): MoveToWorkspace(3),
            (modifiers: [Super, Shift], key: "4"): MoveToWorkspace(4),
            (modifiers: [Super, Shift], key: "5"): MoveToWorkspace(5),
            (modifiers: [Super, Shift], key: "6"): MoveToWorkspace(6),
            (modifiers: [Super, Shift], key: "7"): MoveToWorkspace(7),
            (modifiers: [Super, Shift], key: "8"): MoveToWorkspace(8),
            (modifiers: [Super, Shift], key: "9"): MoveToWorkspace(9),
            (modifiers: [Super, Shift], key: "0"): MoveToLastWorkspace,

            (modifiers: [Super, Ctrl], key: "Left"): PreviousWorkspace,
            (modifiers: [Super, Ctrl], key: "Down"): NextWorkspace,
            (modifiers: [Super, Ctrl], key: "Up"): PreviousWorkspace,
            (modifiers: [Super, Ctrl], key: "Right"): NextWorkspace,
            (modifiers: [Super, Ctrl], key: "h"): PreviousWorkspace,
            (modifiers: [Super, Ctrl], key: "j"): NextWorkspace,
            (modifiers: [Super, Ctrl], key: "k"): PreviousWorkspace,
            (modifiers: [Super, Ctrl], key: "l"): NextWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "Left"): MoveToPreviousWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "Down"): MoveToNextWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "Up"): MoveToPreviousWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "Right"): MoveToNextWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "h"): MoveToPreviousWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "j"): MoveToNextWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "k"): MoveToPreviousWorkspace,
            (modifiers: [Super, Shift, Ctrl], key: "l"): MoveToNextWorkspace,

            (modifiers: [Super, Alt], key: "Left"): SwitchOutput(Left),
            (modifiers: [Super, Alt], key: "Down"): SwitchOutput(Down),
            (modifiers: [Super, Alt], key: "Up"): SwitchOutput(Up),
            (modifiers: [Super, Alt], key: "Right"): SwitchOutput(Right),
            (modifiers: [Super, Alt], key: "h"): SwitchOutput(Left),
            (modifiers: [Super, Alt], key: "k"): SwitchOutput(Up),
            (modifiers: [Super, Alt], key: "j"): SwitchOutput(Down),
            (modifiers: [Super, Alt], key: "l"): SwitchOutput(Right),
            (modifiers: [Super, Shift, Alt], key: "Left"): MoveToOutput(Left),
            (modifiers: [Super, Shift, Alt], key: "Down"): MoveToOutput(Down),
            (modifiers: [Super, Shift, Alt], key: "Up"): MoveToOutput(Up),
            (modifiers: [Super, Shift, Alt], key: "Right"): MoveToOutput(Right),
            (modifiers: [Super, Shift, Alt], key: "h"): MoveToOutput(Left),
            (modifiers: [Super, Shift, Alt], key: "k"): MoveToOutput(Up),
            (modifiers: [Super, Shift, Alt], key: "j"): MoveToOutput(Down),
            (modifiers: [Super, Shift, Alt], key: "l"): MoveToOutput(Right),

            (modifiers: [Super], key: "o"): ToggleOrientation,
            (modifiers: [Super], key: "s"): ToggleStacking,
            (modifiers: [Super], key: "y"): ToggleTiling,
            (modifiers: [Super], key: "g"): ToggleWindowFloating,
            (modifiers: [Super], key: "x"): SwapWindow,

            (modifiers: [Super], key: "m"): Maximize,
            (modifiers: [Super], key: "F11"): Fullscreen,
            (modifiers: [Super], key: "r"): Resizing(Outwards),
            (modifiers: [Super, Shift], key: "r"): Resizing(Inwards),

            (modifiers: [Super], key: "equal"): ZoomIn,
            (modifiers: [Super], key: "minus"): ZoomOut,
            (modifiers: [Super], key: "period"): ZoomIn,
            (modifiers: [Super], key: "comma"): ZoomOut,

            (modifiers: [Super], key: "b"): System(WebBrowser),
            (modifiers: [Super], key: "f"): System(HomeFolder),
            (modifiers: [Super], key: "space"): System(InputSourceSwitch),
            (modifiers: [Super], key: "t"): System(Terminal),

            (modifiers: [Super], key: "a"): System(AppLibrary),
            (modifiers: [Super], key: "w"): System(WorkspaceOverview),
            (modifiers: [Super], key: "slash"): System(Launcher),
            (modifiers: [Super]): System(Launcher),
            (modifiers: [Alt], key: "Tab"): System(WindowSwitcher),
            (modifiers: [Alt, Shift], key: "Tab"): System(WindowSwitcherPrevious),
            (modifiers: [Super], key: "Tab"): System(WindowSwitcher),
            (modifiers: [Super, Shift], key: "Tab"): System(WindowSwitcherPrevious),

            (modifiers: [], key: "Print"): System(Screenshot),
            (modifiers: [], key: "XF86AudioRaiseVolume"): System(VolumeRaise),
            (modifiers: [], key: "XF86AudioLowerVolume"): System(VolumeLower),
            (modifiers: [], key: "XF86AudioMute"): System(Mute),
            (modifiers: [], key: "XF86AudioMicMute"): System(MuteMic),
            (modifiers: [], key: "XF86MonBrightnessUp"): System(BrightnessUp),
            (modifiers: [], key: "XF86MonBrightnessDown"): System(BrightnessDown),
            (modifiers: [], key: "XF86AudioPlay"): System(PlayPause),
            (modifiers: [], key: "XF86AudioPrev"): System(PlayPrev),
            (modifiers: [], key: "XF86AudioNext"): System(PlayNext),
            (modifiers: [], key: "XF86PowerOff"): System(PowerOff),
            (modifiers: [], key: "XF86TouchpadToggle"): System(TouchpadToggle),
        }
      '';
    };

    # ==========================================================================
    # System Actions Override (RON format)
    # ==========================================================================
    # Override COSMIC's default Screenshot action to use our custom script
    # This file overrides /run/current-system/sw/share/cosmic/.../system_actions
    
    "cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions" = {
      text = ''
        {
            AppLibrary: "cosmic-app-library",
            BrightnessDown: "busctl --user call com.system76.CosmicSettingsDaemon /com/system76/CosmicSettingsDaemon com.system76.CosmicSettingsDaemon DecreaseDisplayBrightness",
            BrightnessUp: "busctl --user call com.system76.CosmicSettingsDaemon /com/system76/CosmicSettingsDaemon com.system76.CosmicSettingsDaemon IncreaseDisplayBrightness",
            InputSourceSwitch: "busctl --user call com.system76.CosmicSettingsDaemon /com/system76/CosmicSettingsDaemon com.system76.CosmicSettingsDaemon InputSourceSwitch",
            HomeFolder: "xdg-open ~",
            LogOut: "cosmic-osd log-out",
            Launcher: "cosmic-launcher",
            LockScreen: "loginctl lock-session",
            Mute: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
            MuteMic: "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
            PlayPause: "playerctl play-pause",
            PlayNext: "playerctl next",
            PlayPrev: "playerctl previous",
            PowerOff: "cosmic-osd shutdown",
            Screenshot: "screenshot ri",
            Terminal: "kitty",
            TouchpadToggle: "cosmic-osd touchpad",
            VolumeLower: "busctl --user call com.system76.CosmicSettingsDaemon /com/system76/CosmicSettingsDaemon com.system76.CosmicSettingsDaemon VolumeDown",
            VolumeRaise: "busctl --user call com.system76.CosmicSettingsDaemon /com/system76/CosmicSettingsDaemon com.system76.CosmicSettingsDaemon VolumeUp",
            WebBrowser: "brave",
            WindowSwitcher: "cosmic-launcher alt-tab",
            WindowSwitcherPrevious: "cosmic-launcher shift-alt-tab",
            WorkspaceOverview: "cosmic-workspaces",
        }
      '';
    };
    # Custom bindings added here - system defaults remain unchanged
    # Format: (modifiers, key, description) : Action
    #
    # Available modifiers: Super, Shift, Ctrl, Alt
    # Actions: Spawn("command args") for launching programs
    #
    # System shortcuts (built-in, not listed here):
    #   - Super+1-9: Switch to workspace 1-9
    #   - Super+Shift+1-9: Move window to workspace 1-9
    #   - Super+Arrow: Focus window in direction
    #   - Super+Shift+Arrow: Move window in direction
    #   - Super+Escape: Power menu
    #   - Alt+Tab: Window switcher
    
    "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
      text = ''
        {
            (
                modifiers: [Super],
                key: "v",
                description: Some("Clipboard Manager"),
            ): Spawn("copyq toggle"),
            
            (
                modifiers: [Super],
                key: "Return",
                description: Some("Terminal - Kitty"),
            ): Spawn("kitty"),
            
            (
                modifiers: [Super],
                key: "e",
                description: Some("File Manager"),
            ): Spawn("cosmic-files"),
            
            (
                modifiers: [Super],
                key: "b",
                description: Some("Browser"),
            ): Spawn("brave"),
            
            (
                modifiers: [Alt],
                key: "F9",
                description: Some("Screenshot Window Interactive"),
            ): Spawn("sh -c 'screenshot ri'"),
            
            (
                modifiers: [Shift],
                key: "F9",
                description: Some("Screenshot Full Screen to File"),
            ): Spawn("sh -c 'screenshot rec'"),

            (
                modifiers: [],
                key: "F10",
                description: Some("Bluetooth Toggle"),
            ): Spawn("sh -c 'bluetooth_toggle'"),

            (
                modifiers: [Super],
                key: "n",
                description: Some("Restore Notifications"),
            ): Spawn("sh -c 'makoctl restore'"),

            (
                modifiers: [Super, Ctrl],
                key: "n",
                description: Some("Dismiss All Notifications"),
            ): Spawn("sh -c 'makoctl dismiss --all'"),

        }
      '';
    };

    # ==========================================================================
    # Panel Configuration (JSON format)
    # ==========================================================================
    # Top panel with workspaces, window list, and system tray
    
    "cosmic/com.system76.CosmicPanel/v1/panel_top" = {
      text = builtins.toJSON {
        name = "Panel";
        anchor = "Top";
        anchor_gap = true;
        layer = "Top";
        keyboard_interactivity = "OnDemand";
        size = 32;
        
        # Left side: Workspace switcher and app launcher
        plugins_left = [
          "com.system76.CosmicPanelWorkspacesButton"
          "com.system76.CosmicAppList"
        ];
        
        # Center: Active windows list
        plugins_center = [
          "com.system76.CosmicPanelWindowList"
        ];
        
        # Right side: System tray and status indicators
        plugins_right = [
          "com.system76.CosmicPanelStatusArea"
          "com.system76.CosmicPanelAudioButton"
          "com.system76.CosmicPanelNetworkButton"
          "com.system76.CosmicPanelBatteryButton"
          "com.system76.CosmicPanelTimeButton"
          "com.system76.CosmicPanelPowerButton"
        ];
        
        # Visual appearance
        background = {
          color = "rgba(30, 30, 34, 0.95)";  # Semi-transparent dark
        };
        border_radius = 8;
        padding = 4;
      };
    };

    # ==========================================================================
    # Accessibility Configuration (JSON format)
    # ==========================================================================
    # Disable high contrast mode and screen reader
    # Location: ~/.config/cosmic/com.system76.CosmicSettings/v1/accessibility
    #
    # Issue: COSMIC Beta may send "high contrast enabled" signal to apps
    # even when GUI shows it's disabled. This explicitly disables it.
    
    "cosmic/com.system76.CosmicSettings/v1/accessibility" = {
      text = builtins.toJSON {
        high_contrast = false;
        screen_reader = false;
      };
    };

    # ==========================================================================
    # Workspace Configuration (RON format)
    # ==========================================================================
    # COSMIC compositor workspace settings
    # Format: RON (not JSON) - this is the actual file cosmic-comp reads
    # Location: ~/.config/cosmic/com.system76.CosmicComp/v1/workspaces
    
    "cosmic/com.system76.CosmicComp/v1/workspaces" = {
      text = ''
        (
            workspace_mode: Global,
            workspace_layout: Horizontal,
        )
      '';
    };

    # ==========================================================================
    # Pinned Workspaces Configuration (RON format)
    # ==========================================================================
    # Pinned workspaces persist even when empty
    # Note: Monitor EDID will be specific to your hardware
    # To generate: Pin workspaces via GUI, then copy the generated file
    # This config creates 9 pinned workspaces with tiling enabled
    #
    # IMPORTANT: Replace EDID values with your actual monitor info
    # Get your monitor info from: ~/.config/cosmic/com.system76.CosmicComp/v1/pinned_workspaces
    
    "cosmic/com.system76.CosmicComp/v1/pinned_workspaces" = {
      text = ''
        [
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws1")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws2")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws3")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws4")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws5")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws6")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws7")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws8")),
            (output: (name: "DP-3", edid: Some((manufacturer: ('D', 'E', 'L'), product: 16606, serial: Some(959461708), manufacture_week: 34, manufacture_year: 2018, model_year: None))), tiling_enabled: true, id: Some("ws9")),
        ]
      '';
    };

    # ==========================================================================
    # Dock Configuration Files
    # ==========================================================================
    # Oturum açıldığında dock boyutunu XS yap
    # (Not: Servis tanımları xdg.configFile dışında tepe seviyeye taşındı.)

    # ==========================================================================
    # Terminal Configuration (JSON format)
    # ==========================================================================
    # COSMIC Terminal (cosmic-term) settings
    
    "cosmic/com.system76.CosmicTerm/v1/config" = {
      text = builtins.toJSON {
        # Font settings - Maple Mono for consistency
        font_name = "Maple Mono NF";
        font_size = 14;
        font_weight = 400;              # Regular weight
        dim_font_weight = 400;
        bold_font_weight = 700;
        
        # Theme selection
        syntax_theme_dark = "COSMIC Dark";
        syntax_theme_light = "COSMIC Light";
        
        # Appearance
        background_opacity = 0.95;      # Slight transparency
        
        # Behavior
        scrollback_lines = 10000;       # History buffer
        cursor_shape = "Block";         # Block cursor style
        
        # Padding
        padding_horizontal = 8;
        padding_vertical = 8;
        
        # Default profile
        default_profile = "default";
      };
    };

    # ==========================================================================
    # Terminal Default Profile (JSON format)
    # ==========================================================================
    # Shell and environment for new terminal windows
    
    "cosmic/com.system76.CosmicTerm/v1/profiles/default" = {
      text = builtins.toJSON {
        name = "Default";
        command = "zsh";                # Default shell (zsh)
        directory = null;               # Start in home directory
        hold = false;                   # Close window on exit
        tab_title = null;               # Auto-generate tab title
        syntax_theme_dark = "COSMIC Dark";
        syntax_theme_light = "COSMIC Light";
      };
    };

    # ==========================================================================
    # File Manager Configuration (JSON format)
    # ==========================================================================
    # COSMIC Files appearance and behavior
    
    "cosmic/com.system76.CosmicFiles/v1/config" = {
      text = builtins.toJSON {
        view = "Grid";                  # Grid view by default
        icon_sizes = {
          list = 32;                    # Icon size in list view
          grid = 96;                    # Icon size in grid view
        };
        show_hidden = false;            # Hide dotfiles by default
        sort_name = "Name";             # Sort by name
        sort_direction = true;          # Ascending order
      };
    };

    # ==========================================================================
    # Window Tiling Configuration
    # ==========================================================================
    # Auto-tiling behavior and default state for new workspaces
    # Note: force = true prevents COSMIC Settings from overriding these
    
    "cosmic/com.system76.CosmicComp/v1/autotile" = {
      text = "true";                    # New workspaces start with tiling enabled
      force = true;                     # Prevent GUI override
    };

    "cosmic/com.system76.CosmicComp/v1/autotile_behavior" = {
      text = ''
        Global
      '';
      force = true;                     # Prevent GUI override - keep it Global always
    };
    
    # Tiling mode default enabled for all workspaces
    # Note: Removed - COSMIC doesn't use this config file for default tiling
    # Use autotile_behavior = "Always" instead

    # ==========================================================================
    # Icon Theme Configuration (JSON format)
    # ==========================================================================
    # Set A-Candy-Beauty as the icon theme
    
    "cosmic/com.system76.CosmicTheme/v1/icon_theme" = {
      text = builtins.toJSON {
        theme = "a-candy-beauty-icon-theme";
      };
    };

    # ==========================================================================
    # GTK Theme Configuration
    # ==========================================================================
    # Force dark mode preference for GTK apps and browsers
    
  };

  # ============================================================================
  # Systemd User Session Variables
  # ============================================================================
  # Environment for systemd user services running under COSMIC
  
  systemd.user.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}

