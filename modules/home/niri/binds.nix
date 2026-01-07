# modules/home/niri/binds.nix
# ==============================================================================
# Niri Keybindings - The Ultimate Configuration
#
# Optimized for Kenan's workflow with semantic grouping and complete coverage.
#
# Categories:
# 1. Core Window Management (Focus, Move, Actions)
# 2. Layout & View (Sizing, Modes, Column Ops)
# 3. DMS Integration (Launchers, UI, Power)
# 4. System & Scripts (Audio, Media, VPN, Tools)
# 5. Nirius Workflow (Smart Apps, Scratchpad)
# 6. MPV Manager (Multimedia)
# 7. Workspaces & Monitors
# ==============================================================================
{ lib, pkgs, bins, enableNiriusBinds, ... }:
{
  # ---------------------------------------------------------------------------
  # 1. CORE WINDOW MANAGEMENT
  # ---------------------------------------------------------------------------
  core = ''
      // --- Window Focus (Vim & Arrows) ---
      Mod+Left   hotkey-overlay-title="Focus Left"  { focus-column-left; }
      Mod+Right  hotkey-overlay-title="Focus Right" { focus-column-right; }
      Mod+Up     hotkey-overlay-title="Focus Up"    { focus-workspace-up; }
      Mod+Down   hotkey-overlay-title="Focus Down"  { focus-workspace-down; }
      
      Mod+H      hotkey-overlay-title="Focus Left"  { focus-column-left; }
      Mod+L      hotkey-overlay-title="Focus Right" { focus-column-right; }
      Mod+K      hotkey-overlay-title="Focus Up"    { focus-workspace-up; }
      Mod+J      hotkey-overlay-title="Focus Down"  { focus-workspace-down; }

      // --- Window Movement (Shift + Vim/Arrows) ---
      Mod+Shift+Left   hotkey-overlay-title="Move Left"  { move-column-left; }
      Mod+Shift+Right  hotkey-overlay-title="Move Right" { move-column-right; }
      Mod+Shift+Up     hotkey-overlay-title="Move Up"    { move-window-up; }
      Mod+Shift+Down   hotkey-overlay-title="Move Down"  { move-window-down; }
      
      Mod+Shift+H      hotkey-overlay-title="Move Left"  { move-column-left; }
      Mod+Shift+L      hotkey-overlay-title="Move Right" { move-column-right; }
      Mod+Shift+K      hotkey-overlay-title="Move Up"    { move-window-up; }
      Mod+Shift+J      hotkey-overlay-title="Move Down"  { move-window-down; }

      // --- Core Actions ---
      Mod+Q      hotkey-overlay-title="Close Window" { close-window; }
      Mod+F      hotkey-overlay-title="Fullscreen"   { fullscreen-window; }
      Mod+Space  hotkey-overlay-title="Maximize Column" { maximize-column; }
      Mod+C      hotkey-overlay-title="Center Column" { center-column; }
  '';

  # ---------------------------------------------------------------------------
  # 2. LAYOUT & VIEW
  # ---------------------------------------------------------------------------
  layout = ''
      // --- Sizing & Presets ---
      Mod+R        hotkey-overlay-title="Next Preset Width" { switch-preset-column-width; }
      Mod+Shift+R  hotkey-overlay-title="Width 75%" { set-column-width "75%"; }
      
      Mod+0        hotkey-overlay-title="Size: 960x540 (Half)"   { spawn "sh" "-c" "niri msg action set-column-width 960 && niri msg action set-window-height 540"; }
      Mod+Shift+0  hotkey-overlay-title="Size: 1280x720 (HD)"    { spawn "sh" "-c" "niri msg action set-column-width 1280 && niri msg action set-window-height 720"; }
      Mod+Ctrl+0   hotkey-overlay-title="Size: 1920x1080 (FHD)"  { spawn "sh" "-c" "niri msg action set-column-width 1920 && niri msg action set-window-height 1080"; }

      // --- Fine-grained Sizing ---
      Mod+Minus       hotkey-overlay-title="Width -5%" { set-column-width "-5%"; }
      Mod+Equal       hotkey-overlay-title="Width +5%" { set-column-width "+5%"; }
      Mod+Shift+Minus hotkey-overlay-title="Height -5%" { set-window-height "-5%"; }
      Mod+Shift+Equal hotkey-overlay-title="Height +5%" { set-window-height "+5%"; }

      // --- Advanced Modes ---
      Alt+G        repeat=false hotkey-overlay-title="Max to Edges" { maximize-window-to-edges; }
      Mod+Tab      hotkey-overlay-title="Toggle Tabbed Mode" { toggle-column-tabbed-display; }
      Mod+V        hotkey-overlay-title="Toggle Float/Tile" { spawn "${bins.niriSet}" "toggle-window-mode"; }
      Mod+Ctrl+BackSpace hotkey-overlay-title="Focus Float/Tile" { switch-focus-between-floating-and-tiling; }
      
      Mod+Z        repeat=false hotkey-overlay-title="Zen Mode" { spawn "${bins.niriSet}" "zen"; }
      Mod+P        repeat=false hotkey-overlay-title="Pin Window (PiP)" { spawn "${bins.niriSet}" "pin"; }

      // --- Consume / Expel (Window Grouping) ---
      Mod+BracketLeft  hotkey-overlay-title="Consume/Expel Left" { consume-or-expel-window-left; }
      Mod+BracketRight hotkey-overlay-title="Consume/Expel Right" { consume-or-expel-window-right; }
      Mod+Comma        hotkey-overlay-title="Consume/Expel Left" { consume-or-expel-window-left; }
      Mod+Period       hotkey-overlay-title="Consume/Expel Right" { consume-or-expel-window-right; }
      
      // --- Mouse Wheel Interaction ---
      Mod+WheelScrollDown  cooldown-ms=150 hotkey-overlay-title="WS Down" { focus-workspace-down; }
      Mod+WheelScrollUp    cooldown-ms=150 hotkey-overlay-title="WS Up" { focus-workspace-up; }
      Mod+WheelScrollRight hotkey-overlay-title="Focus Right" { focus-column-right; }
      Mod+WheelScrollLeft  hotkey-overlay-title="Focus Left" { focus-column-left; }
      
      // --- Opacity Control ---
      Mod+O                     hotkey-overlay-title="Toggle Opacity Rule" { toggle-window-rule-opacity; }
      Mod+Shift+WheelScrollDown hotkey-overlay-title="Opacity -10%" { spawn "niri" "msg" "action" "set-window-opacity" "-0.1"; }
      Mod+Shift+WheelScrollUp   hotkey-overlay-title="Opacity +10%" { spawn "niri" "msg" "action" "set-window-opacity" "+0.1"; }
  '';

  # ---------------------------------------------------------------------------
  # 3. DMS INTEGRATION (System Interface)
  # ---------------------------------------------------------------------------
  dms = ''
      // --- Launchers ---
      Alt+Space    repeat=false hotkey-overlay-title="Spotlight" { spawn "${bins.dms}" "ipc" "call" "spotlight" "toggle"; }
      Mod+D        repeat=false hotkey-overlay-title="Dash / Apps" { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" ""; }
      Mod+A        repeat=false hotkey-overlay-title="Control Center" { spawn "${bins.dms}" "ipc" "call" "control-center" "toggle"; }
      Mod+N        repeat=false hotkey-overlay-title="Notifications" { spawn "${bins.dms}" "ipc" "call" "notifications" "toggle"; }
      
      // --- DMS Tools ---
      Mod+V        repeat=false hotkey-overlay-title="Clipboard History" { spawn "${bins.dms}" "ipc" "call" "clipboard" "toggle"; }
      Mod+Shift+V  repeat=false hotkey-overlay-title="Clipboard Preview" { spawn "osc-clipview"; }
      Mod+Shift+D  repeat=false hotkey-overlay-title="Dash Overview" { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" "overview"; }
      Mod+Shift+P  repeat=false hotkey-overlay-title="Process List" { spawn "${bins.dms}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Ctrl+N   repeat=false hotkey-overlay-title="Notepad" { spawn "${bins.dms}" "ipc" "call" "notepad" "open"; }
      Mod+Comma    repeat=false hotkey-overlay-title="Settings" { spawn "${bins.dms}" "ipc" "call" "settings" "focusOrToggle"; }
      
      // --- Window Switching ---
      Alt+Tab      hotkey-overlay-title="Switch Windows" { spawn "${bins.dms}" "ipc" "call" "spotlight" "openQuery" "!"; }

      // --- UI Toggles ---
      Mod+B        repeat=false hotkey-overlay-title="Toggle Bar" { spawn "${bins.dms}" "ipc" "call" "bar" "toggle" "index" "0"; }
      Mod+Shift+B  repeat=false hotkey-overlay-title="Toggle Dock" { spawn "${bins.dms}" "ipc" "call" "dock" "toggle"; }
      Mod+Ctrl+B   repeat=false hotkey-overlay-title="Auto-Hide Bar" { spawn "${bins.dms}" "ipc" "call" "bar" "toggleAutoHide" "index" "0"; }

      // --- Power & Session ---
      Mod+Delete       repeat=false hotkey-overlay-title="Power Menu" { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }
      Ctrl+Alt+Delete  repeat=false hotkey-overlay-title="Power Menu" { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }
      Alt+L            repeat=false hotkey-overlay-title="Lock Screen" { spawn "${bins.niriSet}" "lock"; }
      Mod+Shift+Delete repeat=false hotkey-overlay-title="Inhibit Idle" { spawn "${bins.dms}" "ipc" "call" "inhibit" "toggle"; }
      
      // --- Appearance ---
      Mod+Y        repeat=false hotkey-overlay-title="Wallpaper Menu" { spawn "${bins.dms}" "ipc" "call" "dankdash" "wallpaper"; }
      Mod+W        hotkey-overlay-title="Next Wallpaper" { spawn "${bins.dms}" "ipc" "call" "wallpaper" "next"; }
      Mod+Shift+W  hotkey-overlay-title="Prev Wallpaper" { spawn "${bins.dms}" "ipc" "call" "wallpaper" "prev"; }
      Mod+Shift+T  repeat=false hotkey-overlay-title="Toggle Theme" { spawn "${bins.dms}" "ipc" "call" "theme" "toggle"; }
      Mod+Shift+N  repeat=false hotkey-overlay-title="Toggle Night Mode" { spawn "${bins.dms}" "ipc" "call" "night" "toggle"; }
      
      // --- Help ---
      Mod+Alt+Slash repeat=false hotkey-overlay-title="Keybind Settings" { spawn "${bins.dms}" "ipc" "call" "settings" "openWith" "keybinds"; }
      Mod+F1        repeat=false hotkey-overlay-title="Keybinds (DMS)" { spawn "${bins.dms}" "ipc" "call" "keybinds" "toggle" "niri"; }
      Alt+F1        repeat=false hotkey-overlay-title="Keybinds (Niri)" { show-hotkey-overlay; }
  '';

  # ---------------------------------------------------------------------------
  # 4. SYSTEM & SCRIPTS
  # ---------------------------------------------------------------------------
  apps = ''
      // --- System Hardware (Audio/Bright) ---
      XF86AudioRaiseVolume allow-when-locked=true hotkey-overlay-title="Vol +" { spawn "${bins.dms}" "ipc" "call" "audio" "increment" "5"; }
      XF86AudioLowerVolume allow-when-locked=true hotkey-overlay-title="Vol -" { spawn "${bins.dms}" "ipc" "call" "audio" "decrement" "5"; }
      XF86AudioMute        allow-when-locked=true hotkey-overlay-title="Mute" { spawn "${bins.dms}" "ipc" "call" "audio" "mute"; }
      XF86AudioMicMute     allow-when-locked=true hotkey-overlay-title="Mic Mute" { spawn "${bins.dms}" "ipc" "call" "audio" "micmute"; }
      XF86MonBrightnessUp   allow-when-locked=true hotkey-overlay-title="Bright +" { spawn "${bins.dms}" "ipc" "call" "brightness" "increment" "5" ""; }
      XF86MonBrightnessDown allow-when-locked=true hotkey-overlay-title="Bright -" { spawn "${bins.dms}" "ipc" "call" "brightness" "decrement" "5" ""; }

      // --- Media Control (MPRIS) ---
      XF86AudioPlay allow-when-locked=true hotkey-overlay-title="Play/Pause" { spawn "${bins.dms}" "ipc" "call" "mpris" "playPause"; }
      XF86AudioNext allow-when-locked=true hotkey-overlay-title="Next" { spawn "${bins.dms}" "ipc" "call" "mpris" "next"; }
      XF86AudioPrev allow-when-locked=true hotkey-overlay-title="Prev" { spawn "${bins.dms}" "ipc" "call" "mpris" "previous"; }
      XF86AudioStop allow-when-locked=true hotkey-overlay-title="Stop" { spawn "${bins.dms}" "ipc" "call" "mpris" "stop"; }

      // --- Custom Scripts (Audio/Media) ---
      Alt+A          repeat=false hotkey-overlay-title="Switch Audio Output" { spawn "osc-soundctl" "switch"; }
      Alt+Ctrl+A     repeat=false hotkey-overlay-title="Switch Mic Input" { spawn "osc-soundctl" "switch-mic"; }
      Alt+E          repeat=false hotkey-overlay-title="Spotify Toggle" { spawn "osc-spotify"; }
      Alt+Ctrl+N     repeat=false hotkey-overlay-title="Spotify Next" { spawn "osc-spotify" "next"; }
      Alt+Ctrl+B     repeat=false hotkey-overlay-title="Spotify Prev" { spawn "osc-spotify" "prev"; }
      Alt+Ctrl+E     repeat=false hotkey-overlay-title="MPC Toggle" { spawn "mpc-control" "toggle"; }
      Alt+I          repeat=false hotkey-overlay-title="VLC Toggle" { spawn "vlc-toggle"; }

      // --- System Tools ---
      Mod+Shift+C    repeat=false hotkey-overlay-title="Color Picker" { spawn "hyprpicker" "-a"; }
      Mod+Ctrl+V     repeat=false hotkey-overlay-title="Clipse (Floating)" { spawn "${bins.kitty}" "--class" "clipse" "-e" "${bins.clipse}"; }
      F10            repeat=false hotkey-overlay-title="Bluetooth Toggle" { spawn "bluetooth_toggle"; }
      Alt+F12        repeat=false hotkey-overlay-title="VPN Toggle" { spawn "osc-mullvad" "toggle"; }
      
      // --- Screenshots ---
      Print       repeat=false hotkey-overlay-title="Screenshot Area" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshot"; }
      Ctrl+Print  repeat=false hotkey-overlay-title="Screenshot Screen" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotScreen"; }
      Alt+Print   repeat=false hotkey-overlay-title="Screenshot Window" { spawn "${bins.dms}" "ipc" "call" "niri" "screenshotWindow"; }
      
      // --- System Config ---
      Mod+Ctrl+Alt+R repeat=false hotkey-overlay-title="Reload Config" { spawn "niri" "msg" "action" "load-config-file"; }
      
      // --- Custom Apps ---
      Alt+T          repeat=false hotkey-overlay-title="KKENP Start" { spawn "start-kkenp"; }
      Alt+N          repeat=false hotkey-overlay-title="Notes (Anotes)" { spawn "anotes"; }
      Mod+Alt+Return      repeat=false hotkey-overlay-title="SemsuMo Daily" { spawn "semsumo" "launch" "--daily" "-all"; }
      Mod+Shift+A         repeat=false hotkey-overlay-title="Arrange Windows" { spawn "${bins.niriSet}" "arrange-windows"; }
      
      // --- Direct App Launchers ---
      Alt+Space      repeat=false hotkey-overlay-title="Rofi Launcher" { spawn "rofi-launcher"; }
      Mod+Ctrl+Space repeat=false hotkey-overlay-title="Walk Launcher" { spawn "walk"; }
      Mod+Ctrl+S     repeat=false hotkey-overlay-title="Sticky Toggle" { spawn "nsticky-toggle"; }
      Mod+Ctrl+F     repeat=false hotkey-overlay-title="File Manager (Nemo)" { spawn "nemo"; }
      Alt+Ctrl+F     repeat=false hotkey-overlay-title="File Manager (Yazi)" { spawn "${bins.kitty}" "-e" "yazi"; }
      Mod+T          repeat=false hotkey-overlay-title="Terminal" { spawn "${bins.kitty}"; }
  '';

  # ---------------------------------------------------------------------------
  # 5. NIRIUS WORKFLOW (Smart Focus & Routing)
  # ---------------------------------------------------------------------------
  nirius = ''
      ${lib.optionalString enableNiriusBinds ''
        // --- Smart Focus-or-Spawn (Mod+Alt) ---
        Mod+Alt+T    repeat=false hotkey-overlay-title="Smart: Terminal" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^kitty$" "${bins.kitty}"; }
        Mod+Alt+B    repeat=false hotkey-overlay-title="Smart: Browser" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "(brave|brave-browser|firefox|zen|chromium)" "brave"; }
        Mod+Alt+M    repeat=false hotkey-overlay-title="Smart: Music" { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "spotify"; }
        Mod+Alt+N    repeat=false hotkey-overlay-title="Smart: Notes" { spawn "${bins.nirius}" "focus-or-spawn" "--title" "(Anotes|Notes)" "anotes"; }

        // --- Pull-to-Me (Move here & Focus) (Mod+Alt+Shift) ---
        Mod+Alt+Shift+T repeat=false hotkey-overlay-title="Pull Terminal" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^kitty$" "--focus"; }
        Mod+Alt+Shift+B repeat=false hotkey-overlay-title="Pull Browser" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "(brave|brave-browser|firefox|zen|chromium)" "--focus"; }
        Mod+Alt+Shift+M repeat=false hotkey-overlay-title="Pull Music" { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "--focus"; }
        Mod+Alt+Shift+N repeat=false hotkey-overlay-title="Pull Notes" { spawn "${bins.nirius}" "move-to-current-workspace" "--title" "(Anotes|Notes)" "--focus"; }

        // --- Scratchpad (BackSpace) ---
        Mod+BackSpace     repeat=false hotkey-overlay-title="Scratch: Toggle" { spawn "${bins.nirius}" "scratchpad-toggle"; }
        Alt+BackSpace     repeat=false hotkey-overlay-title="Scratch: Cycle" { spawn "${bins.nirius}" "scratchpad-show"; }
        Mod+Alt+BackSpace repeat=false hotkey-overlay-title="Scratch: Show All" { spawn "${bins.nirius}" "scratchpad-show-all"; }

        // --- Marks (Role-Based) ---
        Mod+Alt+G    repeat=false hotkey-overlay-title="Mark: Toggle Default" { spawn "${bins.nirius}" "toggle-mark"; }

        Mod+Alt+Shift+1 repeat=false hotkey-overlay-title="Mark: Set Term" { spawn "${bins.nirius}" "toggle-mark" "term"; }
        Mod+Alt+Shift+2 repeat=false hotkey-overlay-title="Mark: Set Web" { spawn "${bins.nirius}" "toggle-mark" "web"; }
        Mod+Alt+Shift+3 repeat=false hotkey-overlay-title="Mark: Set Media" { spawn "${bins.nirius}" "toggle-mark" "media"; }
        Mod+Alt+Shift+4 repeat=false hotkey-overlay-title="Mark: Set Notes" { spawn "${bins.nirius}" "toggle-mark" "notes"; }

        Mod+Alt+1    repeat=false hotkey-overlay-title="Mark: Go Term" { spawn "${bins.nirius}" "focus-marked" "term"; }
        Mod+Alt+2    repeat=false hotkey-overlay-title="Mark: Go Web" { spawn "${bins.nirius}" "focus-marked" "web"; }
        Mod+Alt+3    repeat=false hotkey-overlay-title="Mark: Go Media" { spawn "${bins.nirius}" "focus-marked" "media"; }
        Mod+Alt+4    repeat=false hotkey-overlay-title="Mark: Go Notes" { spawn "${bins.nirius}" "focus-marked" "notes"; }

        Mod+Alt+Shift+I repeat=false hotkey-overlay-title="Debug: List Marks" { spawn "${bins.nirius}" "list-marked" "--all"; }

        // --- Follow Mode ---
        Mod+Alt+F    repeat=false hotkey-overlay-title="Toggle Follow Mode" { spawn "${bins.nirius}" "toggle-follow-mode"; }
      ''}
  '';

  # ---------------------------------------------------------------------------
  # 6. MPV MANAGER
  # ---------------------------------------------------------------------------
  mpv = ''
      Alt+U       repeat=false hotkey-overlay-title="MPV Playback" { spawn "${bins.mpvManager}" "playback"; }
      Mod+Ctrl+Y  repeat=false hotkey-overlay-title="MPV Play YouTube" { spawn "${bins.mpvManager}" "play-yt"; }
      Mod+Ctrl+3  repeat=false hotkey-overlay-title="MPV Stick" { spawn "${bins.mpvManager}" "stick"; }
      Mod+Ctrl+4  repeat=false hotkey-overlay-title="MPV Move" { spawn "${bins.mpvManager}" "move"; }
      Mod+Ctrl+5  repeat=false hotkey-overlay-title="MPV Save YT" { spawn "${bins.mpvManager}" "save-yt"; }
      Mod+Ctrl+6  repeat=false hotkey-overlay-title="MPV Wallpaper" { spawn "${bins.mpvManager}" "wallpaper"; }
  '';

  # ---------------------------------------------------------------------------
  # 7. WORKSPACES & MONITORS
  # ---------------------------------------------------------------------------
  workspaces = ''
      // --- Focus Workspace ---
      Mod+1 hotkey-overlay-title="Workspace 1" { focus-workspace "1"; }
      Mod+2 hotkey-overlay-title="Workspace 2" { focus-workspace "2"; }
      Mod+3 hotkey-overlay-title="Workspace 3" { focus-workspace "3"; }
      Mod+4 hotkey-overlay-title="Workspace 4" { focus-workspace "4"; }
      Mod+5 hotkey-overlay-title="Workspace 5" { focus-workspace "5"; }
      Mod+6 hotkey-overlay-title="Workspace 6" { focus-workspace "6"; }
      Mod+7 hotkey-overlay-title="Workspace 7" { focus-workspace "7"; }
      Mod+8 hotkey-overlay-title="Workspace 8" { focus-workspace "8"; }
      Mod+9 hotkey-overlay-title="Workspace 9" { focus-workspace "9"; }

      // --- Move to Workspace ---
      Mod+Shift+1 hotkey-overlay-title="Move To WS 1" { move-column-to-workspace "1"; }
      Mod+Shift+2 hotkey-overlay-title="Move To WS 2" { move-column-to-workspace "2"; }
      Mod+Shift+3 hotkey-overlay-title="Move To WS 3" { move-column-to-workspace "3"; }
      Mod+Shift+4 hotkey-overlay-title="Move To WS 4" { move-column-to-workspace "4"; }
      Mod+Shift+5 hotkey-overlay-title="Move To WS 5" { move-column-to-workspace "5"; }
      Mod+Shift+6 hotkey-overlay-title="Move To WS 6" { move-column-to-workspace "6"; }
      Mod+Shift+7 hotkey-overlay-title="Move To WS 7" { move-column-to-workspace "7"; }
      Mod+Shift+8 hotkey-overlay-title="Move To WS 8" { move-column-to-workspace "8"; }
      Mod+Shift+9 hotkey-overlay-title="Move To WS 9" { move-column-to-workspace "9"; }

      // --- Workspace Navigation ---
      Mod+Ctrl+C    repeat=false hotkey-overlay-title="Move to Empty WS" { move-window-to-workspace 255; }
      Mod+Page_Up   hotkey-overlay-title="Move Win WS Up" { move-window-to-workspace-up; }
      Mod+Page_Down hotkey-overlay-title="Move Win WS Down" { move-window-to-workspace-down; }
  '';

  monitors = ''
      // --- Monitor Focus ---
      Mod+A        repeat=false hotkey-overlay-title="Focus Next Monitor" { spawn "niri" "msg" "action" "focus-monitor-next"; }
      Mod+Alt+H    hotkey-overlay-title="Monitor Left" { focus-monitor-left; }
      Mod+Alt+L    hotkey-overlay-title="Monitor Right" { focus-monitor-right; }
      Mod+Alt+K    hotkey-overlay-title="Monitor Up" { focus-monitor-up; }
      Mod+Alt+J    hotkey-overlay-title="Monitor Down" { focus-monitor-down; }
      Mod+Alt+Left hotkey-overlay-title="Monitor Left" { focus-monitor-left; }
      Mod+Alt+Right hotkey-overlay-title="Monitor Right" { focus-monitor-right; }
      Mod+Alt+Up   hotkey-overlay-title="Monitor Up" { focus-monitor-up; }
      Mod+Alt+Down hotkey-overlay-title="Monitor Down" { focus-monitor-down; }

      // --- Move to Monitor ---
      Mod+E               repeat=false hotkey-overlay-title="Move WS Next Monitor" { spawn "niri" "msg" "action" "move-workspace-to-monitor-next"; }
      Mod+Escape          repeat=false hotkey-overlay-title="Smart Move/Focus" { spawn "sh" "-lc" "niri msg action move-workspace-to-monitor-next || niri msg action focus-monitor-next"; }
      Mod+Alt+Shift+Left  hotkey-overlay-title="Move to Monitor Left" { move-column-to-monitor-left; }
      Mod+Alt+Shift+Right hotkey-overlay-title="Move to Monitor Right" { move-column-to-monitor-right; }
      Mod+Ctrl+Up         hotkey-overlay-title="Move to Monitor Up" { move-column-to-monitor-up; }
      Mod+Ctrl+Down       hotkey-overlay-title="Move to Monitor Down" { move-column-to-monitor-down; }
  '';
}