# modules/home/niri/binds.nix
# ==============================================================================
# Niri Keybindings - Modular Configuration
#
# Contains key mapping categories:
# - DMS Integration, Core Window Management, Apps, MPV, Workspaces, Monitors
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
      Mod+Space hotkey-overlay-title="DMS: Spotlight" { spawn "${bins.dms}" "ipc" "call" "spotlight" "toggle"; }
      Mod+D hotkey-overlay-title="DMS: Dash" { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" ""; }
      Mod+N hotkey-overlay-title="DMS: Notifications" { spawn "${bins.dms}" "ipc" "call" "notifications" "toggle"; }
      Mod+C hotkey-overlay-title="DMS: Control Center" { spawn "${bins.dms}" "ipc" "call" "control-center" "toggle"; }
      Mod+V hotkey-overlay-title="DMS: Clipboard" { spawn "${bins.dms}" "ipc" "call" "clipboard" "toggle"; }
      Mod+Shift+D hotkey-overlay-title="DMS: Dash Overview" { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" "overview"; }
      Mod+Shift+P hotkey-overlay-title="DMS: Process List" { spawn "${bins.dms}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Ctrl+N hotkey-overlay-title="DMS: Notepad" { spawn "${bins.dms}" "ipc" "call" "notepad" "open"; }
      Mod+Comma hotkey-overlay-title="DMS: Settings" { spawn "${bins.dms}" "ipc" "call" "settings" "focusOrToggle"; }
      Mod+Delete hotkey-overlay-title="DMS: Power Menu" { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }
      Ctrl+Alt+Delete hotkey-overlay-title="DMS: Power Menu" { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }

      // Wallpaper & Theming
      Mod+Y hotkey-overlay-title="DMS: Wallpaper" { spawn "${bins.dms}" "ipc" "call" "dankdash" "wallpaper"; }
      Mod+W hotkey-overlay-title="Wallpaper: Next" { spawn "${bins.dms}" "ipc" "call" "wallpaper" "next"; }
      Mod+Shift+W hotkey-overlay-title="Wallpaper: Prev" { spawn "${bins.dms}" "ipc" "call" "wallpaper" "prev"; }
      Mod+Shift+T hotkey-overlay-title="Theme: Toggle" { spawn "${bins.dms}" "ipc" "call" "theme" "toggle"; }
      Mod+Shift+N hotkey-overlay-title="Night Mode: Toggle" { spawn "${bins.dms}" "ipc" "call" "night" "toggle"; }

      // Bar & Dock
      Mod+B hotkey-overlay-title="Bar: Toggle" { spawn "${bins.dms}" "ipc" "call" "bar" "toggle" "index" "0"; }
      Mod+Ctrl+B hotkey-overlay-title="Bar: Auto Hide" { spawn "${bins.dms}" "ipc" "call" "bar" "toggleAutoHide" "index" "0"; }
      Mod+Shift+B hotkey-overlay-title="Dock: Toggle" { spawn "${bins.dms}" "ipc" "call" "dock" "toggle"; }

      // Security
      Alt+L hotkey-overlay-title="Lock" { spawn "${bins.niriSet}" "lock"; }
      Mod+Shift+Delete hotkey-overlay-title="Inhibit: Toggle" { spawn "${bins.dms}" "ipc" "call" "inhibit" "toggle"; }

      // Audio
      XF86AudioRaiseVolume allow-when-locked=true hotkey-overlay-title="Audio: Volume +" { spawn "${bins.dms}" "ipc" "call" "audio" "increment" "5"; }
      XF86AudioLowerVolume allow-when-locked=true hotkey-overlay-title="Audio: Volume -" { spawn "${bins.dms}" "ipc" "call" "audio" "decrement" "5"; }
      XF86AudioMute allow-when-locked=true hotkey-overlay-title="Audio: Mute" { spawn "${bins.dms}" "ipc" "call" "audio" "mute"; }
      XF86AudioMicMute allow-when-locked=true hotkey-overlay-title="Mic: Mute" { spawn "${bins.dms}" "ipc" "call" "audio" "micmute"; }
      //F4 allow-when-locked=true { spawn "osc-soundctl" "mic" "mute"; }
      Mod+Alt+A hotkey-overlay-title="Audio: Cycle Output" { spawn "${bins.dms}" "ipc" "call" "audio" "cycleoutput"; }
      Mod+Alt+P hotkey-overlay-title="Audio: Pavucontrol" { spawn "pavucontrol"; }

      // Media (MPRIS)
      XF86AudioPlay allow-when-locked=true hotkey-overlay-title="Media: Play/Pause" { spawn "${bins.dms}" "ipc" "call" "mpris" "playPause"; }
      XF86AudioNext allow-when-locked=true hotkey-overlay-title="Media: Next" { spawn "${bins.dms}" "ipc" "call" "mpris" "next"; }
      XF86AudioPrev allow-when-locked=true hotkey-overlay-title="Media: Previous" { spawn "${bins.dms}" "ipc" "call" "mpris" "previous"; }
      XF86AudioStop allow-when-locked=true hotkey-overlay-title="Media: Stop" { spawn "${bins.dms}" "ipc" "call" "mpris" "stop"; }

      // Brightness
      XF86MonBrightnessUp allow-when-locked=true hotkey-overlay-title="Brightness: +" { spawn "${bins.dms}" "ipc" "call" "brightness" "increment" "5" ""; }
      XF86MonBrightnessDown allow-when-locked=true hotkey-overlay-title="Brightness: -" { spawn "${bins.dms}" "ipc" "call" "brightness" "decrement" "5" ""; }

      // Help
      Mod+Alt+Slash hotkey-overlay-title="DMS: Keybinds Settings" { spawn "${bins.dms}" "ipc" "call" "settings" "openWith" "keybinds"; }
      Mod+F1 hotkey-overlay-title="DMS: Keybinds (Niri)" { spawn "${bins.dms}" "ipc" "call" "keybinds" "toggle" "niri"; }
      Alt+F1 hotkey-overlay-title="Show Hotkeys" { show-hotkey-overlay; }

      Alt+Tab hotkey-overlay-title="Switch Windows" { spawn "${bins.dms}" "ipc" "call" "spotlight" "openQuery" "!"; }
  '';

  core = ''
      // ========================================================================
      // Core Window Management
      // ========================================================================

      // Applications
      Mod+Return hotkey-overlay-title="Terminal" { spawn "${bins.kitty}"; }
      Mod+T hotkey-overlay-title="Terminal" { spawn "${bins.kitty}"; }

      // Window Controls
      Mod+Q hotkey-overlay-title="Window: Close" { close-window; }
      Mod+F hotkey-overlay-title="Column: Maximize" { maximize-column; }
      Mod+Shift+F hotkey-overlay-title="Window: Fullscreen" { fullscreen-window; }
      Mod+O hotkey-overlay-title="Window: Toggle Opacity Rule" { toggle-window-rule-opacity; }
      Mod+R hotkey-overlay-title="Column: Next Preset Width" { switch-preset-column-width; }
      Mod+Shift+R hotkey-overlay-title="Column: Width 100%" { spawn "niri" "msg" "action" "set-column-width" "100%"; }
      Mod+Ctrl+R hotkey-overlay-title="Column: Width 50%" { spawn "niri" "msg" "action" "set-column-width" "50%"; }
      Mod+Shift+Space hotkey-overlay-title="Float ↔ Tile (preset)" { spawn "${bins.niriSet}" "toggle-window-mode"; }
      // Mod+Alt+Shift+Space hotkey-overlay-title="Tile (force)" { move-window-to-tiling; }
      Mod+Alt+Shift+Space hotkey-overlay-title="Tile (from float)" { move-window-to-tiling; }
      Mod+BackSpace hotkey-overlay-title="Focus: Float ↔ Tile" { switch-focus-between-floating-and-tiling; }

      // Column Operations
      Mod+BracketLeft hotkey-overlay-title="Column: Consume/Expel Left" { consume-or-expel-window-left; }
      Mod+BracketRight hotkey-overlay-title="Column: Consume/Expel Right" { consume-or-expel-window-right; }

      // Navigation
      Mod+Left hotkey-overlay-title="Focus: Left" { focus-column-left; }
      Mod+Right hotkey-overlay-title="Focus: Right" { focus-column-right; }
      Mod+Up hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+Down hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }
      Mod+H hotkey-overlay-title="Focus: Left" { focus-column-left; }
      Mod+L hotkey-overlay-title="Focus: Right" { focus-column-right; }
      Mod+K hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+J hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }

      // Monitor Focus
      Mod+Alt+Up hotkey-overlay-title="Monitor: Focus Up" { focus-monitor-up; }
      Mod+Alt+Down hotkey-overlay-title="Monitor: Focus Down" { focus-monitor-down; }
      Mod+Alt+H hotkey-overlay-title="Monitor: Focus Left" { focus-monitor-left; }
      Mod+Alt+L hotkey-overlay-title="Monitor: Focus Right" { focus-monitor-right; }
      Mod+Alt+K hotkey-overlay-title="Monitor: Focus Up" { focus-monitor-up; }
      Mod+Alt+J hotkey-overlay-title="Monitor: Focus Down" { focus-monitor-down; }

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
      Mod+Page_Up hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+Page_Down hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }
      Mod+Shift+Page_Up hotkey-overlay-title="Move: To Workspace Up" { move-column-to-workspace-up; }
      Mod+Shift+Page_Down hotkey-overlay-title="Move: To Workspace Down" { move-column-to-workspace-down; }

      // Screenshots
      Print hotkey-overlay-title="Screenshot: Selection" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshot"; }
      Ctrl+Print hotkey-overlay-title="Screenshot: Screen" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotScreen"; }
      Alt+Print hotkey-overlay-title="Screenshot: Window" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotWindow"; }

      // Reload config (fast iteration)
      // Not all niri versions expose `load-config-file` as a direct config action,
      // but it is always available via the IPC CLI.
      Mod+Ctrl+Alt+R hotkey-overlay-title="Reload Niri Config" { spawn "niri" "msg" "action" "load-config-file"; }

      // Mouse Wheel
      Mod+WheelScrollDown cooldown-ms=150 hotkey-overlay-title="Workspace: Down" { focus-workspace-down; }
      Mod+WheelScrollUp   cooldown-ms=150 hotkey-overlay-title="Workspace: Up" { focus-workspace-up; }
      Mod+WheelScrollRight hotkey-overlay-title="Focus: Right" { focus-column-right; }
      Mod+WheelScrollLeft  hotkey-overlay-title="Focus: Left" { focus-column-left; }

      // ========================================================================
      // nirius Integration (optional)
      //
      // WARNING:
      // - Niri rejects duplicate keys inside the same `binds {}` block.
      // - Multiple `binds {}` blocks across includes are merged; conflicting keys
      //   are replaced (last definition wins).
      // - Your previous validate error was caused by binding the same key twice
      //   in the same file, AND by calling scratchpad via niriusd.
      // - Enable these binds only after picking keys that do not conflict with
      //   existing ones (avoid overlaps with the core binds above).
      //
      // Recommended "safe" defaults (unlikely to collide):
      // - Mod+Alt+BackSpace / Mod+Alt+Shift+BackSpace
      // ========================================================================
      ${lib.optionalString enableNiriusBinds ''
      Mod+Alt+Shift+Return hotkey-overlay-title="Nirius: Kitty Focus/Spawn" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^kitty$" "${bins.kitty}"; }
      Mod+Alt+S hotkey-overlay-title="Nirius: Spotify To Current WS" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "--focus"; }
      Mod+Alt+Shift+BackSpace hotkey-overlay-title="Nirius: Scratchpad Toggle" { spawn "${bins.nirius}" "scratchpad-toggle"; }
      Mod+Alt+BackSpace hotkey-overlay-title="Nirius: Scratchpad Show" { spawn "${bins.nirius}" "scratchpad-show"; }
      Mod+Alt+Shift+F10 hotkey-overlay-title="Nirius: Follow Mode" { spawn "${bins.nirius}" "toggle-follow-mode"; }
      ''}
  '';

  apps = ''
      // ========================================================================
      // Custom Applications
      // ========================================================================

      Mod+Alt+Return hotkey-overlay-title="SemsuMo: Daily" { spawn "semsumo" "launch" "--daily" "-all"; }
      Mod+Shift+A hotkey-overlay-title="Arrange Windows" { spawn "${bins.niriSet}" "arrange-windows"; }
      Mod+Alt+Left hotkey-overlay-title="Column Width: -100" { spawn "niri" "msg" "action" "set-column-width" "-100"; }
      Mod+Alt+Right hotkey-overlay-title="Column Width: +100" { spawn "niri" "msg" "action" "set-column-width" "+100"; }

      // Launchers
      Alt+Space hotkey-overlay-title="Rofi: Launcher" { spawn "rofi-launcher"; }
      Mod+Ctrl+Space hotkey-overlay-title="Walk" { spawn "walk"; }
      Mod+S hotkey-overlay-title="Sticky: Toggle" { spawn "${bins.nsticky}" "sticky" "toggle-active"; }
      Mod+Shift+S hotkey-overlay-title="Stage: Toggle" { spawn "${bins.nsticky}" "stage" "toggle-active"; }

      // File Managers
      Alt+F hotkey-overlay-title="Files: Yazi" { spawn "${bins.kitty}" "-e" "yazi"; }
      Alt+Ctrl+F hotkey-overlay-title="Files: Nemo" { spawn "nemo"; }

      // Special Apps
      Alt+T hotkey-overlay-title="Kkenp" { spawn "start-kkenp"; }
      Mod+M hotkey-overlay-title="Notes" { spawn "anotes"; }

      // Tools
      Mod+Shift+C hotkey-overlay-title="Color Picker" { spawn "hyprpicker" "-a"; }
      Mod+Ctrl+V hotkey-overlay-title="Clipboard: Clipse" { spawn "${bins.kitty}" "--class" "clipse" "-e" "${bins.clipse}"; }
      F10 hotkey-overlay-title="Bluetooth: Toggle" { spawn "bluetooth_toggle"; }
      Alt+F12 hotkey-overlay-title="VPN: Mullvad Toggle" { spawn "osc-mullvad" "toggle"; }

      // Audio Scripts
      Alt+A hotkey-overlay-title="Audio: Switch Output" { spawn "osc-soundctl" "switch"; }
      Alt+Ctrl+A hotkey-overlay-title="Audio: Switch Mic" { spawn "osc-soundctl" "switch-mic"; }

      // Media Scripts
      Alt+E hotkey-overlay-title="Spotify: Toggle" { spawn "osc-spotify"; }
      Alt+Ctrl+N hotkey-overlay-title="Spotify: Next" { spawn "osc-spotify" "next"; }
      Alt+Ctrl+B hotkey-overlay-title="Spotify: Previous" { spawn "osc-spotify" "prev"; }
      Alt+Ctrl+E hotkey-overlay-title="MPC: Toggle" { spawn "mpc-control" "toggle"; }
      Alt+I hotkey-overlay-title="VLC: Toggle" { spawn "vlc-toggle"; }
  '';

  mpv = ''
      // ========================================================================
      // MPV Manager
      // ========================================================================
      Mod+Shift+1 hotkey-overlay-title="MPV: Playback" { spawn "mpv-manager" "playback"; }
      Mod+Shift+2 hotkey-overlay-title="MPV: Play YouTube" { spawn "mpv-manager" "play-yt"; }
      Mod+Shift+3 hotkey-overlay-title="MPV: Stick" { spawn "mpv-manager" "stick"; }
      Mod+Shift+4 hotkey-overlay-title="MPV: Move" { spawn "mpv-manager" "move"; }
      Mod+Shift+5 hotkey-overlay-title="MPV: Save YouTube" { spawn "mpv-manager" "save-yt"; }
      Mod+Shift+6 hotkey-overlay-title="MPV: Wallpaper" { spawn "mpv-manager" "wallpaper"; }
  '';

  workspaces = ''
      // ========================================================================
      // Workspace Management
      // ========================================================================

      // Focus Workspace
      Mod+1 hotkey-overlay-title="Workspace: 1" { focus-workspace "1"; }
      Mod+2 hotkey-overlay-title="Workspace: 2" { focus-workspace "2"; }
      Mod+3 hotkey-overlay-title="Workspace: 3" { focus-workspace "3"; }
      Mod+4 hotkey-overlay-title="Workspace: 4" { focus-workspace "4"; }
      Mod+5 hotkey-overlay-title="Workspace: 5" { focus-workspace "5"; }
      Mod+6 hotkey-overlay-title="Workspace: 6" { focus-workspace "6"; }
      Mod+7 hotkey-overlay-title="Workspace: 7" { focus-workspace "7"; }
      Mod+8 hotkey-overlay-title="Workspace: 8" { focus-workspace "8"; }
      Mod+9 hotkey-overlay-title="Workspace: 9" { focus-workspace "9"; }

      // Move to Workspace
      Alt+1 hotkey-overlay-title="Move: To Workspace 1" { move-column-to-workspace "1"; }
      Alt+2 hotkey-overlay-title="Move: To Workspace 2" { move-column-to-workspace "2"; }
      Alt+3 hotkey-overlay-title="Move: To Workspace 3" { move-column-to-workspace "3"; }
      Alt+4 hotkey-overlay-title="Move: To Workspace 4" { move-column-to-workspace "4"; }
      Alt+5 hotkey-overlay-title="Move: To Workspace 5" { move-column-to-workspace "5"; }
      Alt+6 hotkey-overlay-title="Move: To Workspace 6" { move-column-to-workspace "6"; }
      Alt+7 hotkey-overlay-title="Move: To Workspace 7" { move-column-to-workspace "7"; }
      Alt+8 hotkey-overlay-title="Move: To Workspace 8" { move-column-to-workspace "8"; }
      Alt+9 hotkey-overlay-title="Move: To Workspace 9" { move-column-to-workspace "9"; }
  '';

  monitors = ''
      // ========================================================================
      // Monitor Management
      // ========================================================================
      Mod+A hotkey-overlay-title="Monitor: Focus Next" { spawn "niri" "msg" "action" "focus-monitor-next"; }
      Mod+E hotkey-overlay-title="Monitor: Move WS Next" { spawn "niri" "msg" "action" "move-workspace-to-monitor-next"; }
      Mod+Escape hotkey-overlay-title="Monitor: Focus Next" { spawn "${bins.niriSet}" "workspace-monitor" "-mn"; }
  '';
}
