# modules/home/niri/default.nix
# ==============================================================================
# Home module for Niri compositor optimized for DankMaterialShell (DMS).
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.my.desktop.niri;
  username = config.home.username;
  
  # Binaries
  kittyCmd = "${pkgs.kitty}/bin/kitty";
  dmsCmd = "/etc/profiles/per-user/${username}/bin/dms";
  niriusCmd = "${pkgs.nirius}/bin/niriusd";
  niriswitcherCmd = "${pkgs.niriswitcher}/bin/niriswitcher";

  # ----------------------------------------------------------------------------
  # DMS Specific Configurations (Sub-files)
  # ----------------------------------------------------------------------------

  # 1. Layout: Transparent background for wallpaper integration
  dmsLayout = ''
    layout {
      gaps 5;
      center-focused-column "never";
      background-color "#00000000";
      preset-column-widths {
        proportion 0.33333;
        proportion 0.5;
        proportion 0.66667;
      }
      default-column-width { proportion 0.5; }
    }
  '';

  # 2. Keybindings: Full DMS IPC integration + Niri Core
  # WRAPPED IN "binds {}" BLOCK AND ADDED SEMICOLONS
  dmsBinds = ''
    binds {
      // ========================================================================
      // DANK MATERIAL SHELL (DMS) - IPC BINDINGS
      // ========================================================================

      // --- Launchers & Modals ---
      Mod+Space hotkey-overlay-title="Application Launcher" { spawn "${dmsCmd}" "ipc" "call" "spotlight" "toggle"; }
      Mod+D hotkey-overlay-title="Dashboard" { spawn "${dmsCmd}" "ipc" "call" "dash" "toggle" ""; }
      Mod+Shift+D hotkey-overlay-title="Dash Overview" { spawn "${dmsCmd}" "ipc" "call" "dash" "toggle" "overview"; }
      Mod+M hotkey-overlay-title="Task Manager" { spawn "${dmsCmd}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Shift+P hotkey-overlay-title="Task Manager (Alt)" { spawn "${dmsCmd}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Comma hotkey-overlay-title="Settings" { spawn "${dmsCmd}" "ipc" "call" "settings" "focusOrToggle"; }
      Mod+N hotkey-overlay-title="Notification Center" { spawn "${dmsCmd}" "ipc" "call" "notifications" "toggle"; }
      Mod+C hotkey-overlay-title="Control Center" { spawn "${dmsCmd}" "ipc" "call" "control-center" "toggle"; }
      Mod+V hotkey-overlay-title="Clipboard Manager" { spawn "${dmsCmd}" "ipc" "call" "clipboard" "toggle"; }
      Mod+Backspace hotkey-overlay-title="Power Menu" { spawn "${dmsCmd}" "ipc" "call" "powermenu" "toggle"; }
      Mod+Ctrl+N hotkey-overlay-title="Notepad" { spawn "${dmsCmd}" "ipc" "call" "notepad" "open"; }

      // --- Wallpaper & Theming ---
      Mod+Y hotkey-overlay-title="Browse Wallpapers" { spawn "${dmsCmd}" "ipc" "call" "dankdash" "wallpaper"; }
      Mod+W hotkey-overlay-title="Next Wallpaper" { spawn "${dmsCmd}" "ipc" "call" "wallpaper" "next"; }
      Mod+Shift+W hotkey-overlay-title="Prev Wallpaper" { spawn "${dmsCmd}" "ipc" "call" "wallpaper" "prev"; }
      Mod+Shift+T hotkey-overlay-title="Toggle Theme (Light/Dark)" { spawn "${dmsCmd}" "ipc" "call" "theme" "toggle"; }
      Mod+Shift+N hotkey-overlay-title="Toggle Night Mode" { spawn "${dmsCmd}" "ipc" "call" "night" "toggle"; }

      // --- Bar & Dock ---
      Mod+B hotkey-overlay-title="Toggle Bar" { spawn "${dmsCmd}" "ipc" "call" "bar" "toggle" "index" "0"; }
      Mod+Ctrl+B hotkey-overlay-title="Toggle Bar AutoHide" { spawn "${dmsCmd}" "ipc" "call" "bar" "toggleAutoHide" "index" "0"; }
      Mod+Shift+B hotkey-overlay-title="Toggle Dock" { spawn "${dmsCmd}" "ipc" "call" "dock" "toggle"; }

      // --- Security & Inhibit ---
      Mod+Ctrl+L hotkey-overlay-title="Lock Screen" { spawn "${dmsCmd}" "ipc" "call" "lock" "lock"; }
      Alt+L hotkey-overlay-title="Lock Screen" { spawn "${dmsCmd}" "ipc" "call" "lock" "lock"; }
      Mod+Delete hotkey-overlay-title="Lock Screen" { spawn "${dmsCmd}" "ipc" "call" "lock" "lock"; }
      Mod+Shift+Delete hotkey-overlay-title="Toggle Idle Inhibit" { spawn "${dmsCmd}" "ipc" "call" "inhibit" "toggle"; }

      // --- Audio Controls ---
      XF86AudioRaiseVolume allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "increment" "5"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "decrement" "5"; }
      XF86AudioMute allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "mute"; }
      XF86AudioMicMute allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "micmute"; }
      Mod+Alt+A hotkey-overlay-title="Cycle Audio Output" { spawn "${dmsCmd}" "ipc" "call" "audio" "cycleoutput"; }

      // --- Media Controls (MPRIS) ---
      XF86AudioPlay allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "playPause"; }
      XF86AudioNext allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "next"; }
      XF86AudioPrev allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "previous"; }
      XF86AudioStop allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "stop"; }

      // --- Brightness Controls ---
      XF86MonBrightnessUp allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "brightness" "increment" "5" ""; }
      XF86MonBrightnessDown allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "brightness" "decrement" "5" ""; }
      Mod+Alt+B hotkey-overlay-title="Toggle Exponential Brightness" { spawn "${dmsCmd}" "ipc" "call" "brightness" "toggleExponential"; }

      // --- Help / Cheatsheet ---
      Mod+Slash hotkey-overlay-title="Show Keybinds" { spawn "${dmsCmd}" "ipc" "call" "keybinds" "toggle" "niri"; }
      Mod+Alt+Slash hotkey-overlay-title="Open Keybind Settings" { spawn "${dmsCmd}" "ipc" "call" "settings" "openWith" "keybinds"; }
      Mod+Shift+Slash { show-hotkey-overlay; }

      // ========================================================================
      // NIRI CORE BINDINGS
      // ========================================================================

      // --- Applications ---
      Mod+Return { spawn "${kittyCmd}"; }
      Mod+T { spawn "${kittyCmd}"; }

      // --- Window Management ---
      Mod+Q { close-window; }
      Mod+Shift+E { quit skip-confirmation=true; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
      Mod+O { toggle-window-rule-opacity; }
      Mod+R { switch-preset-column-width; }
      Mod+Shift+Space { toggle-window-floating; }
      Mod+Grave { switch-focus-between-floating-and-tiling; }

      // --- Column/Window Manipulation ---
      Mod+BracketLeft { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }

      // --- Navigation ---
      Mod+Left  { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up    { focus-workspace-up; }
      Mod+Down  { focus-workspace-down; }
      Mod+H     { focus-column-left; }
      Mod+L     { focus-column-right; }
      Mod+K     { focus-workspace-up; }
      Mod+J     { focus-workspace-down; }

      // --- Focus Monitor ---
      Mod+Alt+Left  { focus-monitor-left; }
      Mod+Alt+Right { focus-monitor-right; }
      Mod+Alt+Up    { focus-monitor-up; }
      Mod+Alt+Down  { focus-monitor-down; }
      Mod+Alt+H     { focus-monitor-left; }
      Mod+Alt+L     { focus-monitor-right; }
      Mod+Alt+K     { focus-monitor-up; }
      Mod+Alt+J     { focus-monitor-down; }

      // --- Moving Windows ---
      Mod+Shift+Left  { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up    { move-window-up; }
      Mod+Shift+Down  { move-window-down; }
      Mod+Shift+H     { move-column-left; }
      Mod+Shift+L     { move-column-right; }
      Mod+Shift+K     { move-window-up; }
      Mod+Shift+J     { move-window-down; }

      // --- Moving Workspaces (Monitors/Workspaces) ---
      Mod+Ctrl+Left  { move-column-to-monitor-left; }
      Mod+Ctrl+Right { move-column-to-monitor-right; }
      Mod+Ctrl+Up    { move-column-to-workspace-up; }
      Mod+Ctrl+Down  { move-column-to-workspace-down; }

      // --- Screenshots (DMS Niri integration) ---
      Print { spawn "${dmsCmd}" "ipc" "call" "niri" "screenshot"; }
      Ctrl+Print { spawn "${dmsCmd}" "ipc" "call" "niri" "screenshotScreen"; }
      Alt+Print { spawn "${dmsCmd}" "ipc" "call" "niri" "screenshotWindow"; }
      
      // --- Mouse Wheel Integration ---
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
      Mod+WheelScrollRight                { focus-column-right; }
      Mod+WheelScrollLeft                 { focus-column-left; }

      // --- Custom Applications (Imported from Hyprland) ---
      Mod+Alt+Return { spawn "semsumo" "launch" "--daily"; }

      // Launchers
      F1 { spawn "rofi-launcher" "keys"; }
      Alt+Space { spawn "rofi-launcher"; }
      Mod+Ctrl+Space { spawn "walk"; }

      // File Managers
      Alt+F { spawn "kitty" "-e" "yazi"; }
      Alt+Ctrl+F { spawn "nemo"; }

      // Special Apps
      Alt+T { spawn "start-kkenp"; }
      Mod+Shift+M { spawn "anotes"; } // Mod+M is DMS Task Manager

      // Tools
      Mod+Shift+C { spawn "hyprpicker" "-a"; }
      Mod+Ctrl+V { spawn "kitty" "--class" "clipse" "-e" "clipse"; }
      F10 { spawn "bluetooth_toggle"; }
      Alt+F12 { spawn "osc-mullvad" "toggle"; }

      // --- Audio & Media Scripts ---
      Alt+A { spawn "osc-soundctl" "switch"; }
      Alt+Ctrl+A { spawn "osc-soundctl" "switch-mic"; }
      
      Alt+E { spawn "osc-spotify"; }
      Alt+Ctrl+N { spawn "osc-spotify" "next"; }
      Alt+Ctrl+B { spawn "osc-spotify" "prev"; }
      Alt+Ctrl+E { spawn "mpc-control" "toggle"; }
      Alt+I { spawn "hypr-vlc_toggle"; }

      // --- MPV Manager ---
      Ctrl+Alt+1 { spawn "hypr-mpv-manager" "start"; }
      Alt+1 { spawn "hypr-mpv-manager" "playback"; }
      Alt+2 { spawn "hypr-mpv-manager" "play-yt"; }
      Alt+3 { spawn "hypr-mpv-manager" "stick"; }
      Alt+4 { spawn "hypr-mpv-manager" "move"; }
      Alt+5 { spawn "hypr-mpv-manager" "save-yt"; }
      Alt+6 { spawn "hypr-mpv-manager" "wallpaper"; }

      // --- Workspace Switching (1-9) ---
      Mod+1 { focus-workspace "1"; }
      Mod+2 { focus-workspace "2"; }
      Mod+3 { focus-workspace "3"; }
      Mod+4 { focus-workspace "4"; }
      Mod+5 { focus-workspace "5"; }
      Mod+6 { focus-workspace "6"; }
      Mod+7 { focus-workspace "7"; }
      Mod+8 { focus-workspace "8"; }
      Mod+9 { focus-workspace "9"; }

      // --- Move Column to Workspace (1-9) ---
      Mod+Shift+1 { move-column-to-workspace "1"; }
      Mod+Shift+2 { move-column-to-workspace "2"; }
      Mod+Shift+3 { move-column-to-workspace "3"; }
      Mod+Shift+4 { move-column-to-workspace "4"; }
      Mod+Shift+5 { move-column-to-workspace "5"; }
      Mod+Shift+6 { move-column-to-workspace "6"; }
      Mod+Shift+7 { move-column-to-workspace "7"; }
      Mod+Shift+8 { move-column-to-workspace "8"; }
      Mod+Shift+9 { move-column-to-workspace "9"; }
    }
  '';

  # 3. Rules (Window & Layer)
  dmsRules = ''
    // --- General Styling ---
    window-rule {
        geometry-corner-radius 12;
        clip-to-geometry true;
    }

    // --- Floating Windows & Shadows ---
    window-rule {
        match is-floating=true;
        shadow { on; }
    }

    window-rule {
        match app-id=r#"org.quickshell$"#;
        open-floating true;
    }
    
    // --- Media & PIP ---
    window-rule {
        match app-id="mpv";
        match title="^Picture-in-Picture$";
        open-floating true;
        default-column-width { fixed 600; }
        default-window-height { fixed 340; }
    }
    
    window-rule {
        match app-id="vlc";
        open-on-workspace "6";
    }

    // --- Dialogs & Tools (Floating) ---
    window-rule {
        match title="^Open File$";
        match title="^File Upload$";
        match title="^Save As$";
        match title="^Confirm to replace files$";
        match title="^File Operation Progress$";
        match app-id="pavucontrol";
        match app-id="org.pulseaudio.pavucontrol";
        match app-id="nm-connection-editor";
        match app-id="blueman-manager";
        match app-id="polkit-gnome-authentication-agent-1";
        match app-id="hyprland-share-picker"; 
        open-floating true;
        // default-floating-position x=0 y=0 relative-to="center";
    }

    // --- Workspace Assignments ---
    window-rule { match app-id="discord"; open-on-workspace "5"; }
    window-rule { match app-id="WebCord"; open-on-workspace "5"; }
    window-rule { match app-id="Spotify"; open-on-workspace "8"; }
    window-rule { match app-id="audacious"; open-on-workspace "5"; }
    window-rule { match app-id="transmission"; open-on-workspace "7"; }
    window-rule { match app-id="org.keepassxc.KeePassXC"; open-on-workspace "7"; }

    // --- Privacy (Block from Screencast) ---
    window-rule {
        match app-id=r#"^org\.keepassxc\.KeePassXC$"#;
        match app-id=r#"^org\.gnome\.World\.Secrets$"#;
        block-out-from "screencast";
    }

    // --- No Border Apps ---
    window-rule {
        match app-id=r#"^org\.gnome\."#;
        match app-id=r#"^org\.wezfurlong\.wezterm$"#;
        match app-id="Alacritty";
        match app-id="zen";
        match app-id="com.mitchellh.ghostty";
        match app-id="kitty";
        match app-id="firefox";
        match app-id="Brave-browser";
        draw-border-with-background false;
    }

    // --- Inactive Dimming ---
    window-rule {
        match is-active=false;
        opacity 0.95;
    }

    // --- Layer Rules ---
    layer-rule {
        match namespace="^quickshell$";
        place-within-backdrop true;
    }
    layer-rule {
        match namespace="dms:blurwallpaper";
        place-within-backdrop true;
    }
    layer-rule {
        match namespace="^notifications$";
        block-out-from "screencast";
    }
  '';

  # 4. Animations
  dmsAnimations = ''
    animations {
        // Workspace Switching (Spring for snappy feel)
        workspace-switch { 
            spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001; 
        }

        // Window Open/Close (Easing)
        window-open { 
            duration-ms 150; 
            curve "ease-out-expo"; 
        }
        window-close { 
            duration-ms 150; 
            curve "ease-out-quad"; 
        }

        // View Movement (Springs)
        horizontal-view-movement { 
            spring damping-ratio=1.0 stiffness=800 epsilon=0.0001; 
        }
        window-movement { 
            spring damping-ratio=1.0 stiffness=800 epsilon=0.0001; 
        }
        window-resize { 
            spring damping-ratio=1.0 stiffness=800 epsilon=0.0001; 
        }

        // UI Animations
        config-notification-open-close { 
            spring damping-ratio=0.6 stiffness=1000 epsilon=0.001; 
        }
        exit-confirmation-open-close { 
            spring damping-ratio=0.6 stiffness=500 epsilon=0.01; 
        }
        screenshot-ui-open { 
            duration-ms 200; 
            curve "ease-out-quad"; 
        }
        overview-open-close { 
            spring damping-ratio=1.0 stiffness=800 epsilon=0.0001; 
        }
        recent-windows-close { 
            spring damping-ratio=1.0 stiffness=800 epsilon=0.001; 
        }
    }
  '';

  # 5. Gestures
  dmsGestures = ''
    gestures {
        dnd-edge-view-scroll {
            trigger-width 30;
            delay-ms 100;
            max-speed 1500;
        }
        hot-corners {
            top-left;
        }
    }
  '';

  # 6. Recent Windows (Alt-Tab)
  dmsRecentWindows = ''
    recent-windows {
        debounce-ms 0;
        highlight {
            active-color "#cba6f7ff"; // Catppuccin Mauve
            corner-radius 12;
        }
    }
  '';

  # 3. Colors (Placeholder)
  dmsColors = ''
    // Colors placeholder
  '';

  # ----------------------------------------------------------------------------
  # Main Niri Config
  # ----------------------------------------------------------------------------
  niriConfig = ''
    // ========================================================================
    // Niri Configuration - Optimized for DankMaterialShell
    // ========================================================================

    environment {
      XDG_CURRENT_DESKTOP "niri";
      QT_QPA_PLATFORM "wayland";
      ELECTRON_OZONE_PLATFORM_HINT "auto";
      QT_QPA_PLATFORMTHEME "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 "gtk3";
      DISPLAY ":0";
    }

    prefer-no-csd;

    // --- Startup Applications ---
    spawn-at-startup "${niriusCmd}";
    spawn-at-startup "${niriswitcherCmd}";
    
    // Start DMS manually (Disabled: DMS is managed by systemd service)
    // spawn-at-startup "${dmsCmd}" "run";
    // spawn-at-startup "bash" "-c" "wl-paste --watch cliphist store &"

    // --- Input Configuration ---
    input {
      keyboard {
        xkb {
          layout "tr"
          variant "f"
          options "ctrl:nocaps"
        }
      }
      touchpad {
        tap
        dwt
        drag-lock
        middle-emulation
        click-method "clickfinger"
        accel-profile "flat"
        accel-speed 0.8
        // natural-scroll
      }
    }
    // --- Switch Events ---
    switch-events {
        lid-close { spawn "${dmsCmd}" "ipc" "call" "lock" "lock"; }
    }

    // --- Named Workspaces (Static 1-9) ---
    // Primary Monitor (DP-3)
    workspace "1" { open-on-output "DP-3"; }
    workspace "2" { open-on-output "DP-3"; }
    workspace "3" { open-on-output "DP-3"; }
    workspace "4" { open-on-output "DP-3"; }
    workspace "5" { open-on-output "DP-3"; }
    workspace "6" { open-on-output "DP-3"; }
    
    // Secondary Monitor (eDP-1)
    workspace "7" { open-on-output "eDP-1"; }
    
    // Spotify Workspace (Custom Layout)
    workspace "8" { 
        open-on-output "eDP-1";
        layout {
            gaps 20;
            border {
                on;
                width 4;
                active-color "#cba6f7ff";
            }
        }
    }
    
    workspace "9" { open-on-output "eDP-1"; }

    // --- Monitor Configuration ---
    // Note: Use 'niri msg outputs' to find exact port names (e.g., DP-1, eDP-1).
    // Replacing "Monitor Name" with actual names is required.

    // Primary: DELL UP2716D
    output "DP-3" {
        mode "2560x1440@59.951"; // or @60
        position x=0 y=0;
        scale 1.0;
    }

    // Secondary: Chimei Innolux (Laptop?)
    output "eDP-1" {
        mode "1920x1200@60.003";
        position x=320 y=1440;
        scale 1.0;
    }

    // --- Includes (Modular Config) ---
    include "dms/layout.kdl";
    include "dms/binds.kdl";
    include "dms/rules.kdl";
    include "dms/animations.kdl";
    include "dms/gestures.kdl";
    include "dms/recent-windows.kdl";
    include "dms/colors.kdl";
  '';

in
{
  options.my.desktop.niri = {
    enable = lib.mkEnableOption "Niri compositor (Wayland) configuration";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.niri;
      description = "Niri compositor package.";
    };
    enableNirius = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install nirius daemon + cli helpers.";
    };
    enableNiriswitcher = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install niriswitcher application switcher.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package ]
      ++ lib.optional cfg.enableNirius pkgs.nirius
      ++ lib.optional cfg.enableNiriswitcher pkgs.niriswitcher;

    # Main Config
    xdg.configFile."niri/config.kdl".text = niriConfig;

    # DMS Sub-configs
    xdg.configFile."niri/dms/layout.kdl".text = dmsLayout;
    xdg.configFile."niri/dms/binds.kdl".text = dmsBinds;
    xdg.configFile."niri/dms/rules.kdl".text = dmsRules;
    xdg.configFile."niri/dms/animations.kdl".text = dmsAnimations;
    xdg.configFile."niri/dms/gestures.kdl".text = dmsGestures;
    xdg.configFile."niri/dms/recent-windows.kdl".text = dmsRecentWindows;
    xdg.configFile."niri/dms/colors.kdl".text = dmsColors;
    xdg.configFile."niri/dms/alttab.kdl".text = ""; # Placeholder (deprecated by recent-windows)
  };
}
