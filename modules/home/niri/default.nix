# modules/home/niri/default.nix
# ==============================================================================
# Niri Compositor Configuration - Optimized for DankMaterialShell (DMS)
#
# Design goals:
# - Keep Niri config modular (KDL snippets under ~/.config/niri/dms/)
# - Keep comments English (per user preference)
# - Avoid duplicate keybinds: Niri rejects any duplicate binding across includes
# - Provide optional nirius integration (daemon + CLI) without breaking validate
#
# Important notes:
# - nirius provides:
#   - niriusd (daemon)  -> must be started
#   - nirius  (CLI)     -> used in keybinds (scratchpad/focus/move/etc.)
# - Do NOT call scratchpad-* via niriusd; that is a daemon, not the CLI.
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.desktop.niri;

  # ---------------------------------------------------------------------------
  # Optional feature toggles (module-local policy)
  #
  # - enableNiriusBinds:
  #   Disabled by default to prevent config validation failures due to duplicate
  #   keybinds. Enable only after choosing non-conflicting key combos.
  # ---------------------------------------------------------------------------
  enableNiriusBinds = false;

  # ---------------------------------------------------------------------------
  # Binary paths
  # ---------------------------------------------------------------------------
  bins = {
    kitty = "${pkgs.kitty}/bin/kitty";
    dms = "${config.home.profileDirectory}/bin/dms";
    niriLock = "${config.home.profileDirectory}/bin/niri-lock";

    # nirius: daemon + CLI (keep names explicit and correct)
    niriusd = "${pkgs.nirius}/bin/niriusd";
    nirius  = "${pkgs.nirius}/bin/nirius";

    niriuswitcher = "${pkgs.niriswitcher}/bin/niriswitcher";
  };

  # ---------------------------------------------------------------------------
  # Catppuccin color palette
  # ---------------------------------------------------------------------------
  palette = {
    cyan = "#74c7ec";
    sky = "#89dceb";
    mauve = "#cba6f7";
    red = "#f38ba8";

    surface0 = "#313244";
    surface1 = "#45475a";

    skyA80 = "#89dceb80";
    mauveA80 = "#cba6f780";
    mauveFF = "#cba6f7ff";
    redFF = "#f38ba8ff";
  };

  # ----------------------------------------------------------------------------
  # Window Rule Helpers
  # ----------------------------------------------------------------------------
  mkFixedFloating =
    { w, h, x ? null, y ? null, relativeTo ? "top-right", opacity ? null, focus ? true }:
    ''
      open-floating true;
      default-column-width { fixed ${toString w}; }
      default-window-height { fixed ${toString h}; }
      ${lib.optionalString (x != null && y != null)
        ''default-floating-position x=${toString x} y=${toString y} relative-to="${relativeTo}";''}
      min-width ${toString w};
      max-width ${toString w};
      min-height ${toString h};
      max-height ${toString h};
      ${lib.optionalString (opacity != null) "opacity ${toString opacity};"}
      ${lib.optionalString focus "open-focused true;"}
    '';

  mkProportionalFloating =
    { w, h, x ? null, y ? null, relativeTo ? "top-right", focus ? true }:
    ''
      open-floating true;
      default-column-width { proportion ${toString w}; }
      default-window-height { proportion ${toString h}; }
      ${lib.optionalString (x != null && y != null)
        ''default-floating-position x=${toString x} y=${toString y} relative-to="${relativeTo}";''}
      ${lib.optionalString focus "open-focused true;"}
    '';

  # ----------------------------------------------------------------------------
  # Workspace assignment rules for daily apps
  # ----------------------------------------------------------------------------
  workspaceRules = [
    { appId = "^discord$"; workspace = "5"; maximize = true; }
    { appId = "^WebCord$"; workspace = "5"; maximize = true; }
    { appId = "^(spotify|Spotify|com\\.spotify\\.Client)$"; workspace = "8"; }
    { appId = "^audacious$"; workspace = "5"; }
    { appId = "^transmission$"; workspace = "7"; }
    { appId = "^org\\.keepassxc\\.KeePassXC$"; workspace = "7"; }
    { appId = "^Kenp$"; workspace = "1"; maximize = true; }
    { appId = "^Ai$"; workspace = "3"; maximize = true; }
    { appId = "^CompecTA$"; workspace = "4"; maximize = true; }
    { appId = "^brave-youtube\\.com__-Default$"; workspace = "7"; maximize = true; }
    { appId = "^ferdium$"; workspace = "9"; }
    { appId = "^vlc$"; workspace = "6"; }
  ];

  renderWorkspaceRules = lib.concatStringsSep "\n" (
    map (r: ''
      window-rule {
        match app-id=r#"${r.appId}"#;
        open-on-workspace "${r.workspace}";
        ${lib.optionalString (r.maximize or false) "open-maximized true; open-maximized-to-edges true;"}
      }
    '') workspaceRules
  );

  # ----------------------------------------------------------------------------
  # Layout
  # ----------------------------------------------------------------------------
  layoutConfig = ''
    layout {
      gaps 5;
      center-focused-column "never";
      background-color "#00000000";

      focus-ring {
        on;
        width 2;
        active-gradient from="${palette.cyan}" to="${palette.mauve}" angle=45;
        inactive-color "${palette.surface1}";
      }

      border {
        on;
        width 1;
        active-color "${palette.sky}";
        inactive-color "${palette.surface0}";
      }

      tab-indicator {
        hide-when-single-tab;
        place-within-column;
        width 4;
        gap 6;
        length total-proportion=0.9;
        position "top";
        gaps-between-tabs 4;
        corner-radius 8;
        active-color "${palette.cyan}";
        inactive-color "${palette.surface1}";
        urgent-color "${palette.red}";
      }

      insert-hint {
        color "${palette.skyA80}";
        gradient from="${palette.skyA80}" to="${palette.mauveA80}" angle=45 relative-to="workspace-view";
      }

      preset-column-widths {
        proportion 0.33333;
        proportion 0.5;
        proportion 0.66667;
      }

      default-column-width { proportion 0.5; }
    }
  '';

  # ----------------------------------------------------------------------------
  # Keybinds - DMS Integration
  # ----------------------------------------------------------------------------
  bindsDms = ''
    binds {
      // ========================================================================
      // DMS Integration
      // ========================================================================

      // Launchers
      Mod+Space { spawn "${bins.dms}" "ipc" "call" "spotlight" "toggle"; }
      Mod+D { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" ""; }
      Mod+N { spawn "${bins.dms}" "ipc" "call" "notifications" "toggle"; }
      Mod+C { spawn "${bins.dms}" "ipc" "call" "control-center" "toggle"; }
      Mod+V { spawn "${bins.dms}" "ipc" "call" "clipboard" "toggle"; }
      Mod+Shift+D { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" "overview"; }
      Mod+Shift+P { spawn "${bins.dms}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Ctrl+N { spawn "${bins.dms}" "ipc" "call" "notepad" "open"; }
      Mod+Comma { spawn "${bins.dms}" "ipc" "call" "settings" "focusOrToggle"; }
      Mod+Backspace { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }

      // Wallpaper & Theming
      Mod+Y { spawn "${bins.dms}" "ipc" "call" "dankdash" "wallpaper"; }
      Mod+W { spawn "${bins.dms}" "ipc" "call" "wallpaper" "next"; }
      Mod+Shift+W { spawn "${bins.dms}" "ipc" "call" "wallpaper" "prev"; }
      Mod+Shift+T { spawn "${bins.dms}" "ipc" "call" "theme" "toggle"; }
      Mod+Shift+N { spawn "${bins.dms}" "ipc" "call" "night" "toggle"; }

      // Bar & Dock
      Mod+B { spawn "${bins.dms}" "ipc" "call" "bar" "toggle" "index" "0"; }
      Mod+Ctrl+B { spawn "${bins.dms}" "ipc" "call" "bar" "toggleAutoHide" "index" "0"; }
      Mod+Shift+B { spawn "${bins.dms}" "ipc" "call" "dock" "toggle"; }

      // Security
      Alt+L { spawn "${bins.niriLock}"; }
      Mod+Shift+Delete { spawn "${bins.dms}" "ipc" "call" "inhibit" "toggle"; }

      // Audio
      XF86AudioRaiseVolume allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "audio" "increment" "5"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "audio" "decrement" "5"; }
      XF86AudioMute allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "audio" "mute"; }
      XF86AudioMicMute allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "audio" "micmute"; }
      Mod+Alt+A { spawn "${bins.dms}" "ipc" "call" "audio" "cycleoutput"; }
      Mod+Alt+P { spawn "pavucontrol"; }

      // Media (MPRIS)
      XF86AudioPlay allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "mpris" "playPause"; }
      XF86AudioNext allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "mpris" "next"; }
      XF86AudioPrev allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "mpris" "previous"; }
      XF86AudioStop allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "mpris" "stop"; }

      // Brightness
      XF86MonBrightnessUp allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "brightness" "increment" "5" ""; }
      XF86MonBrightnessDown allow-when-locked=true { spawn "${bins.dms}" "ipc" "call" "brightness" "decrement" "5" ""; }

      // Help
      Mod+Slash { spawn "${bins.dms}" "ipc" "call" "keybinds" "toggle" "niri"; }
      Mod+Alt+Slash { spawn "${bins.dms}" "ipc" "call" "settings" "openWith" "keybinds"; }
      Mod+Shift+Slash { show-hotkey-overlay; }

      Alt+Tab hotkey-overlay-title="Switch Windows" { spawn "${bins.dms}" "ipc" "call" "spotlight" "openQuery" "!"; }
    }
  '';

  # ----------------------------------------------------------------------------
  # Keybinds - Core (window mgmt)
  # ----------------------------------------------------------------------------
  bindsCore = ''
    binds {
      // ========================================================================
      // Core Window Management
      // ========================================================================

      // Applications
      Mod+Return { spawn "${bins.kitty}"; }
      Mod+T { spawn "${bins.kitty}"; }

      // Window Controls
      Mod+Q { close-window; }
      Mod+Shift+E { quit skip-confirmation=true; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
      Mod+O { toggle-window-rule-opacity; }
      Mod+R { switch-preset-column-width; }
      Mod+Shift+Space { toggle-window-floating; }
      Mod+Grave { switch-focus-between-floating-and-tiling; }

      // Column Operations
      Mod+BracketLeft { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }

      // Navigation
      Mod+Left  { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up    { focus-workspace-up; }
      Mod+Down  { focus-workspace-down; }
      Mod+H     { focus-column-left; }
      Mod+L     { focus-column-right; }
      Mod+K     { focus-workspace-up; }
      Mod+J     { focus-workspace-down; }

      // Monitor Focus
      Mod+Alt+Up    { focus-monitor-up; }
      Mod+Alt+Down  { focus-monitor-down; }
      Mod+Alt+H     { focus-monitor-left; }
      Mod+Alt+L     { focus-monitor-right; }
      Mod+Alt+K     { focus-monitor-up; }
      Mod+Alt+J     { focus-monitor-down; }

      // Move Windows
      Mod+Shift+Left  { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up    { move-window-up; }
      Mod+Shift+Down  { move-window-down; }
      Mod+Shift+H     { move-column-left; }
      Mod+Shift+L     { move-column-right; }
      Mod+Shift+K     { move-window-up; }
      Mod+Shift+J     { move-window-down; }

      // Move to Monitor
      Mod+Ctrl+Left  { move-column-to-monitor-left; }
      Mod+Ctrl+Right { move-column-to-monitor-right; }
      Mod+Ctrl+Up    { move-column-to-monitor-up; }
      Mod+Ctrl+Down  { move-column-to-monitor-down; }

      // Alternative Navigation
      Mod+Page_Up       { focus-workspace-up; }
      Mod+Page_Down     { focus-workspace-down; }
      Mod+Shift+Page_Up { move-column-to-workspace-up; }
      Mod+Shift+Page_Down { move-column-to-workspace-down; }

      // Screenshots
      Print { spawn "${bins.dms}" "ipc" "call" "niri" "screenshot"; }
      Ctrl+Print { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotScreen"; }
      Alt+Print { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotWindow"; }

      // Mouse Wheel
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
      Mod+WheelScrollRight { focus-column-right; }
      Mod+WheelScrollLeft  { focus-column-left; }

      // ========================================================================
      // nirius Integration (optional)
      //
      // WARNING:
      // - Niri rejects duplicate keybinds across all included files.
      // - Your previous validate error was caused by binding Mod+Grave and
      //   Mod+Shift+Grave twice, AND by calling scratchpad via niriusd.
      // - Enable these binds only after picking keys that do not conflict with
      //   existing ones (Mod+Grave is already used above).
      //
      // Recommended "safe" defaults (unlikely to collide):
      // - Mod+Alt+Grave / Mod+Alt+Shift+Grave
      // ========================================================================
      ${lib.optionalString enableNiriusBinds ''
      Mod+Alt+Shift+Return { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^kitty$" "${bins.kitty}"; }
      Mod+Alt+S { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "--focus"; }
      Mod+Alt+Shift+Grave { spawn "${bins.nirius}" "scratchpad-toggle"; }
      Mod+Alt+Grave { spawn "${bins.nirius}" "scratchpad-show"; }
      Mod+Alt+Shift+F10 { spawn "${bins.nirius}" "toggle-follow-mode"; }
      ''}
    }
  '';

  # ----------------------------------------------------------------------------
  # Keybinds - Custom apps
  # ----------------------------------------------------------------------------
  bindsApps = ''
    binds {
      // ========================================================================
      // Custom Applications
      // ========================================================================

      Mod+Alt+Return { spawn "semsumo" "launch" "--daily"; }
      Mod+Shift+A { spawn "niri-arrange-windows"; }
      Mod+Alt+Left { spawn "niri" "msg" "action" "set-column-width" "-100"; }
      Mod+Alt+Right { spawn "niri" "msg" "action" "set-column-width" "+100"; }

      // Launchers
      Alt+Space { spawn "rofi-launcher"; }
      Mod+Ctrl+Space { spawn "walk"; }

      // File Managers
      Alt+F { spawn "kitty" "-e" "yazi"; }
      Alt+Ctrl+F { spawn "nemo"; }

      // Special Apps
      Alt+T { spawn "start-kkenp"; }
      Mod+M { spawn "anotes"; }

      // Tools
      Mod+Shift+C { spawn "hyprpicker" "-a"; }
      Mod+Ctrl+V { spawn "kitty" "--class" "clipse" "-e" "clipse"; }
      F10 { spawn "bluetooth_toggle"; }
      Alt+F12 { spawn "osc-mullvad" "toggle"; }

      // Audio Scripts
      Alt+A { spawn "osc-soundctl" "switch"; }
      Alt+Ctrl+A { spawn "osc-soundctl" "switch-mic"; }

      // Media Scripts
      Alt+E { spawn "osc-spotify"; }
      Alt+Ctrl+N { spawn "osc-spotify" "next"; }
      Alt+Ctrl+B { spawn "osc-spotify" "prev"; }
      Alt+Ctrl+E { spawn "mpc-control" "toggle"; }
      Alt+I { spawn "hypr-vlc_toggle"; }
    }
  '';

  # ----------------------------------------------------------------------------
  # Keybinds - MPV manager
  # ----------------------------------------------------------------------------
  bindsMpv = ''
    binds {
      // ========================================================================
      // MPV Manager
      // ========================================================================
      Ctrl+Alt+1 { spawn "mpv-manager" "start"; }
      Alt+1 { spawn "mpv-manager" "playback"; }
      Alt+2 { spawn "mpv-manager" "play-yt"; }
      Alt+3 { spawn "mpv-manager" "stick"; }
      Alt+4 { spawn "mpv-manager" "move"; }
      Alt+5 { spawn "mpv-manager" "save-yt"; }
      Alt+6 { spawn "mpv-manager" "wallpaper"; }
    }
  '';

  # ----------------------------------------------------------------------------
  # Keybinds - Workspaces
  # ----------------------------------------------------------------------------
  bindsWorkspaces = ''
    binds {
      // ========================================================================
      // Workspace Management
      // ========================================================================

      // Focus Workspace
      Mod+1 { focus-workspace "1"; }
      Mod+2 { focus-workspace "2"; }
      Mod+3 { focus-workspace "3"; }
      Mod+4 { focus-workspace "4"; }
      Mod+5 { focus-workspace "5"; }
      Mod+6 { focus-workspace "6"; }
      Mod+7 { focus-workspace "7"; }
      Mod+8 { focus-workspace "8"; }
      Mod+9 { focus-workspace "9"; }

      // Move to Workspace
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

  # ----------------------------------------------------------------------------
  # Keybinds - Monitor management
  # ----------------------------------------------------------------------------
  bindsMonitors = ''
    binds {
      // ========================================================================
      // Monitor Management
      // ========================================================================
      Mod+A { spawn "niri" "msg" "action" "focus-monitor-next"; }
      Mod+E { spawn "niri" "msg" "action" "move-workspace-to-monitor-next"; }
      Mod+Escape { spawn "sh" "-lc" "niri msg action move-workspace-to-monitor-next || niri msg action focus-monitor-next"; }
    }
  '';

  # ----------------------------------------------------------------------------
  # Window rules
  # ----------------------------------------------------------------------------
  rulesConfig = ''
    // ========================================================================
    // Window Rules
    // ========================================================================

    // Global Styling
    window-rule {
      geometry-corner-radius 12;
      clip-to-geometry true;
    }

    // Floating Windows
    window-rule {
      match is-floating=true;
      shadow { on; }
    }

    // QuickShell
    window-rule {
      match app-id=r#"^org\.quickshell$"#;
      open-floating true;
    }

    // Variable Refresh Rate
    window-rule {
      match app-id=r#"^mpv$"#;
      variable-refresh-rate true;
    }

    // Picture-in-Picture
    window-rule {
      match title=r#"(?i)^picture[- ]in[- ]picture$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // MPV (non-PiP)
    window-rule {
      match app-id=r#"^mpv$"#;
      exclude title=r#"^Picture-in-Picture( - mpv)?$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // MPV (PiP)
    window-rule {
      match app-id=r#"^mpv$"# title=r#"^Picture-in-Picture( - mpv)?$"#;
      ${mkFixedFloating { w = 640; h = 360; x = 32; y = 96; opacity = "1.0"; }}
    }

    // Common dialogs / utilities
    window-rule {
      match title="^Open File$";
      match title="^File Upload$";
      match title="^Save As$";
      match title="^Confirm to replace files$";
      match title="^File Operation Progress$";
      match app-id=r#"^pavucontrol$"#;
      match app-id=r#"^nm-connection-editor$"#;
      match app-id=r#"^blueman-manager$"#;
      match app-id=r#"^polkit-gnome-authentication-agent-1$"#;
      match app-id=r#"^hyprland-share-picker$"#;
      open-floating true;
    }

    // Tmux
    window-rule {
      match app-id=r#"^(TmuxKenp|Tmux)$"#;
      match app-id=r#"^(kitty|org\.wezfurlong\.wezterm)$"# title=r#"^Tmux$"#;
      open-on-workspace "2";
      open-maximized true;
      open-maximized-to-edges true;
      open-focused true;
    }

    // Audio Mixer
    window-rule {
      match app-id=r#"^org\.pulseaudio\.pavucontrol$"#;
      ${mkProportionalFloating { w = 0.25; h = 0.80; x = 32; y = 144; }}
    }

    // Clipboard Manager
    window-rule {
      match app-id=r#"^clipse$"#;
      ${mkProportionalFloating { w = 0.25; h = 0.80; x = 32; y = 144; }}
    }

    // Notes
    window-rule {
      match app-id=r#"^anote$"#;
      ${mkFixedFloating { w = 1152; h = 864; }}
    }

    // Keyring / password prompt
    window-rule {
      match app-id=r#"^gcr-prompter$"#;
      ${mkFixedFloating { w = 600; h = 230; x = 0; y = 96; relativeTo = "top"; }}
    }

    // Workspace Assignments
    ${renderWorkspaceRules}

    // Better dialog placement
    window-rule {
      match app-id=r#"^(blueman-manager|nm-connection-editor)$"#;
      open-floating true;
      default-column-width { fixed 900; }
      default-window-height { fixed 650; }
      open-focused true;
    }

    window-rule {
      match app-id=r#"^polkit-gnome-authentication-agent-1$"#;
      open-floating true;
      default-column-width { fixed 520; }
      default-window-height { fixed 240; }
      open-focused true;
    }

    window-rule {
      match title=r#"^(Open File|File Upload|Save As|Confirm to replace files|File Operation Progress)$"#;
      open-floating true;
      default-column-width { proportion 0.60; }
      default-window-height { proportion 0.75; }
      open-focused true;
    }

    // Privacy - block from screencast
    window-rule {
      match app-id=r#"^org\.keepassxc\.KeePassXC$"#;
      match app-id=r#"^org\.gnome\.World\.Secrets$"#;
      block-out-from "screencast";
    }

    // Borderless apps
    window-rule {
      match app-id=r#"^(org\.gnome\..*|org\.wezfurlong\.wezterm|zen|com\.mitchellh\.ghostty|kitty|firefox|brave-browser)$"#;
      match app-id=r#"^(Kenp|Ai|CompecTA|Whats|Exclude|brave-youtube\.com__-Default|ferdium)$"#;
      draw-border-with-background false;
    }

    // Inactive dimming
    window-rule {
      match is-active=false;
      opacity 0.95;
    }

    // ========================================================================
    // Layer Rules
    // ========================================================================
    layer-rule {
      match namespace=r#"^dms:blurwallpaper$"#;
      place-within-backdrop true;
    }

    layer-rule {
      match namespace="^notifications$";
      block-out-from "screencast";
    }
  '';

  # ----------------------------------------------------------------------------
  # Animations
  # ----------------------------------------------------------------------------
  animationsConfig = ''
    animations {
      workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001;
      }

      window-open {
        duration-ms 150;
        curve "ease-out-expo";
      }
      window-close {
        duration-ms 150;
        curve "ease-out-quad";
      }

      horizontal-view-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }
      window-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }
      window-resize {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }

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

  # ----------------------------------------------------------------------------
  # Gestures
  # ----------------------------------------------------------------------------
  gesturesConfig = ''
    gestures {
      dnd-edge-view-scroll {
        trigger-width 30;
        delay-ms 100;
        max-speed 1500;
      }
      hot-corners {
        off;
      }
    }
  '';

  # ----------------------------------------------------------------------------
  # Recent windows
  # ----------------------------------------------------------------------------
  recentWindowsConfig = ''
    recent-windows {
      debounce-ms 0;
      open-delay-ms 0;
      highlight {
        active-color "${palette.mauveFF}";
        urgent-color "${palette.redFF}";
        padding 24;
        corner-radius 12;
      }
      previews {
        max-height 720;
        max-scale 0.6;
      }
    }
  '';

  # ----------------------------------------------------------------------------
  # Colors reference (documentation-only)
  # ----------------------------------------------------------------------------
  colorsReference = ''
    // ========================================================================
    // Catppuccin Color Palette Reference
    // ========================================================================
    // Accents:  cyan=${palette.cyan} sky=${palette.sky} mauve=${palette.mauve} red=${palette.red}
    // Surfaces: surface0=${palette.surface0} surface1=${palette.surface1}
  '';

  # ----------------------------------------------------------------------------
  # Hardware configuration (example)
  # ----------------------------------------------------------------------------
  hardwareConfigDefault = ''
    // ========================================================================
    // Hardware Configuration
    // ========================================================================

    // Named Workspaces (1-9)
    workspace "1" { open-on-output "DP-3"; }
    workspace "2" { open-on-output "DP-3"; }
    workspace "3" { open-on-output "DP-3"; }
    workspace "4" { open-on-output "DP-3"; }
    workspace "5" { open-on-output "DP-3"; }
    workspace "6" { open-on-output "DP-3"; }
    workspace "7" { open-on-output "eDP-1"; }
    workspace "8" {
      open-on-output "eDP-1";
      layout {
        gaps 20;
        border {
          on;
          width 1;
          active-color "${palette.sky}";
          inactive-color "${palette.surface0}";
        }
      }
    }
    workspace "9" { open-on-output "eDP-1"; }

    // Monitor Configuration
    output "DP-3" {
      mode "2560x1440@59.951";
      position x=0 y=0;
      scale 1.0;
    }

    output "eDP-1" {
      mode "1920x1200@60.003";
      position x=320 y=1440;
      scale 1.0;
      variable-refresh-rate on-demand=true;
    }
  '';

  # ----------------------------------------------------------------------------
  # Main config
  # ----------------------------------------------------------------------------
  mainConfig = ''
    // ========================================================================
    // Niri Configuration - DankMaterialShell Edition
    // ========================================================================

    environment {
      XDG_CURRENT_DESKTOP "niri";
      QT_QPA_PLATFORM "wayland";
      ELECTRON_OZONE_PLATFORM_HINT "auto";
      QT_QPA_PLATFORMTHEME "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 "gtk3";

      // Use a stable SSH agent socket provided by gnome-keyring on Wayland.
      // This helps prevent late-session passphrase prompts and gcr-prompter popups.
      SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/keyring/ssh";
    }

    cursor {
      hide-when-typing;
      hide-after-inactive-ms 1000;
    }

    prefer-no-csd;

    hotkey-overlay {
      skip-at-startup;
      hide-not-bound;
    }

    // Startup Applications
    // Export session variables into systemd --user and D-Bus activation env.
    spawn-at-startup "systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "XDG_SESSION_TYPE" "XDG_SESSION_DESKTOP" "NIRI_SOCKET" "SSH_AUTH_SOCK";
    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "XDG_SESSION_TYPE" "XDG_SESSION_DESKTOP" "NIRI_SOCKET" "SSH_AUTH_SOCK";

    // Clipboard manager
    spawn-at-startup "clipse" "-listen";

    // Focus preferred monitor if present (best-effort)
    spawn-at-startup "sh" "-lc" "if niri msg outputs 2>/dev/null | grep -q '(DP-3)'; then niri msg action focus-monitor DP-3; fi";

    // nirius daemon (required for nirius CLI commands)
    ${lib.optionalString cfg.enableNirius ''spawn-at-startup "${bins.niriusd}";''}

    // niriswitcher (optional)
    ${lib.optionalString cfg.enableNiriswitcher ''spawn-at-startup "${bins.niriuswitcher}";''}

    // Input Configuration
    input {
      workspace-auto-back-and-forth;
      focus-follows-mouse max-scroll-amount="0%";

      keyboard {
        xkb {
          layout "tr"
          variant "f"
          options "ctrl:nocaps"
        }
        repeat-delay 250
        repeat-rate 35
      }

      touchpad {
        tap
        dwt
        drag-lock
        tap-button-map "left-right-middle"
        middle-emulation
        click-method "clickfinger"
        accel-profile "flat"
        accel-speed 1.0
        scroll-method "two-finger"
        scroll-factor 1.0
      }

      mouse {
        accel-profile "flat"
        accel-speed 0.0
        scroll-factor 1.0
      }

      trackpoint {
        accel-profile "flat"
        accel-speed 0.0
        middle-emulation
        scroll-method "on-button-down"
        scroll-button 273
        scroll-button-lock
      }
    }

    // Switch Events
    switch-events {
      lid-close { spawn "${bins.niriLock}"; }
    }

    // Modular Configuration Includes
    include "dms/hardware.kdl";
    include "dms/layout.kdl";
    include "dms/binds-core.kdl";
    include "dms/binds-dms.kdl";
    include "dms/binds-apps.kdl";
    include "dms/binds-mpv.kdl";
    include "dms/binds-workspaces.kdl";
    include "dms/binds-monitors.kdl";
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
      default =
        if inputs ? niri && inputs.niri ? packages
        then inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri
        else pkgs.niri;
      description = "Niri compositor package";
    };

    enableNirius = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install nirius daemon and CLI helpers";
    };

    enableNiriswitcher = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install niriswitcher application switcher";
    };

    enableHardwareConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable static output/workspace pinning (host-specific)";
    };

    hardwareConfig = lib.mkOption {
      type = lib.types.lines;
      default = hardwareConfigDefault;
      description = "Niri KDL snippet for outputs/workspaces";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package ]
      ++ lib.optional cfg.enableNirius pkgs.nirius
      ++ lib.optional cfg.enableNiriswitcher pkgs.niriswitcher;

    # Main Configuration
    xdg.configFile."niri/config.kdl".text = mainConfig;

    # Modular DMS Configurations
    xdg.configFile."niri/dms/hardware.kdl".text =
      if cfg.enableHardwareConfig then cfg.hardwareConfig else "";
    xdg.configFile."niri/dms/layout.kdl".text = layoutConfig;
    xdg.configFile."niri/dms/binds-core.kdl".text = bindsCore;
    xdg.configFile."niri/dms/binds-dms.kdl".text = bindsDms;
    xdg.configFile."niri/dms/binds-apps.kdl".text = bindsApps;
    xdg.configFile."niri/dms/binds-mpv.kdl".text = bindsMpv;
    xdg.configFile."niri/dms/binds-workspaces.kdl".text = bindsWorkspaces;
    xdg.configFile."niri/dms/binds-monitors.kdl".text = bindsMonitors;
    xdg.configFile."niri/dms/rules.kdl".text = rulesConfig;
    xdg.configFile."niri/dms/animations.kdl".text = animationsConfig;
    xdg.configFile."niri/dms/gestures.kdl".text = gesturesConfig;
    xdg.configFile."niri/dms/recent-windows.kdl".text = recentWindowsConfig;
    xdg.configFile."niri/dms/colors.kdl".text = colorsReference;

    # Deprecated placeholder (kept to avoid stale references)
    xdg.configFile."niri/dms/alttab.kdl".text = "";
  };
}

