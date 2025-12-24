# modules/home/hyprland/binds.nix
# ==============================================================================
# Hyprland Key Bindings & Submaps
#
# Contains all input mappings including application launchers, window controls,
# navigation, workspace management, and DMS integration.
# Imported by default.nix
# ==============================================================================
{ lib, themeName, ... }:

let
  # Binding generators
  mkWorkspaces = nums: map (n: "$mainMod, ${toString n}, workspace, ${toString n}") nums;
  mkMoveWorkspaces = nums: map (n: "$mainMod SHIFT, ${toString n}, movetoworkspacesilent, ${toString n}") nums;
  mkMoveMonitor = nums: map (n: "$mainMod CTRL, ${toString n}, exec, hypr-set workspace-monitor -am ${toString n}") nums;
  
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
    "$mainMod, F1, exec, rofi-launcher keys || pkill rofi"
    "ALT, Space, exec, rofi-launcher || pkill rofi"
    "$mainMod CTRL, Space, exec, walk"
   
    # Terminals
    "$mainMod, Return, exec, kitty"
    "ALT, Return, exec, [float; center; size 950 650] kitty"
  
    # File Managers
    "ALT, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] kitty yazi'"
    "ALT CTRL, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] env GTK_THEME=${themeName}-standard+normal nemo'"
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
    "ALT, i, exec, hypr-set vlc-toggle"
  
    # MPV Manager
    "CTRL ALT, 1, exec, mpv-manager start"
    "ALT, 1, exec, mpv-manager playback"
    "ALT, 2, exec, mpv-manager play-yt"
    "ALT, 3, exec, mpv-manager stick"
    "ALT, 4, exec, mpv-manager move"
    "ALT, 5, exec, mpv-manager save-yt"
    "ALT, 6, exec, mpv-manager wallpaper"
  ];

  windowControlBinds = [
    # Basic Actions
    "$mainMod, Q, killactive"
    "$mainMod SHIFT, F, fullscreen, 1"
    "$mainMod CTRL, F, fullscreen, 0"
    "$mainMod, F, exec, hypr-set toggle-float"
    "$mainMod, P, pseudo,"
    "$mainMod, X, togglesplit,"
    "$mainMod, G, togglegroup"
    "$mainMod, T, exec, hypr-set toggle-opacity"
    "$mainMod, S, pin"
  
    # Layout
    "$mainMod CTRL, J, exec, hypr-set layout-toggle"
    "$mainMod CTRL, RETURN, layoutmsg, swapwithmaster"
    "$mainMod, R, submap, resize"
  
    # Splitting
    "$mainMod ALT, left, exec, hyprctl dispatch splitratio -0.2"
    "$mainMod ALT, right, exec, hyprctl dispatch splitratio +0.2"
  ];

  systemBinds = [
    # Tools
    "$mainMod SHIFT, C, exec, hyprpicker -a"
  
    # Monitor
    "$mainMod, Escape, exec, pypr shift_monitors +1 || hyprctl dispatch focusmonitor -1"
    "$mainMod, A, exec, hyprctl dispatch focusmonitor -1"
    "$mainMod, E, exec, pypr shift_monitors +1"
  
    # Connectivity
    ", F10, exec, bluetooth_toggle"
    "ALT, F12, exec, osc-mullvad toggle"
  
    # Clipboard (local)
    "$mainMod CTRL, V, exec, kitty --class clipse -e clipse"
  ];

  screenshotBinds = [
    ", Print, exec, screenshot ri"
    "$mainMod CTRL, Print, exec, screenshot rec"
    "$mainMod, Print, exec, screenshot si"
    "ALT, Print, exec, screenshot wi"
    "$mainMod ALT, Print, exec, screenshot p"
    "$mainMod SHIFT CTRL, Print, exec, screenshot sec"
  ];

  specialAppsBinds = [
    "ALT, T, exec, start-kkenp"
    "$mainMod ALT, RETURN, exec, semsumo launch --daily"
    "$mainMod, M, exec, anotes"
  ];

  navBinds = [
    # Workspace Nav
    "ALT, N, workspace, previous"
    "ALT, Tab, workspace, e+1"
    "ALT CTRL, tab, workspace, e-1"
    "$mainMod, page_up, exec, hypr-set workspace-monitor -wl"
    "$mainMod, page_down, exec, hypr-set workspace-monitor -wr"
    "$mainMod, bracketleft, workspace, e-1"
    "$mainMod, bracketright, workspace, e+1"
    "$mainMod CTRL, c, movetoworkspace, empty"
    "$mainMod, mouse_down, workspace, e-1"
    "$mainMod, mouse_up, workspace, e+1"
  ]
  ++ [
    # Scratchpad
    "$mainMod, minus, movetoworkspace, special:scratchpad"
    "$mainMod SHIFT, minus, togglespecialworkspace, scratchpad"
  ]
  ++ mkDirectionalBinds "$mainMod" "movefocus" "dir"
  ++ mkDirectionalBinds "$mainMod SHIFT" "movewindow" "dir"
  ++ mkDirectionalBinds "$mainMod CTRL" "resizeactive" "resizeDelta"
  ++ mkDirectionalBinds "$mainMod ALT" "moveactive" "delta";

  dmsBinds = [
    # Launchers & power
    "$mainMod, Space, exec, dms ipc call spotlight toggle"
    "$mainMod, backspace, exec, dms ipc call powermenu toggle"
    "$mainMod, delete, exec, dms ipc call lock lock"
    "ALT, L, exec, dms ipc call lock lock"
    "$mainMod SHIFT, delete, exec, dms ipc call inhibit toggle"

    # Dash & panels
    "$mainMod, D, exec, dms ipc call dash toggle ''"
    "$mainMod, C, exec, dms ipc call control-center toggle"
    "$mainMod, N, exec, dms ipc call notifications toggle"
    "$mainMod, comma, exec, dms ipc call settings focusOrToggle"
    "$mainMod SHIFT, P, exec, dms ipc call processlist focusOrToggle"
    "$mainMod SHIFT, K, exec, dms ipc call settings openWith keybinds"

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
    "$mainMod, Tab, exec, dms ipc call hypr toggleOverview"
    "$mainMod CTRL, N, exec, dms ipc call notepad open"

    # Clipboard & keybinds cheat sheet
    "$mainMod, V, exec, dms ipc call clipboard toggle"
    "$mainMod, slash, exec, dms ipc call keybinds toggle hyprland"

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
    mkMoveMonitor (lib.range 1 9) ++
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
