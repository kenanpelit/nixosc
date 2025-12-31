# modules/home/niri/binds.nix
# ==============================================================================
# Niri Keybindings - Modular Configuration
#
# Contains key mapping categories:
# - DMS Integration, Core Window Management, Nirius Window Router, Apps, MPV,
#   Workspaces, Monitors
# Imported by default.nix
#
# Note: "binds {}" wrapper is REMOVED here. It is added in default.nix to ensure
# a single binds block in the final config.
# ==============================================================================
{ lib, pkgs, bins, enableNiriusBinds, ... }:
{
  dms = ''
      // ========================================================================
      // DMS Integration
      // ========================================================================

      // Launchers
      Mod+Space repeat=false hotkey-overlay-title="DMS Spotlight" { spawn "${bins.dms}" "ipc" "call" "spotlight" "toggle"; }
      Mod+D repeat=false hotkey-overlay-title="DMS Dash" { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" ""; }
      Mod+N repeat=false hotkey-overlay-title="DMS Notifications" { spawn "${bins.dms}" "ipc" "call" "notifications" "toggle"; }
      Mod+C repeat=false hotkey-overlay-title="DMS Control Center" { spawn "${bins.dms}" "ipc" "call" "control-center" "toggle"; }
      Mod+V repeat=false hotkey-overlay-title="DMS Clipboard" { spawn "${bins.dms}" "ipc" "call" "clipboard" "toggle"; }
      Mod+Shift+D repeat=false hotkey-overlay-title="DMS Dash Overview" { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" "overview"; }
      Mod+Shift+P repeat=false hotkey-overlay-title="DMS Process List" { spawn "${bins.dms}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Ctrl+N repeat=false hotkey-overlay-title="DMS Notepad" { spawn "${bins.dms}" "ipc" "call" "notepad" "open"; }
      Mod+Comma repeat=false hotkey-overlay-title="DMS Settings" { spawn "${bins.dms}" "ipc" "call" "settings" "focusOrToggle"; }
      Mod+Delete repeat=false hotkey-overlay-title="DMS Power Menu" { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }
      Ctrl+Alt+Delete repeat=false hotkey-overlay-title=null { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }

      // Wallpaper & Theming
      Mod+Y repeat=false hotkey-overlay-title="DMS Wallpaper" { spawn "${bins.dms}" "ipc" "call" "dankdash" "wallpaper"; }
      Mod+W hotkey-overlay-title="Wallpaper Next" { spawn "${bins.dms}" "ipc" "call" "wallpaper" "next"; }
      Mod+Shift+W hotkey-overlay-title="Wallpaper Prev" { spawn "${bins.dms}" "ipc" "call" "wallpaper" "prev"; }
      Mod+Shift+T repeat=false hotkey-overlay-title="Theme Toggle" { spawn "${bins.dms}" "ipc" "call" "theme" "toggle"; }
      Mod+Shift+N repeat=false hotkey-overlay-title="Night Toggle" { spawn "${bins.dms}" "ipc" "call" "night" "toggle"; }

      // Bar & Dock
      Mod+B repeat=false hotkey-overlay-title="UI Bar Toggle" { spawn "${bins.dms}" "ipc" "call" "bar" "toggle" "index" "0"; }
      Mod+Ctrl+B repeat=false hotkey-overlay-title="UI Bar Auto Hide" { spawn "${bins.dms}" "ipc" "call" "bar" "toggleAutoHide" "index" "0"; }
      Mod+Shift+B repeat=false hotkey-overlay-title="UI Dock Toggle" { spawn "${bins.dms}" "ipc" "call" "dock" "toggle"; }

      // Security
      Alt+L repeat=false hotkey-overlay-title="Session Lock" { spawn "${bins.niriSet}" "lock"; }
      Mod+Shift+Delete repeat=false hotkey-overlay-title="Session Inhibit Toggle" { spawn "${bins.dms}" "ipc" "call" "inhibit" "toggle"; }

      // Audio
      XF86AudioRaiseVolume allow-when-locked=true hotkey-overlay-title="Audio: Volume +" { spawn "${bins.dms}" "ipc" "call" "audio" "increment" "5"; }
      XF86AudioLowerVolume allow-when-locked=true hotkey-overlay-title="Audio: Volume -" { spawn "${bins.dms}" "ipc" "call" "audio" "decrement" "5"; }
      XF86AudioMute allow-when-locked=true hotkey-overlay-title="Audio: Mute" { spawn "${bins.dms}" "ipc" "call" "audio" "mute"; }
      XF86AudioMicMute allow-when-locked=true hotkey-overlay-title="Mic: Mute" { spawn "${bins.dms}" "ipc" "call" "audio" "micmute"; }
      //F4 allow-when-locked=true { spawn "osc-soundctl" "mic" "mute"; }
      Mod+Alt+A repeat=false hotkey-overlay-title="Audio Cycle Output" { spawn "${bins.dms}" "ipc" "call" "audio" "cycleoutput"; }
      Mod+Alt+P repeat=false hotkey-overlay-title="Audio Pavucontrol" { spawn "pavucontrol"; }

      // Media (MPRIS)
      XF86AudioPlay allow-when-locked=true hotkey-overlay-title="Media: Play/Pause" { spawn "${bins.dms}" "ipc" "call" "mpris" "playPause"; }
      XF86AudioNext allow-when-locked=true hotkey-overlay-title="Media: Next" { spawn "${bins.dms}" "ipc" "call" "mpris" "next"; }
      XF86AudioPrev allow-when-locked=true hotkey-overlay-title="Media: Previous" { spawn "${bins.dms}" "ipc" "call" "mpris" "previous"; }
      XF86AudioStop allow-when-locked=true hotkey-overlay-title="Media: Stop" { spawn "${bins.dms}" "ipc" "call" "mpris" "stop"; }

      // Brightness
      XF86MonBrightnessUp allow-when-locked=true hotkey-overlay-title="Brightness: +" { spawn "${bins.dms}" "ipc" "call" "brightness" "increment" "5" ""; }
      XF86MonBrightnessDown allow-when-locked=true hotkey-overlay-title="Brightness: -" { spawn "${bins.dms}" "ipc" "call" "brightness" "decrement" "5" ""; }

      // Help
      Mod+Alt+Slash repeat=false hotkey-overlay-title="DMS Keybinds Settings" { spawn "${bins.dms}" "ipc" "call" "settings" "openWith" "keybinds"; }
      Mod+F1 repeat=false hotkey-overlay-title="DMS Keybinds (Niri)" { spawn "${bins.dms}" "ipc" "call" "keybinds" "toggle" "niri"; }
      Alt+F1 repeat=false hotkey-overlay-title="Help Show Hotkeys" { show-hotkey-overlay; }

      Alt+Tab hotkey-overlay-title="Switch Windows" { spawn "${bins.dms}" "ipc" "call" "spotlight" "openQuery" "!"; }
  '';

  core = ''
      // ========================================================================
      // Core Window Management
      // ========================================================================

      // Applications
      Mod+T repeat=false hotkey-overlay-title="App Terminal" { spawn "${bins.kitty}"; }

      // Window Controls
      Mod+Q hotkey-overlay-title="Window: Close" { close-window; }
      Mod+M hotkey-overlay-title="Column: Maximize" { maximize-column; }
      Alt+G repeat=false hotkey-overlay-title="Window Maximize To Edges" { maximize-window-to-edges; }
      Mod+Ctrl+F repeat=false hotkey-overlay-title="Window Windowed Fullscreen" { fullscreen-window; }
      Mod+O hotkey-overlay-title="Window: Toggle Opacity Rule" { toggle-window-rule-opacity; }
      Mod+R hotkey-overlay-title="Column: Next Preset Width" { switch-preset-column-width; }
      Mod+Shift+R hotkey-overlay-title="Column: Width 75%" { set-column-width "75%"; }
      Mod+0 hotkey-overlay-title="Column: Center" { center-column; }
      Mod+G repeat=false hotkey-overlay-title="Window Float ↔ Tile" { spawn "${bins.niriSet}" "toggle-window-mode"; }
      Mod+Z repeat=false hotkey-overlay-title="Zen Mode Toggle" { spawn "${bins.niriSet}" "zen"; }
      Mod+P repeat=false hotkey-overlay-title="Pin Window (PIP)" { spawn "${bins.niriSet}" "pin"; }

      // NOTE:
      // Mod+BackSpace is reserved for Nirius scratchpad toggle (see nirius section).
      // This binding is moved to Mod+Ctrl+BackSpace to avoid a hard duplicate-key error.
      Mod+Ctrl+BackSpace hotkey-overlay-title="Focus: Float ↔ Tile" { switch-focus-between-floating-and-tiling; }

      // Dynamic screencast target (OBS: "niri Dynamic Cast Target")
      Mod+F9 repeat=false hotkey-overlay-title="Cast: Window" { set-dynamic-cast-window; }
      Mod+Shift+F9 repeat=false hotkey-overlay-title="Cast: Monitor" { set-dynamic-cast-monitor; }
      Mod+Ctrl+F9 repeat=false hotkey-overlay-title="Cast: Clear" { clear-dynamic-cast-target; }
      Mod+Alt+F9 repeat=false hotkey-overlay-title="Cast: Pick Window" { spawn "${bins.niriSet}" "cast" "pick"; }

      // Column Operations
      Mod+BracketLeft hotkey-overlay-title="Column: Consume/Expel Left" { consume-or-expel-window-left; }
      Mod+BracketRight hotkey-overlay-title="Column: Consume/Expel Right" { consume-or-expel-window-right; }

      // Navigation
      Mod+S repeat=false hotkey-overlay-title="Overview Toggle" { toggle-overview; }
      Mod+Left hotkey-overlay-title="Focus: Left" { focus-column-left; }
      Mod+Right hotkey-overlay-title="Focus: Right" { focus-column-right; }
      Mod+Up hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+Down hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }
      Mod+H hotkey-overlay-title="Focus: Left" { focus-column-left; }
      Mod+L hotkey-overlay-title="Focus: Right" { focus-column-right; }
      Mod+K hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+J hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }

      // Monitor Focus
      Mod+Alt+H hotkey-overlay-title="Monitor: Focus Left" { focus-monitor-left; }
      Mod+Alt+L hotkey-overlay-title="Monitor: Focus Right" { focus-monitor-right; }
      Mod+Alt+K hotkey-overlay-title="Monitor: Focus Up" { focus-monitor-up; }
      Mod+Alt+J hotkey-overlay-title="Monitor: Focus Down" { focus-monitor-down; }
      Mod+Alt+Left hotkey-overlay-title="Monitor: Focus Left" { focus-monitor-left; }
      Mod+Alt+Right hotkey-overlay-title="Monitor: Focus Right" { focus-monitor-right; }
      Mod+Alt+Up hotkey-overlay-title="Monitor: Focus Up" { focus-monitor-up; }
      Mod+Alt+Down hotkey-overlay-title="Monitor: Focus Down" { focus-monitor-down; }

      // Move Windows
      Mod+Shift+Left hotkey-overlay-title="Move: Column Left" { move-column-left; }
      Mod+Shift+Right hotkey-overlay-title="Move: Column Right" { move-column-right; }
      Mod+Shift+Up hotkey-overlay-title="Move: Window Up" { move-window-up; }
      Mod+Shift+Down hotkey-overlay-title="Move: Window Down" { move-window-down; }
      Mod+Shift+H hotkey-overlay-title="Move: Column Left" { move-column-left; }
      Mod+Shift+L hotkey-overlay-title="Move: Column Right" { move-column-right; }
      Mod+Shift+K hotkey-overlay-title="Move: Window Up" { move-window-up; }
      Mod+Shift+J hotkey-overlay-title="Move: Window Down" { move-window-down; }

      // Move to Monitor
      Mod+Ctrl+Left hotkey-overlay-title="Move: To Monitor Left" { move-column-to-monitor-left; }
      Mod+Ctrl+Right hotkey-overlay-title="Move: To Monitor Right" { move-column-to-monitor-right; }
      Mod+Ctrl+Up hotkey-overlay-title="Move: To Monitor Up" { move-column-to-monitor-up; }
      Mod+Ctrl+Down hotkey-overlay-title="Move: To Monitor Down" { move-column-to-monitor-down; }

      // Alternative Navigation
      // (PageUp/PageDown bindings removed; keep arrows + vim keys for navigation)

      // Screenshots
      Print repeat=false hotkey-overlay-title="Screenshot Selection" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshot"; }
      Ctrl+Print repeat=false hotkey-overlay-title="Screenshot Screen" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotScreen"; }
      Alt+Print repeat=false hotkey-overlay-title="Screenshot Window" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotWindow"; }

      // Reload config (fast iteration)
      // Not all niri versions expose `load-config-file` as a direct config action,
      // but it is always available via the IPC CLI.
      Mod+Ctrl+Alt+R repeat=false hotkey-overlay-title="Niri Reload Config" { spawn "niri" "msg" "action" "load-config-file"; }

      // Mouse Wheel & Opacity
      Mod+Shift+WheelScrollDown hotkey-overlay-title="Opacity: -10%" { spawn "niri" "msg" "action" "set-window-opacity" "-0.1"; }
      Mod+Shift+WheelScrollUp   hotkey-overlay-title="Opacity: +10%" { spawn "niri" "msg" "action" "set-window-opacity" "+0.1"; }
      Mod+Ctrl+Shift+J hotkey-overlay-title="Opacity: -10%" { spawn "niri" "msg" "action" "set-window-opacity" "-0.1"; }
      Mod+Ctrl+Shift+K hotkey-overlay-title="Opacity: +10%" { spawn "niri" "msg" "action" "set-window-opacity" "+0.1"; }
      Mod+Ctrl+Shift+Down hotkey-overlay-title="Opacity: -10%" { spawn "niri" "msg" "action" "set-window-opacity" "-0.1"; }
      Mod+Ctrl+Shift+Up   hotkey-overlay-title="Opacity: +10%" { spawn "niri" "msg" "action" "set-window-opacity" "+0.1"; }
      
      Mod+WheelScrollDown cooldown-ms=150 hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }
      Mod+WheelScrollUp   cooldown-ms=150 hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+WheelScrollRight hotkey-overlay-title="Focus: Right" { focus-column-right; }
      Mod+WheelScrollLeft  hotkey-overlay-title="Focus: Left" { focus-column-left; }
  '';

  nirius = ''
      // ========================================================================
      // Nirius Window Router (optional)
      //
      // Requirements:
      // - niriusd must be running (recommended: spawn-at-startup "niriusd")
      //
      // Design:
      // - Mod+Alt       => "bring/manage" (focus-or-spawn)
      // - Mod+Alt+Shift => "pull-to-me" (move-to-current-workspace + focus)
      //
      // Notes:
      // - No Grave key usage (layout-safe)
      // - Avoids collisions with existing Mod+Alt arrows and Mod+Alt+A/P
      // ========================================================================

      ${lib.optionalString enableNiriusBinds ''
        // ----------------------------------------------------------------------
        // Smart Focus-or-Spawn (daily drivers)
        // ----------------------------------------------------------------------

        Mod+Alt+T repeat=false hotkey-overlay-title="Nirius: Terminal (focus or spawn)" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^kitty$" "${bins.kitty}"; }
        Mod+Alt+B repeat=false hotkey-overlay-title="Nirius: Browser (focus or spawn)" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "(brave|brave-browser|firefox|zen|chromium)" "brave"; }
        Mod+Alt+M repeat=false hotkey-overlay-title="Nirius: Music (focus or spawn)" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "spotify"; }
        Mod+Alt+N repeat=false hotkey-overlay-title="Nirius: Notes (focus or spawn)" { spawn "${bins.nirius}" "focus-or-spawn" "--title" "(Anotes|Notes)" "anotes"; }

        // ----------------------------------------------------------------------
        // Pull-to-Me (move matching windows here + focus)
        // ----------------------------------------------------------------------

        Mod+Alt+Shift+T repeat=false hotkey-overlay-title="Nirius: Pull Terminal here" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^kitty$" "--focus"; }
        Mod+Alt+Shift+B repeat=false hotkey-overlay-title="Nirius: Pull Browser here" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "(brave|brave-browser|firefox|zen|chromium)" "--focus"; }
        Mod+Alt+Shift+M repeat=false hotkey-overlay-title="Nirius: Pull Music here" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "--focus"; }
        Mod+Alt+Shift+N repeat=false hotkey-overlay-title="Nirius: Pull Notes here" { spawn "${bins.nirius}" "move-to-current-workspace" "--title" "(Anotes|Notes)" "--focus"; }

        // ----------------------------------------------------------------------
        // Scratchpad (layout-safe; BackSpace-based)
        // ----------------------------------------------------------------------

        // Toggle scratchpad state for the focused window (send/unsend) 
        Mod+BackSpace repeat=false hotkey-overlay-title="Nirius: Scratchpad Toggle" { spawn "${bins.nirius}" "scratchpad-toggle"; }

        // Show one scratchpad window (cycles if multiple)
        Alt+BackSpace repeat=false hotkey-overlay-title="Nirius: Scratchpad Show/Cycle" { spawn "${bins.nirius}" "scratchpad-show"; }

        // Show all scratchpad windows (toggle)
        Mod+Alt+BackSpace repeat=false hotkey-overlay-title="Nirius: Scratchpad Show All" { spawn "${bins.nirius}" "scratchpad-show-all"; }

        // ----------------------------------------------------------------------
        // Marks (role-based windows; cycles if multiple)
        // Recommended marks: term, web, media, notes
        // ----------------------------------------------------------------------

        // Default mark (__default__) toggle for quick tagging
        Mod+Alt+0 repeat=false hotkey-overlay-title="Nirius: Toggle Default Mark" { spawn "${bins.nirius}" "toggle-mark"; }

        // Assign/toggle role marks for the currently focused window
        Mod+Alt+Shift+1 repeat=false hotkey-overlay-title="Nirius: Toggle Mark 'term'" { spawn "${bins.nirius}" "toggle-mark" "term"; }
        Mod+Alt+Shift+2 repeat=false hotkey-overlay-title="Nirius: Toggle Mark 'web'" { spawn "${bins.nirius}" "toggle-mark" "web"; }
        Mod+Alt+Shift+3 repeat=false hotkey-overlay-title="Nirius: Toggle Mark 'media'" { spawn "${bins.nirius}" "toggle-mark" "media"; }
        Mod+Alt+Shift+4 repeat=false hotkey-overlay-title="Nirius: Toggle Mark 'notes'" { spawn "${bins.nirius}" "toggle-mark" "notes"; }

        // Jump to role marks (cycles if multiple)
        Mod+Alt+1 repeat=false hotkey-overlay-title="Nirius: Focus Mark 'term'" { spawn "${bins.nirius}" "focus-marked" "term"; }
        Mod+Alt+2 repeat=false hotkey-overlay-title="Nirius: Focus Mark 'web'" { spawn "${bins.nirius}" "focus-marked" "web"; }
        Mod+Alt+3 repeat=false hotkey-overlay-title="Nirius: Focus Mark 'media'" { spawn "${bins.nirius}" "focus-marked" "media"; }
        Mod+Alt+4 repeat=false hotkey-overlay-title="Nirius: Focus Mark 'notes'" { spawn "${bins.nirius}" "focus-marked" "notes"; }

        // Debug: list all marked windows
        Mod+Alt+Shift+I repeat=false hotkey-overlay-title="Nirius: List Marked (all)" { spawn "${bins.nirius}" "list-marked" "--all"; }

        // ----------------------------------------------------------------------
        // Follow Mode (floating windows follow workspace changes)
        // ----------------------------------------------------------------------

        Mod+Alt+F repeat=false hotkey-overlay-title="Nirius: Toggle Follow Mode" { spawn "${bins.nirius}" "toggle-follow-mode"; }
      ''}
  '';

  apps = ''
      // ========================================================================
      // Custom Applications
      // ========================================================================

      Mod+Alt+Return repeat=false hotkey-overlay-title="SemsuMo Daily" { spawn "semsumo" "launch" "--daily" "-all"; }
      Mod+Shift+A repeat=false hotkey-overlay-title="Niri Arrange Windows" { spawn "${bins.niriSet}" "arrange-windows"; }
      Mod+Ctrl+Alt+Left hotkey-overlay-title="Column Width: -100" { spawn "niri" "msg" "action" "set-column-width" "-100"; }
      Mod+Ctrl+Alt+Right hotkey-overlay-title="Column Width: +100" { spawn "niri" "msg" "action" "set-column-width" "+100"; }
      Mod+Ctrl+Alt+Up hotkey-overlay-title="Window Height: -100" { spawn "niri" "msg" "action" "set-window-height" "-100"; }
      Mod+Ctrl+Alt+Down hotkey-overlay-title="Window Height: +100" { spawn "niri" "msg" "action" "set-window-height" "+100"; }

      // Launchers
      Alt+Space repeat=false hotkey-overlay-title="Rofi Launcher" { spawn "rofi-launcher"; }
      Mod+Ctrl+Space repeat=false hotkey-overlay-title="Walk Launcher" { spawn "walk"; }
      Mod+Ctrl+S repeat=false hotkey-overlay-title="Sticky ↔ Stage Toggle" { spawn "nsticky-toggle"; }

      // File Managers
      Mod+F repeat=false hotkey-overlay-title="Files Nemo" { spawn "nemo"; }
      Alt+F repeat=false hotkey-overlay-title="Files Yazi" { spawn "${bins.kitty}" "-e" "yazi"; }

      // Special Apps
      Alt+T repeat=false hotkey-overlay-title="KKENP Start" { spawn "start-kkenp"; }
      Alt+N repeat=false hotkey-overlay-title="Notes Anotes" { spawn "anotes"; }

      // Tools
      Mod+Shift+C repeat=false hotkey-overlay-title="Tool Color Picker" { spawn "hyprpicker" "-a"; }
      Mod+Ctrl+V repeat=false hotkey-overlay-title="Clipboard Clipse" { spawn "${bins.kitty}" "--class" "clipse" "-e" "${bins.clipse}"; }
      F10 repeat=false hotkey-overlay-title="Bluetooth Toggle" { spawn "bluetooth_toggle"; }
      Alt+F12 repeat=false hotkey-overlay-title="VPN Mullvad Toggle" { spawn "osc-mullvad" "toggle"; }

      // Audio Scripts
      Alt+A repeat=false hotkey-overlay-title="Audio Switch Output" { spawn "osc-soundctl" "switch"; }
      Alt+Ctrl+A repeat=false hotkey-overlay-title="Audio Switch Mic" { spawn "osc-soundctl" "switch-mic"; }

      // Media Scripts
      Alt+E repeat=false hotkey-overlay-title="Spotify Toggle" { spawn "osc-spotify"; }
      Alt+Ctrl+N repeat=false hotkey-overlay-title="Spotify Next" { spawn "osc-spotify" "next"; }
      Alt+Ctrl+B repeat=false hotkey-overlay-title="Spotify Previous" { spawn "osc-spotify" "prev"; }
      Alt+Ctrl+E repeat=false hotkey-overlay-title="MPC Toggle" { spawn "mpc-control" "toggle"; }
      Alt+I repeat=false hotkey-overlay-title="VLC Toggle" { spawn "vlc-toggle"; }
  '';

  mpv = ''
      // ========================================================================
      // MPV Manager
      // ========================================================================
      Mod+Ctrl+1 repeat=false hotkey-overlay-title="MPV Playback" { spawn "mpv-manager" "playback"; }
      Mod+Ctrl+2 repeat=false hotkey-overlay-title="MPV Play YouTube" { spawn "mpv-manager" "play-yt"; }
      Mod+Ctrl+3 repeat=false hotkey-overlay-title="MPV Stick" { spawn "mpv-manager" "stick"; }
      Mod+Ctrl+4 repeat=false hotkey-overlay-title="MPV Move" { spawn "mpv-manager" "move"; }
      Mod+Ctrl+5 repeat=false hotkey-overlay-title="MPV Save YouTube" { spawn "mpv-manager" "save-yt"; }
      Mod+Ctrl+6 repeat=false hotkey-overlay-title="MPV Wallpaper" { spawn "mpv-manager" "wallpaper"; }
  '';

  workspaces = ''
      // ========================================================================
      // Workspace Management
      // ========================================================================

      // Focus Workspace
      Mod+1 hotkey-overlay-title="Workspace 1" { focus-workspace "1"; }
      Mod+2 hotkey-overlay-title="Workspace 2" { focus-workspace "2"; }
      Mod+3 hotkey-overlay-title="Workspace 3" { focus-workspace "3"; }
      Mod+4 hotkey-overlay-title="Workspace 4" { focus-workspace "4"; }
      Mod+5 hotkey-overlay-title="Workspace 5" { focus-workspace "5"; }
      Mod+6 hotkey-overlay-title="Workspace 6" { focus-workspace "6"; }
      Mod+7 hotkey-overlay-title="Workspace 7" { focus-workspace "7"; }
      Mod+8 hotkey-overlay-title="Workspace 8" { focus-workspace "8"; }
      Mod+9 hotkey-overlay-title="Workspace 9" { focus-workspace "9"; }

      // Move to Workspace
      Mod+Shift+1 hotkey-overlay-title="Move To WS 1" { move-column-to-workspace "1"; }
      Mod+Shift+2 hotkey-overlay-title="Move To WS 2" { move-column-to-workspace "2"; }
      Mod+Shift+3 hotkey-overlay-title="Move To WS 3" { move-column-to-workspace "3"; }
      Mod+Shift+4 hotkey-overlay-title="Move To WS 4" { move-column-to-workspace "4"; }
      Mod+Shift+5 hotkey-overlay-title="Move To WS 5" { move-column-to-workspace "5"; }
      Mod+Shift+6 hotkey-overlay-title="Move To WS 6" { move-column-to-workspace "6"; }
      Mod+Shift+7 hotkey-overlay-title="Move To WS 7" { move-column-to-workspace "7"; }
      Mod+Shift+8 hotkey-overlay-title="Move To WS 8" { move-column-to-workspace "8"; }
      Mod+Shift+9 hotkey-overlay-title="Move To WS 9" { move-column-to-workspace "9"; }
  '';

  monitors = ''
      // ========================================================================
      // Monitor Management
      // ========================================================================
      Mod+A repeat=false hotkey-overlay-title="Monitor Focus Next" { spawn "niri" "msg" "action" "focus-monitor-next"; }
      Mod+E repeat=false hotkey-overlay-title="Monitor Move WS Next" { spawn "niri" "msg" "action" "move-workspace-to-monitor-next"; }
      Mod+Escape repeat=false hotkey-overlay-title="Monitor Move WS / Focus Next" { spawn "sh" "-lc" "niri msg action move-workspace-to-monitor-next || niri msg action focus-monitor-next"; }
  '';
}
