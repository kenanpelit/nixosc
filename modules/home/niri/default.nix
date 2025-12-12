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
      gaps 5
      center-focused-column "never"
      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }
      default-column-width { proportion 0.5 }
    }
  '';

  # 2. Keybindings: Full DMS IPC integration + Niri Core
  # WRAPPED IN "binds {}" BLOCK AND REMOVED SEMICOLONS
  dmsBinds = ''
    binds {
      // ========================================================================
      // DANK MATERIAL SHELL (DMS) - IPC BINDINGS
      // ========================================================================

      // --- Launchers & Modals ---
      Mod+Space hotkey-overlay-title="Application Launcher" { spawn "${dmsCmd}" "ipc" "call" "spotlight" "toggle" }
      Mod+D hotkey-overlay-title="Dashboard" { spawn "${dmsCmd}" "ipc" "call" "dash" "toggle" "" }
      Mod+Shift+D hotkey-overlay-title="Dash Overview" { spawn "${dmsCmd}" "ipc" "call" "dash" "toggle" "overview" }
      Mod+M hotkey-overlay-title="Task Manager" { spawn "${dmsCmd}" "ipc" "call" "processlist" "focusOrToggle" }
      Mod+Shift+P hotkey-overlay-title="Task Manager (Alt)" { spawn "${dmsCmd}" "ipc" "call" "processlist" "focusOrToggle" }
      Mod+Comma hotkey-overlay-title="Settings" { spawn "${dmsCmd}" "ipc" "call" "settings" "focusOrToggle" }
      Mod+N hotkey-overlay-title="Notification Center" { spawn "${dmsCmd}" "ipc" "call" "notifications" "toggle" }
      Mod+C hotkey-overlay-title="Control Center" { spawn "${dmsCmd}" "ipc" "call" "control-center" "toggle" }
      Mod+V hotkey-overlay-title="Clipboard Manager" { spawn "${dmsCmd}" "ipc" "call" "clipboard" "toggle" }
      Mod+Backspace hotkey-overlay-title="Power Menu" { spawn "${dmsCmd}" "ipc" "call" "powermenu" "toggle" }
      Mod+Ctrl+N hotkey-overlay-title="Notepad" { spawn "${dmsCmd}" "ipc" "call" "notepad" "open" }

      // --- Wallpaper & Theming ---
      Mod+Y hotkey-overlay-title="Browse Wallpapers" { spawn "${dmsCmd}" "ipc" "call" "dankdash" "wallpaper" }
      Mod+W hotkey-overlay-title="Next Wallpaper" { spawn "${dmsCmd}" "ipc" "call" "wallpaper" "next" }
      Mod+Shift+W hotkey-overlay-title="Prev Wallpaper" { spawn "${dmsCmd}" "ipc" "call" "wallpaper" "prev" }
      Mod+Shift+T hotkey-overlay-title="Toggle Theme (Light/Dark)" { spawn "${dmsCmd}" "ipc" "call" "theme" "toggle" }
      Mod+Shift+N hotkey-overlay-title="Toggle Night Mode" { spawn "${dmsCmd}" "ipc" "call" "night" "toggle" }

      // --- Bar & Dock ---
      Mod+B hotkey-overlay-title="Toggle Bar" { spawn "${dmsCmd}" "ipc" "call" "bar" "toggle" "index" "0" }
      Mod+Ctrl+B hotkey-overlay-title="Toggle Bar AutoHide" { spawn "${dmsCmd}" "ipc" "call" "bar" "toggleAutoHide" "index" "0" }
      Mod+Shift+B hotkey-overlay-title="Toggle Dock" { spawn "${dmsCmd}" "ipc" "call" "dock" "toggle" }

      // --- Security & Inhibit ---
      Mod+Alt+L hotkey-overlay-title="Lock Screen" { spawn "${dmsCmd}" "ipc" "call" "lock" "lock" }
      Mod+Delete hotkey-overlay-title="Lock Screen" { spawn "${dmsCmd}" "ipc" "call" "lock" "lock" }
      Mod+Shift+Delete hotkey-overlay-title="Toggle Idle Inhibit" { spawn "${dmsCmd}" "ipc" "call" "inhibit" "toggle" }

      // --- Audio Controls ---
      XF86AudioRaiseVolume allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "increment" "5" }
      XF86AudioLowerVolume allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "decrement" "5" }
      XF86AudioMute allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "mute" }
      XF86AudioMicMute allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "audio" "micmute" }
      Mod+Alt+A hotkey-overlay-title="Cycle Audio Output" { spawn "${dmsCmd}" "ipc" "call" "audio" "cycleoutput" }

      // --- Media Controls (MPRIS) ---
      XF86AudioPlay allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "playPause" }
      XF86AudioNext allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "next" }
      XF86AudioPrev allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "previous" }
      XF86AudioStop allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "mpris" "stop" }

      // --- Brightness Controls ---
      XF86MonBrightnessUp allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "brightness" "increment" "5" "" }
      XF86MonBrightnessDown allow-when-locked=true { spawn "${dmsCmd}" "ipc" "call" "brightness" "decrement" "5" "" }
      Mod+Alt+B hotkey-overlay-title="Toggle Exponential Brightness" { spawn "${dmsCmd}" "ipc" "call" "brightness" "toggleExponential" }

      // --- Help / Cheatsheet ---
      Mod+Slash hotkey-overlay-title="Show Keybinds" { spawn "${dmsCmd}" "ipc" "call" "keybinds" "toggle" "niri" }
      Mod+Shift+K hotkey-overlay-title="Open Keybind Settings" { spawn "${dmsCmd}" "ipc" "call" "settings" "openWith" "keybinds" }

      // ========================================================================
      // NIRI CORE BINDINGS
      // ========================================================================

      // --- Applications ---
      Mod+Return { spawn "${kittyCmd}" }
      Mod+T { spawn "${kittyCmd}" }

      // --- Window Management ---
      Mod+Q { close-window }
      Mod+Shift+E { quit skip-confirmation=true }
      Mod+F { maximize-column }
      Mod+Shift+F { fullscreen-window }
      Mod+O { toggle-window-rule-opacity }

      // --- Navigation ---
      Mod+Left  { focus-column-left }
      Mod+Right { focus-column-right }
      Mod+Up    { focus-workspace-up }
      Mod+Down  { focus-workspace-down }
      Mod+H     { focus-column-left }
      Mod+L     { focus-column-right }
      Mod+K     { focus-workspace-up }
      Mod+J     { focus-workspace-down }

      // --- Moving Windows ---
      Mod+Shift+Left  { move-column-left }
      Mod+Shift+Right { move-column-right }
      Mod+Shift+Up    { move-window-up }
      Mod+Shift+Down  { move-window-down }
      Mod+Shift+H     { move-column-left }
      Mod+Shift+L     { move-column-right }
      Mod+Shift+K     { move-window-up }
      Mod+Shift+J     { move-window-down }

      // --- Moving Workspaces to Outputs ---
      Mod+Ctrl+Left  { move-column-to-monitor-left }
      Mod+Ctrl+Right { move-column-to-monitor-right }
      Mod+Ctrl+Up    { move-column-to-monitor-up }
      Mod+Ctrl+Down  { move-column-to-monitor-down }

      // --- Screenshots (DMS Niri integration) ---
      Print { spawn "${dmsCmd}" "ipc" "call" "niri" "screenshot" }
      Ctrl+Print { spawn "${dmsCmd}" "ipc" "call" "niri" "screenshotScreen" }
      Alt+Print { spawn "${dmsCmd}" "ipc" "call" "niri" "screenshotWindow" }
      
      // --- Mouse Wheel Integration ---
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down }
      Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up }
      Mod+WheelScrollRight                { focus-column-right }
      Mod+WheelScrollLeft                 { focus-column-left }
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
      XDG_CURRENT_DESKTOP "niri"
      QT_QPA_PLATFORM "wayland"
      ELECTRON_OZONE_PLATFORM_HINT "auto"
      QT_QPA_PLATFORMTHEME "gtk3"
      QT_QPA_PLATFORMTHEME_QT6 "gtk3"
      DISPLAY ":0"
    }

    // --- Startup Applications ---
    spawn-at-startup "${niriusCmd}"
    spawn-at-startup "${niriswitcherCmd}"
    
    // Start DMS manually
    spawn-at-startup "${dmsCmd}" "run"
    spawn-at-startup "bash" "-c" "wl-paste --watch cliphist store &"

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
        natural-scroll
      }
    }

    // --- Includes (Modular Config) ---
    include "dms/layout.kdl"
    include "dms/binds.kdl"
    include "dms/colors.kdl"

    // --- DMS Layer Rules (Wallpaper Integration) ---
    layer-rule {
        match namespace="^quickshell$"
        place-within-backdrop true
    }

    layer-rule {
        match namespace="dms:blurwallpaper"
        place-within-backdrop true
    }
    
    // --- Window Rules ---
    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    window-rule {
        match app-id=r#"org.quickshell$"#
        open-floating true
    }
    
    window-rule {
        match app-id=r#"^org\.gnome\."#
        draw-border-with-background false
    }
    window-rule {
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        match app-id="Alacritty"
        match app-id="zen"
        match app-id="com.mitchellh.ghostty"
        match app-id="kitty"
        draw-border-with-background false
    }

    window-rule {
        match is-active=false
        opacity 0.9
    }
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
    xdg.configFile."niri/dms/colors.kdl".text = dmsColors;
    xdg.configFile."niri/dms/alttab.kdl".text = ""; # Placeholder
  };
}
