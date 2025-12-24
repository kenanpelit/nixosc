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
      Mod+Space { spawn "${bins.dms}" "ipc" "call" "spotlight" "toggle"; }
      Mod+D { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" ""; }
      Mod+N { spawn "${bins.dms}" "ipc" "call" "notifications" "toggle"; }
      Mod+C { spawn "${bins.dms}" "ipc" "call" "control-center" "toggle"; }
      Mod+V { spawn "${bins.dms}" "ipc" "call" "clipboard" "toggle"; }
      Mod+Shift+D { spawn "${bins.dms}" "ipc" "call" "dash" "toggle" "overview"; }
      Mod+Shift+P { spawn "${bins.dms}" "ipc" "call" "processlist" "focusOrToggle"; }
      Mod+Ctrl+N { spawn "${bins.dms}" "ipc" "call" "notepad" "open"; }
      Mod+Comma { spawn "${bins.dms}" "ipc" "call" "settings" "focusOrToggle"; }
      Mod+Delete { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }
      Ctrl+Alt+Delete { spawn "${bins.dms}" "ipc" "call" "powermenu" "toggle"; }

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
      Alt+L { spawn "${bins.niriSet}" "lock"; }
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
      Mod+Alt+Slash { spawn "${bins.dms}" "ipc" "call" "settings" "openWith" "keybinds"; }
      Mod+F1 { spawn "${bins.dms}" "ipc" "call" "keybinds" "toggle" "niri"; }
      Mod+Shift+F1 { show-hotkey-overlay; }

      Alt+Tab hotkey-overlay-title="Switch Windows" { spawn "${bins.dms}" "ipc" "call" "spotlight" "openQuery" "!"; }
  '';

  core = ''
      // ========================================================================
      // Core Window Management
      // ========================================================================

      // Applications
      Mod+Return { spawn "${bins.kitty}"; }
      Mod+T { spawn "${bins.kitty}"; }

      // Window Controls
      Mod+Q { close-window; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
      Mod+O { toggle-window-rule-opacity; }
      Mod+R { switch-preset-column-width; }
      Mod+Shift+Space hotkey-overlay-title="Float (preset)" { spawn "${pkgs.bash}/bin/bash" "-lc" "niri msg action move-window-to-floating; niri msg action set-window-width 900; niri msg action set-window-height 650"; }
      Mod+Alt+Shift+Space hotkey-overlay-title="Tile (from float)" { move-window-to-tiling; }
      Mod+BackSpace hotkey-overlay-title="Focus: Float ↔ Tile" { switch-focus-between-floating-and-tiling; }

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

      // Reload config (fast iteration)
      // Not all niri versions expose `load-config-file` as a direct config action,
      // but it is always available via the IPC CLI.
      Mod+Ctrl+R hotkey-overlay-title="Reload Niri Config" { spawn "niri" "msg" "action" "load-config-file"; }

      // Mouse Wheel
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
      Mod+WheelScrollRight { focus-column-right; }
      Mod+WheelScrollLeft  { focus-column-left; }

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
      Mod+Alt+Shift+Return { spawn "${bins.nirius}" "focus-or-spawn" "--app-id" "^kitty$" "${bins.kitty}"; }
      Mod+Alt+S { spawn "${bins.nirius}" "move-to-current-workspace" "--app-id" "^(spotify|Spotify|com\\.spotify\\.Client)$" "--focus"; }
      Mod+Alt+Shift+BackSpace { spawn "${bins.nirius}" "scratchpad-toggle"; }
      Mod+Alt+BackSpace { spawn "${bins.nirius}" "scratchpad-show"; }
      Mod+Alt+Shift+F10 { spawn "${bins.nirius}" "toggle-follow-mode"; }
      ''}
  '';

  apps = ''
      // ========================================================================
      // Custom Applications
      // ========================================================================

      Mod+Alt+Return { spawn "semsumo" "launch" "--daily"; }
      Mod+Shift+A hotkey-overlay-title="Arrange Windows" { spawn "${bins.niriSet}" "arrange-windows"; }
      Mod+Alt+Left { spawn "niri" "msg" "action" "set-column-width" "-100"; }
      Mod+Alt+Right { spawn "niri" "msg" "action" "set-column-width" "+100"; }

      // Launchers
      Alt+Space { spawn "rofi-launcher"; }
      // Mod+Ctrl+Space { spawn "walk"; }
      Mod+Ctrl+Space { spawn "${bins.nsticky}" "sticky" "toggle-active"; }
      Mod+Shift+S { spawn "${bins.nsticky}" "stage" "toggle-active"; }

      // File Managers
      Alt+F { spawn "${bins.kitty}" "-e" "yazi"; }
      Alt+Ctrl+F { spawn "nemo"; }

      // Special Apps
      Alt+T { spawn "start-kkenp"; }
      Mod+M { spawn "anotes"; }

      // Tools
      Mod+Shift+C { spawn "hyprpicker" "-a"; }
      Mod+Ctrl+V { spawn "${bins.kitty}" "--class" "clipse" "-e" "${bins.clipse}"; }
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
  '';

  mpv = ''
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
  '';

  workspaces = ''
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
  '';

  monitors = ''
      // ========================================================================
      // Monitor Management
      // ========================================================================
      Mod+A { spawn "niri" "msg" "action" "focus-monitor-next"; }
      Mod+E { spawn "niri" "msg" "action" "move-workspace-to-monitor-next"; }
      Mod+Escape { spawn "sh" "-lc" "niri msg action move-workspace-to-monitor-next || niri msg action focus-monitor-next"; }
  '';
}
