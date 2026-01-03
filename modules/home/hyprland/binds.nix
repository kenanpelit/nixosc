# modules/home/hyprland/binds.nix
# ==============================================================================
# Hyprland Key Bindings & Submaps
#
# Contains all input mappings including application launchers, window controls,
# navigation, workspace management, and DMS integration.
# Imported by default.nix
# ==============================================================================
{ lib, themeName, bins, ... }:

let
  # Binding generators
  mkWorkspaces = nums: map (n: "$mainMod, ${toString n}, workspace, ${toString n}") nums;
  mkMoveWorkspaces = nums: map (n: "$mainMod SHIFT, ${toString n}, movetoworkspacesilent, ${toString n}") nums;
  mkPullAppsFromWorkspace = nums: map (n: "$mainMod ALT, ${toString n}, exec, ${bins.hyprSet} workspace-monitor -am ${toString n}") nums;
  
  moveStep = 80;
  resizeStep = 80;
  
  directions = [
    { arrow = "left"; vim = "h"; dir = "l"; delta = "-${toString moveStep} 0"; resizeDelta = "-${toString resizeStep} 0"; }
    { arrow = "right"; vim = "l"; dir = "r"; delta = "${toString moveStep} 0"; resizeDelta = "${toString resizeStep} 0"; }
    { arrow = "up"; vim = "k"; dir = "u"; delta = "0 -${toString moveStep}"; resizeDelta = "0 -${toString resizeStep}"; }
    { arrow = "down"; vim = "j"; dir = "d"; delta = "0 ${toString moveStep}"; resizeDelta = "0 ${toString resizeStep}"; }
  ];
  
  mkDirectionalBinds = mod: command: field:
    lib.concatMap
      (d: [
        "${mod}, ${d.arrow}, ${command}, ${builtins.getAttr field d}"
        "${mod}, ${d.vim}, ${command}, ${builtins.getAttr field d}"
      ])
      directions;

  appBinds = [
    # Launchers
    "ALT, F1, exec, rofi-launcher keys || pkill rofi"
    "ALT, Space, exec, rofi-launcher || pkill rofi"
    "$mainMod CTRL, Space, exec, walk"
   
    # Terminals
    "$mainMod, T, exec, kitty"
    #"ALT, Return, exec, [float; center; size 950 650] kitty"
  
    # File Managers
    "$mainMod CTRL, F, exec, env GTK_THEME=${themeName}-standard+normal nemo"
    "ALT CTRL, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] kitty yazi'"
  ];

  mediaBinds = [
    # Audio Control
    "ALT, A, exec, osc-soundctl switch"
    "ALT CTRL, A, exec, osc-soundctl switch-mic"
    #", F4, exec, osc-soundctl mic mute"
   
    # Playback Control (DMS MPRIS)
  
    # Spotify & MPV (özel scriptler)
    "ALT, E, exec, osc-spotify"
    "ALT CTRL, N, exec, osc-spotify next"
    "ALT CTRL, B, exec, osc-spotify prev"
    "ALT CTRL, E, exec, mpc-control toggle"
    "ALT, i, exec, ${bins.hyprSet} vlc-toggle"
  
    # MPV Manager
    "$mainMod CTRL, 1, exec, mpv-manager playback"
    "$mainMod CTRL, 2, exec, mpv-manager play-yt"
    "$mainMod CTRL, 3, exec, mpv-manager stick"
    "$mainMod CTRL, 4, exec, mpv-manager move"
    "$mainMod CTRL, 5, exec, mpv-manager save-yt"
    "$mainMod CTRL, 6, exec, mpv-manager wallpaper"
  ];

  windowControlBinds = [
    # Basic Actions
    "$mainMod, Q, killactive"
    "$mainMod SHIFT, F, fullscreen, 1"
    "$mainMod, F, fullscreen, 0"
    "$mainMod, G, exec, ${bins.hyprSet} toggle-float"
    "$mainMod, P, exec, ${bins.hyprSet} pin"
    "$mainMod, Z, exec, ${bins.hyprSet} zen"
    "$mainMod, X, togglesplit,"
    "$mainMod SHIFT, G, togglegroup"
    "$mainMod, O, exec, ${bins.hyprSet} toggle-opacity"
    "$mainMod SHIFT, S, pin"
    "$mainMod SHIFT, mouse_down, exec, ${bins.hyprSet} opacity"
    "$mainMod SHIFT, mouse_up, exec, ${bins.hyprSet} opacity"
  
    # Hyprscrolling: cycle the preconfigured column widths (conf list)
    "$mainMod CTRL, R, layoutmsg, colresize +conf"
    "$mainMod CTRL SHIFT, R, layoutmsg, colresize -conf"
    "$mainMod, RETURN, layoutmsg, promote"
    "$mainMod SHIFT, comma, layoutmsg, move -col"
    "$mainMod SHIFT, period, layoutmsg, move +col"
    "$mainMod CTRL SHIFT, comma, layoutmsg, colresize -0.05"
    "$mainMod CTRL SHIFT, period, layoutmsg, colresize +0.05"
    "$mainMod CTRL SHIFT, h, layoutmsg, swapcol l"
    "$mainMod CTRL SHIFT, l, layoutmsg, swapcol r"
    "$mainMod CTRL SHIFT, left, layoutmsg, swapcol l"
    "$mainMod CTRL SHIFT, right, layoutmsg, swapcol r"
    "$mainMod, U, layoutmsg, togglefit"
    "$mainMod, home, layoutmsg, fit tobeg"
    "$mainMod, end, layoutmsg, fit toend"
  
    # Layout
    "$mainMod CTRL, J, exec, ${bins.hyprSet} layout-toggle"
    "$mainMod CTRL, RETURN, layoutmsg, swapwithmaster"
    "$mainMod, R, submap, resize"
  
    # Splitting
    "$mainMod CTRL ALT, left, exec, hyprctl dispatch splitratio -0.2"
    "$mainMod CTRL ALT, right, exec, hyprctl dispatch splitratio +0.2"
  ];

  systemBinds = [
    # Tools
    "$mainMod SHIFT, C, exec, hyprpicker -a"
  
    # Monitor
    "$mainMod, Escape, exec, pypr shift_monitors +1 || hyprctl dispatch focusmonitor -1"
    "$mainMod, A, exec, hyprctl dispatch focusmonitor -1"
    "$mainMod, E, exec, pypr shift_monitors +1"
    "$mainMod SHIFT, M, exec, ${bins.hyprSet} window-move monitor other"
  
    # Connectivity
    ", F10, exec, ${bins.bluetoothToggle}"
    "ALT, F12, exec, osc-mullvad toggle"
  
    # Clipboard (local)
    "$mainMod CTRL, V, exec, kitty --class clipse -e clipse"
  ];

  screenshotBinds = [
    ", Print, exec, ${bins.screenshot} ri"
    "CTRL, Print, exec, ${bins.screenshot} si"
    "ALT, Print, exec, ${bins.screenshot} wi"
    "$mainMod ALT, Print, exec, ${bins.screenshot} p"
  ];

  specialAppsBinds = [
    "ALT, T, exec, start-kkenp"
    "$mainMod ALT, RETURN, exec, semsumo launch --daily -all"
    "ALT, N, exec, anotes"
  ];

  navBinds = [
    # Navigation (Niri-like)
    "$mainMod, left, layoutmsg, focus l"
    "$mainMod, h, layoutmsg, focus l"
    "$mainMod, right, layoutmsg, focus r"
    "$mainMod, l, layoutmsg, focus r"

    "$mainMod, up, exec, ${bins.hyprSet} workspace-monitor -wu"
    "$mainMod, k, exec, ${bins.hyprSet} workspace-monitor -wu"
    "$mainMod, down, exec, ${bins.hyprSet} workspace-monitor -wd"
    "$mainMod, j, exec, ${bins.hyprSet} workspace-monitor -wd"

    # Old behavior
    "ALT, Tab, workspace, e+1"
    "ALT CTRL, tab, workspace, e-1"

    "$mainMod SHIFT, left, layoutmsg, movewindowto l"
    "$mainMod SHIFT, h, layoutmsg, movewindowto l"
    "$mainMod SHIFT, right, layoutmsg, movewindowto r"
    "$mainMod SHIFT, l, layoutmsg, movewindowto r"
    "$mainMod SHIFT, up, layoutmsg, movewindowto u"
    "$mainMod SHIFT, k, layoutmsg, movewindowto u"
    "$mainMod SHIFT, down, layoutmsg, movewindowto d"
    "$mainMod SHIFT, j, layoutmsg, movewindowto d"

    # Monitor focus (Niri-like)
    "$mainMod ALT, left, exec, hyprctl dispatch focusmonitor l"
    "$mainMod ALT, h, exec, hyprctl dispatch focusmonitor l"
    "$mainMod ALT, right, exec, hyprctl dispatch focusmonitor r"
    "$mainMod ALT, l, exec, hyprctl dispatch focusmonitor r"
    "$mainMod ALT, up, exec, hyprctl dispatch focusmonitor u"
    "$mainMod ALT, k, exec, hyprctl dispatch focusmonitor u"
    "$mainMod ALT, down, exec, hyprctl dispatch focusmonitor d"
    "$mainMod ALT, j, exec, hyprctl dispatch focusmonitor d"

    # Workspace helpers
    "$mainMod CTRL, c, movetoworkspace, empty"
    "$mainMod, mouse_down, workspace, e-1"
    "$mainMod, mouse_up, workspace, e+1"
    "$mainMod, Prior, exec, ${bins.hyprSet} window-move workspace prev"
    "$mainMod, Next, exec, ${bins.hyprSet} window-move workspace next"
  ]
  ++ [
    # Scratchpad
    "$mainMod, minus, movetoworkspace, special:scratchpad"
    "$mainMod SHIFT, minus, togglespecialworkspace, scratchpad"
  ]
  ++ mkDirectionalBinds "$mainMod CTRL" "resizeactive" "resizeDelta"
  ;

  dmsBinds = [
    # Launchers & power
    "$mainMod, Space, exec, dms ipc call spotlight toggle"
    "$mainMod, delete, exec, dms ipc call powermenu toggle"
    "ALT, L, exec, dms ipc call lock lock"
    "$mainMod SHIFT, delete, exec, dms ipc call inhibit toggle"

    # Dash & panels
    "$mainMod, D, exec, dms ipc call dash toggle ''"
    "$mainMod, C, exec, dms ipc call control-center toggle"
    "$mainMod, N, exec, dms ipc call notifications toggle"
    "$mainMod, comma, exec, dms ipc call settings focusOrToggle"
    "$mainMod SHIFT, P, exec, dms ipc call processlist focusOrToggle"
    "$mainMod SHIFT, K, exec, dms ipc call settings openWith keybinds"
    "$mainMod ALT, slash, exec, dms ipc call settings openWith keybinds"

    # Theme & night mode
    "$mainMod SHIFT, T, exec, dms ipc call theme toggle"
    "$mainMod SHIFT, N, exec, dms ipc call night toggle"

    # Bar & Dock
    "$mainMod, B, exec, dms ipc call bar toggle index 0"
    "$mainMod SHIFT, B, exec, dms ipc call dock toggle"
    "$mainMod CTRL, B, exec, dms ipc call bar toggleAutoHide index 0"

    # Wallpaper & overview
    "$mainMod, Y, exec, dms ipc call dankdash wallpaper"
    "$mainMod, W, exec, dms ipc call wallpaper next"
    "$mainMod SHIFT, W, exec, dms ipc call wallpaper prev"
    "$mainMod CTRL, W, exec, dms ipc call file browse wallpaper"
    "$mainMod, S, exec, dms ipc call hypr toggleOverview"
    "$mainMod, Tab, hyprexpo:expo, toggle"
    "$mainMod CTRL, N, exec, dms ipc call notepad open"

    # Clipboard & keybinds cheat sheet
    "$mainMod, V, exec, dms ipc call clipboard toggle"
    "$mainMod, F1, exec, dms ipc call keybinds toggle hyprland"

    # Audio & brightness (DMS-managed)
    ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
    ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
    ", XF86AudioMute, exec, dms ipc call audio mute"
    ", XF86AudioMicMute, exec, dms ipc call audio micmute"
    ", XF86AudioPlay, exec, dms ipc call mpris playPause"
    ", XF86AudioNext, exec, dms ipc call mpris next"
    ", XF86AudioPrev, exec, dms ipc call mpris previous"
    ", XF86AudioStop, exec, dms ipc call mpris stop"
    ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 backlight:intel_backlight"
    ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 backlight:intel_backlight"
    "$mainMod ALT, A, exec, dms ipc call audio cycleoutput"
    "$mainMod ALT, B, exec, dms ipc call brightness toggleExponential backlight:intel_backlight"
  ];

in
{
  bind = 
    appBinds ++
    dmsBinds ++
    mediaBinds ++
    windowControlBinds ++
    systemBinds ++
    screenshotBinds ++
    specialAppsBinds ++
    navBinds ++
    mkPullAppsFromWorkspace (lib.range 1 9) ++
    mkWorkspaces (lib.range 1 9) ++
    mkMoveWorkspaces (lib.range 1 9);

  bindm = [
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
  ];
  
  extraConfig = ''
    submap = resize
    binde = , h, resizeactive, -10 0
    binde = , l, resizeactive, 10 0
    binde = , k, resizeactive, 0 -10
    binde = , j, resizeactive, 0 10
    binde = , left, resizeactive, -10 0
    binde = , right, resizeactive, 10 0
    binde = , up, resizeactive, 0 -10
    binde = , down, resizeactive, 0 10
    bind = , escape, submap, reset
    bind = , return, submap, reset
    submap = reset
  '';
}
