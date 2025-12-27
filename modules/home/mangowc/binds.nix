# modules/home/mangowc/binds.nix
# ==============================================================================
# MangoWC key bindings (config.conf snippet)
#
# Syntax reference:
#   bind=<MOD>,<KEY>,<FUNC>[,<ARG1>[,<ARG2>...]]
# MOD examples: SUPER,ALT,CTRL,SHIFT, SUPER+SHIFT, ...
# ==============================================================================
{ lib, bins, fusumaEnabled ? false, ... }:

{
  core = ''
    # ==============================================================================
    # Key bindings
    # ==============================================================================

    # DMS (launcher / shell)
    #
    # Mango `bind=` converts keysyms to keycodes using the configured XKB layout
    # (`xkb_rules_layout=tr` / `xkb_rules_variant=f`), so Mod+V really means "V"
    # on your TR-F layout (instead of "QWERTY V physical key").
    #
    # IMPORTANT: We use `binds=` (keysym-based) so letter shortcuts follow the
    # active keyboard layout (TR-F) instead of QWERTY physical positions.
    binds=SUPER,space,spawn_shell,${bins.dms} ipc call spotlight toggle
    binds=SUPER,d,spawn_shell,${bins.dms} ipc call dash toggle ""
    binds=SUPER,n,spawn_shell,${bins.dms} ipc call notifications toggle
    binds=SUPER,c,spawn_shell,${bins.dms} ipc call control-center toggle
    binds=SUPER,v,spawn_shell,${bins.dms} ipc call clipboard toggle
    # Fallback launcher (Rofi) like Niri/Hyprland
    binds=ALT,space,spawn_shell,rofi-launcher || pkill rofi
    binds=SUPER+SHIFT,d,spawn_shell,${bins.dms} ipc call dash toggle overview
    binds=SUPER+SHIFT,p,spawn_shell,${bins.dms} ipc call processlist focusOrToggle
    binds=SUPER+CTRL,n,spawn_shell,${bins.dms} ipc call notepad open
    binds=SUPER,comma,spawn_shell,${bins.dms} ipc call settings focusOrToggle
    binds=SUPER,Delete,spawn_shell,${bins.dms} ipc call powermenu toggle
    binds=CTRL+ALT,Delete,spawn_shell,${bins.dms} ipc call powermenu toggle

    # reload config
    binds=SUPER,r,reload_config

    # terminal
    binds=SUPER,Return,spawn_shell,${bins.terminal}
    binds=SUPER+ALT,Return,spawn_shell,${bins.semsumo} launch --daily -all

    # exit / kill
    binds=SUPER,q,killclient,
    binds=SUPER+SHIFT,q,quit

    # focus (vim + arrows)
    bind=SUPER,h,focusdir,left
    bind=SUPER,l,focusdir,right
    bind=SUPER,k,focusdir,up
    bind=SUPER,j,focusdir,down
    bind=ALT,Left,focusdir,left
    bind=ALT,Right,focusdir,right
    bind=ALT,Up,focusdir,up
    bind=ALT,Down,focusdir,down

    # swap windows
    bind=SUPER+SHIFT,h,exchange_client,left
    bind=SUPER+SHIFT,l,exchange_client,right
    bind=SUPER+SHIFT,k,exchange_client,up
    bind=SUPER+SHIFT,j,exchange_client,down

    # toggles
    bind=ALT,backslash,togglefloating,
    bind=ALT,f,togglefullscreen,
    bind=ALT,x,togglemaximizescreen,
    binds=ALT,Tab,toggleoverview,

    # tag switch (left/right)
    bind=SUPER,Left,viewtoleft,0
    bind=SUPER,Right,viewtoright,0

    # workspaces (tags) on SUPER
    bind=SUPER,1,view,1,0
    bind=SUPER,2,view,2,0
    bind=SUPER,3,view,3,0
    bind=SUPER,4,view,4,0
    bind=SUPER,5,view,5,0
    bind=SUPER,6,view,6,0
    bind=SUPER,7,view,7,0
    bind=SUPER,8,view,8,0
    bind=SUPER,9,view,9,0
    bind=ALT,1,tag,1,0
    bind=ALT,2,tag,2,0
    bind=ALT,3,tag,3,0
    bind=ALT,4,tag,4,0
    bind=ALT,5,tag,5,0
    bind=ALT,6,tag,6,0
    bind=ALT,7,tag,7,0
    bind=ALT,8,tag,8,0
    bind=ALT,9,tag,9,0

    ${lib.optionalString (!(fusumaEnabled or false)) ''
    # touchpad gestures (libinput)
    # If Fusuma is enabled, let it own gesture handling to avoid double-trigger.

    # 3-finger: directional focus (matches the mental model from niri/hyprland).
    gesturebind=NONE,left,3,focusdir,left
    gesturebind=NONE,right,3,focusdir,right
    gesturebind=NONE,up,3,focusdir,up
    gesturebind=NONE,down,3,focusdir,down

    # 4-finger: workspace + overview.
    # Route workspace through our router for consistent behavior (wrap-around).
    gesturebind=NONE,left,4,spawn_shell,${bins.wmWorkspace} -wl
    gesturebind=NONE,right,4,spawn_shell,${bins.wmWorkspace} -wr
    gesturebind=NONE,up,4,toggleoverview
    gesturebind=NONE,down,4,toggleoverview
    ''}

    # monitor switch
    # Vertical monitor layout (external top, laptop bottom)
    bind=ALT+SHIFT,Up,focusmon,up
    bind=ALT+SHIFT,Down,focusmon,down

    # move focused window to monitor
    # (Mango/dwl semantics: tagmon moves the focused client to the target output)
    bind=SUPER+CTRL,Left,tagmon,left,0
    bind=SUPER+CTRL,Right,tagmon,right,0
    bind=SUPER+CTRL,Up,tagmon,up,0
    bind=SUPER+CTRL,Down,tagmon,down,0

    # ==============================================================================
    # App / Utility binds (aligned with Niri)
    # ==============================================================================
    binds=ALT,t,spawn_shell,start-kkenp
    binds=SUPER,m,spawn_shell,anotes

    binds=F10,spawn_shell,bluetooth_toggle
    binds=ALT,F12,spawn_shell,osc-mullvad toggle

    binds=ALT,a,spawn_shell,osc-soundctl switch
    binds=ALT+CTRL,a,spawn_shell,osc-soundctl switch-mic

    binds=ALT,e,spawn_shell,osc-spotify

    # Screenshots (DMS)
    binds=Print,spawn_shell,${bins.dms} screenshot
    binds=CTRL,Print,spawn_shell,${bins.dms} screenshot full
    binds=ALT,Print,spawn_shell,${bins.dms} screenshot window

    binds=SUPER+SHIFT,1,spawn_shell,mpv-manager start
    binds=SUPER+SHIFT,2,spawn_shell,mpv-manager playback
    binds=SUPER+SHIFT,3,spawn_shell,mpv-manager play-yt
    binds=SUPER+SHIFT,4,spawn_shell,mpv-manager stick
    binds=SUPER+SHIFT,5,spawn_shell,mpv-manager move
    binds=SUPER+SHIFT,6,spawn_shell,mpv-manager save-yt
    binds=SUPER+SHIFT,7,spawn_shell,mpv-manager wallpaper
  '';
}
