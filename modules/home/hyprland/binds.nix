# modules/home/hyprland/binds.nix
# ==============================================================================
# Hyprland Key Bindings - ULTIMATE Sync with Niri (Modular)
#
# Mirrored from modules/home/niri/binds.nix to ensure seamless transitions.
# Organized into separate lists for better maintainability.
# ==============================================================================
{ lib, themeName, bins, ... }:

let
  # --- Binding Generators ---
  mkWorkspaces = nums: map (n: "$mainMod, ${toString n}, workspace, ${toString n}") nums;
  mkMoveWorkspaces = nums: map (n: "$mainMod SHIFT, ${toString n}, layoutmsg, movecoltoworkspace ${toString n}") nums;

  lockedBinds = [
    # Hardware (allow-when-locked parity with Niri)
    ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 5"
    ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 5"
    ", XF86AudioMute, exec, dms ipc call audio mute"
    ", XF86AudioMicMute, exec, dms ipc call audio micmute"
    ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 ''"
    ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 ''"
  ];

  # ---------------------------------------------------------------------------
  # 1. CORE WINDOW MANAGEMENT
  # ---------------------------------------------------------------------------
  coreBinds = [
    # Focus (Vim & Arrows) - Using hyprscrolling layoutmsg
    "$mainMod, left, layoutmsg, focus l"
    "$mainMod, right, layoutmsg, focus r"
    "$mainMod, up, workspace, e-1"
    "$mainMod, down, workspace, e+1"
    "$mainMod, h, layoutmsg, focus l"
    "$mainMod, l, layoutmsg, focus r"
    "$mainMod, k, workspace, e-1"
    "$mainMod, j, workspace, e+1"

    # Focus within Column (Niri Mod+Ctrl+K/J parity)
    "$mainMod CTRL, K, movefocus, u"
    "$mainMod CTRL, J, movefocus, d"

    # Move Column (Shift + Vim/Arrows)
    "$mainMod SHIFT, left, layoutmsg, swapcol l"
    "$mainMod SHIFT, right, layoutmsg, swapcol r"
    "$mainMod SHIFT, up, layoutmsg, movewindowto u"
    "$mainMod SHIFT, down, layoutmsg, movewindowto d"
    "$mainMod SHIFT, h, layoutmsg, swapcol l"
    "$mainMod SHIFT, l, layoutmsg, swapcol r"
    "$mainMod SHIFT, k, layoutmsg, movewindowto u"
    "$mainMod SHIFT, j, layoutmsg, movewindowto d"

    # Actions
    "$mainMod, Q, killactive"
    "$mainMod, F, fullscreen, 0"
    "$mainMod, M, exec, ${bins.hyprSet} maximize-column"
    "$mainMod, C, layoutmsg, togglefit" # Center/Fit Column (Niri Mod+C match)
  ];

  # ---------------------------------------------------------------------------
  # 2. LAYOUT & VIEW
  # ---------------------------------------------------------------------------
  layoutBinds = [
    # Sizing (Niri Mod+R match)
    "$mainMod, R, layoutmsg, colresize +conf"
    "$mainMod SHIFT, R, layoutmsg, colresize 0.8"
    
    # Size Presets (Niri Match) - Using relative resizes as hyprscrolling specific preset msg might vary
    # Assuming colresize all <width> works or fallback to relative.
    # Niri uses 960px etc. Here we use relative sizing.
    "$mainMod, 0, layoutmsg, colresize 0.5"
    "$mainMod SHIFT, 0, layoutmsg, colresize 0.7"
    "$mainMod CTRL, 0, layoutmsg, colresize 1.0"

    # Fine-grained Sizing (Niri Mod+Minus/Equal Match)
    "$mainMod, minus, layoutmsg, colresize -0.05"
    "$mainMod, equal, layoutmsg, colresize +0.05"
    "$mainMod SHIFT, minus, resizeactive, 0 -50" # Height still uses native resize
    "$mainMod SHIFT, equal, resizeactive, 0 50"

    # Advanced Modes
    "ALT, G, exec, ${bins.hyprSet} maximize-window-to-edges"
    "$mainMod CTRL, W, togglegroup"    # Toggle Tabbed Mode (Group)
    "$mainMod, G, exec, ${bins.hyprSet} toggle-float" # Toggle Float
    "$mainMod CTRL, BackSpace, exec, ${bins.hyprSet} focus-float-tile"
    
    "$mainMod, Z, exec, ${bins.hyprSet} zen"
    "$mainMod, P, exec, ${bins.hyprSet} pin"

    # Overview (Niri Mod+Alt+O parity)
    "$mainMod ALT, O, hyprexpo:expo, toggle"

    # Consume / Expel (Niri parity)
    "$mainMod CTRL, left, exec, ${bins.hyprSet} consume-or-expel left"
    "$mainMod CTRL, right, exec, ${bins.hyprSet} consume-or-expel right"
    "$mainMod CTRL, h, exec, ${bins.hyprSet} consume-or-expel left"
    "$mainMod CTRL, l, exec, ${bins.hyprSet} consume-or-expel right"
    
    # Opacity
    "$mainMod, O, exec, ${bins.hyprSet} opacity toggle"
    "$mainMod SHIFT, mouse_down, exec, ${bins.hyprSet} opacity -0.1"
    "$mainMod SHIFT, mouse_up, exec, ${bins.hyprSet} opacity +0.1"
  ];

  # ---------------------------------------------------------------------------
  # 3. DMS INTEGRATION
  # ---------------------------------------------------------------------------
  dmsBinds = [
    # Launchers
    "$mainMod, Space, exec, dms ipc call spotlight toggle"
    
    # DMS Tools
    "$mainMod, V, exec, dms ipc call clipboard toggle"
    "$mainMod SHIFT, V, exec, osc-clipview"
    "$mainMod, D, exec, dms ipc call dash toggle ''"
    "$mainMod CTRL, D, exec, dms ipc call control-center toggle"
    "$mainMod SHIFT, D, exec, dms ipc call dash toggle overview"
    "$mainMod CTRL SHIFT, D, exec, dms ipc call welcome doctor"
    "$mainMod SHIFT, P, exec, dms ipc call processlist focusOrToggle"
    "$mainMod, N, exec, dms ipc call notifications toggle"
    "$mainMod CTRL, N, exec, dms ipc call notepad open"
    "$mainMod, comma, exec, dms ipc call settings focusOrToggle"
    
    # Window Switching
    "$mainMod, Tab, focuscurrentorlast"
    "$mainMod SHIFT, Tab, focuscurrentorlast"
    "ALT, Tab, exec, dms ipc call spotlight openQuery '!'"

    # UI Toggles
    "$mainMod, B, exec, dms ipc call bar toggle index 0"
    "$mainMod SHIFT, B, exec, dms ipc call dock toggle"
    "$mainMod CTRL, B, exec, dms ipc call bar toggleAutoHide index 0"

    # Power & Session
    "$mainMod, Delete, exec, dms ipc call powermenu toggle"
    "ALT, L, exec, ${bins.hyprSet} lock"
    "$mainMod SHIFT, Delete, exec, dms ipc call inhibit toggle"

    # Appearance
    "$mainMod, Y, exec, dms ipc call dankdash wallpaper"
    "$mainMod, W, exec, dms ipc call wallpaper next"
    "$mainMod SHIFT, W, exec, dms ipc call wallpaper prev"
    "$mainMod SHIFT, T, exec, dms ipc call theme toggle"
    "$mainMod SHIFT, N, exec, dms ipc call night toggle"
    
    # Help
    "$mainMod ALT, Slash, exec, dms ipc call settings openWith keybinds"
    "$mainMod, F1, exec, dms ipc call keybinds toggle hyprland"
    "ALT, F1, exec, dms ipc call keybinds toggle hyprland"
  ];

  # ---------------------------------------------------------------------------
  # 4. SYSTEM & SCRIPTS
  # ---------------------------------------------------------------------------
  systemBinds = [
    # Custom Scripts
    "ALT, A, exec, osc-soundctl switch"
    "ALT CTRL, A, exec, osc-soundctl switch-mic"
    "ALT CTRL, M, exec, osc-wiremix"
    "ALT, E, exec, osc-spotify"
    "ALT CTRL, N, exec, osc-spotify next"
    "ALT CTRL, B, exec, osc-spotify prev"
    "ALT CTRL, E, exec, mpc-control toggle"
    "ALT, I, exec, ${bins.hyprSet} vlc-toggle"

    # Tools
    "$mainMod SHIFT, C, exec, hyprpicker -a"
    "$mainMod CTRL, V, exec, kitty --class clipse -e clipse"
    ", F10, exec, ${bins.bluetoothToggle}"
    "CTRL ALT, P, exec, powerprofilesctl-toggle"
    "ALT, F12, exec, osc-mullvad-toggle"
    "$mainMod ALT, F12, exec, osc-mullvad-slot"
    
    # Screenshots
    ", Print, exec, ${bins.screenshot} ri"
    "CTRL, Print, exec, ${bins.screenshot} si"
    "ALT, Print, exec, ${bins.screenshot} wi"
    
    # Reload Config
    "$mainMod CTRL ALT, R, exec, hyprctl reload"
    "$mainMod CTRL ALT, S, exec, ${bins.hyprSet} env-sync"
    "$mainMod CTRL ALT, D, exec, kitty --class hypr-doctor -e bash -lc '${bins.hyprSet} doctor; echo; read -n 1 -s -r -p \"Press any key to close\"'"
    
    # Custom Apps
    "ALT, T, exec, start-kkenp"
    "ALT, N, exec, anotes"
    "$mainMod ALT, Return, exec, semsumo launch --daily -all"
    "$mainMod SHIFT, A, exec, ${bins.hyprSet} arrange-windows" 
    "$mainMod, Return, exec, osc-ndrop --hypr-hide-special dropdown kitty --class dropdown"
    
    # Direct App Launchers
    "Alt, Space, exec, rofi-launcher"
    "$mainMod CTRL, Space, exec, walk"
    "$mainMod CTRL, F, exec, env GTK_THEME=${themeName}-standard+normal nemo"
    "ALT CTRL, F, exec, kitty -e yazi"
    "$mainMod, T, exec, kitty"
  ];

  # ---------------------------------------------------------------------------
  # 5. SMART WORKFLOW (Replacing Nirius)
  # ---------------------------------------------------------------------------
  smartBinds = [
    # Smart Focus-or-Spawn
    "$mainMod ALT, T, exec, ${bins.hyprSet} smart-focus kitty"
    "$mainMod ALT, B, exec, ${bins.hyprSet} smart-focus brave"
    "$mainMod ALT, M, exec, ${bins.hyprSet} smart-focus spotify"
    "$mainMod ALT, N, exec, ${bins.hyprSet} smart-focus anotes"

    # Pull-to-Me
    "$mainMod ALT SHIFT, T, exec, ${bins.hyprSet} pull-window kitty"
    "$mainMod ALT SHIFT, B, exec, ${bins.hyprSet} pull-window brave"
    "$mainMod ALT SHIFT, M, exec, ${bins.hyprSet} pull-window spotify"
    "$mainMod ALT SHIFT, N, exec, ${bins.hyprSet} pull-window anotes"
    
    # Scratchpad (BackSpace -> Special Workspace)
    "$mainMod, BackSpace, movetoworkspace, special:scratchpad"
    "ALT, BackSpace, togglespecialworkspace, scratchpad"
    "$mainMod ALT, BackSpace, togglespecialworkspace, scratchpad" # Show All equiv

    # Marks (Simulated with Named Special Workspaces)
    # Set Mark -> Move to Special
    "$mainMod ALT SHIFT, 1, movetoworkspace, special:term"
    "$mainMod ALT SHIFT, 2, movetoworkspace, special:web"
    "$mainMod ALT SHIFT, 3, movetoworkspace, special:media"
    "$mainMod ALT SHIFT, 4, movetoworkspace, special:notes"

    # Focus Mark -> Toggle Special
    "$mainMod ALT, 1, togglespecialworkspace, term"
    "$mainMod ALT, 2, togglespecialworkspace, web"
    "$mainMod ALT, 3, togglespecialworkspace, media"
    "$mainMod ALT, 4, togglespecialworkspace, notes"

    # Follow Mode (Not directly applicable)

    # ---------------------------------------------------------------------------

  ];

  # ---------------------------------------------------------------------------
  # 6. MPV MANAGER
  # ---------------------------------------------------------------------------
  mpvBinds = [
    "ALT, U, exec, mpv-manager playback"
    "$mainMod CTRL, Y, exec, mpv-manager play-yt"
    "$mainMod CTRL, F9, exec, mpv-manager stick"
    "$mainMod CTRL, F10, exec, mpv-manager move"
    "$mainMod CTRL, F11, exec, mpv-manager save-yt"
    "$mainMod CTRL, F12, exec, mpv-manager wallpaper"
  ];

  # ---------------------------------------------------------------------------
  # 7. WORKSPACES & MONITORS
  # ---------------------------------------------------------------------------
  workspaceBinds = [
    # Workspace Navigation (Helpers)
    "$mainMod CTRL, C, movetoworkspace, empty"
    "$mainMod, Page_Up, exec, ${bins.hyprSet} window-move workspace prev"
    "$mainMod, Page_Down, exec, ${bins.hyprSet} window-move workspace next"
    "$mainMod, mouse_down, workspace, e+1"
    "$mainMod, mouse_up, workspace, e-1"
    "$mainMod, mouse_left, layoutmsg, focus l"
    "$mainMod, mouse_right, layoutmsg, focus r"

    # Here to Window (Niri Alt+1..9 parity)
    "ALT, 1, exec, ${bins.oscHereHypr} Kenp"
    "ALT, 2, exec, ${bins.oscHereHypr} TmuxKenp"
    "ALT, 3, exec, ${bins.oscHereHypr} Ai"
    "ALT, 4, exec, ${bins.oscHereHypr} CompecTA"
    "ALT, 5, exec, ${bins.oscHereHypr} WebCord"
    "ALT, 6, exec, ${bins.oscHereHypr} org.telegram.desktop"
    "ALT, 7, exec, ${bins.oscHereHypr} brave-youtube.com__-Default"
    "ALT, 8, exec, ${bins.oscHereHypr} spotify"
    "ALT, 9, exec, ${bins.oscHereHypr} ferdium"
    "ALT, 0, exec, ${bins.oscHereHypr} all"
    "$mainMod ALT, 0, exec, ${bins.hyprSet} arrange-windows"

    # Monitor Focus (Niri Match)
    "$mainMod ALT, H, focusmonitor, l"
    "$mainMod ALT, L, focusmonitor, r"
    "$mainMod ALT, K, focusmonitor, u"
    "$mainMod ALT, J, focusmonitor, d"
    "$mainMod ALT, left, focusmonitor, l"
    "$mainMod ALT, right, focusmonitor, r"
    "$mainMod ALT, up, focusmonitor, u"
    "$mainMod ALT, down, focusmonitor, d"
    
    # Monitor Move
    "$mainMod ALT SHIFT, left, exec, ${bins.hyprSet} column-move monitor left"
    "$mainMod ALT SHIFT, right, exec, ${bins.hyprSet} column-move monitor right"
    "$mainMod ALT SHIFT, h, exec, ${bins.hyprSet} column-move monitor left"
    "$mainMod ALT SHIFT, l, exec, ${bins.hyprSet} column-move monitor right"
    "$mainMod CTRL, up, exec, ${bins.hyprSet} column-move monitor up"
    "$mainMod CTRL, down, exec, ${bins.hyprSet} column-move monitor down"

    # Smart Monitor Actions
    "$mainMod, A, focusmonitor, +1"
    "$mainMod, E, movecurrentworkspacetomonitor, +1"
    "$mainMod, Escape, exec, ${bins.hyprSet} workspace-move-or-focus"
  ];

in
{
  bind = 
    coreBinds ++
    layoutBinds ++
    dmsBinds ++
    systemBinds ++
    smartBinds ++
    mpvBinds ++
    workspaceBinds ++
    mkWorkspaces (lib.range 1 9) ++
    mkMoveWorkspaces (lib.range 1 9);

  bindl = lockedBinds;

  bindm = [
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
    "$mainMod, mouse:274, killactive"
  ];
  
  extraConfig = ''
    bind = $mainMod CTRL, R, submap, resize
    submap = resize
    binde = , right, resizeactive, 10 0
    binde = , left, resizeactive, -10 0
    binde = , up, resizeactive, 0 -10
    binde = , down, resizeactive, 0 10
    bind = , escape, submap, reset
    bind = , return, submap, reset
    submap = reset
  '';
}
