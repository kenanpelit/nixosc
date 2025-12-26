# modules/home/mangowc/binds.nix
# ==============================================================================
# MangoWC key bindings (config.conf snippet)
#
# Syntax reference:
#   bind=<MOD>,<KEY>,<FUNC>[,<ARG1>[,<ARG2>...]]
# MOD examples: SUPER,ALT,CTRL,SHIFT, SUPER+SHIFT, ...
# ==============================================================================
{ lib, bins, ... }:

{
  core = ''
    # ==============================================================================
    # Key bindings
    # ==============================================================================

    # DMS (launcher / shell)
    bind=SUPER,space,spawn,${bins.dms} ipc call spotlight toggle
    bind=SUPER,d,spawn,${bins.dms} ipc call dash toggle ""
    bind=SUPER,n,spawn,${bins.dms} ipc call notifications toggle
    bind=SUPER,c,spawn,${bins.dms} ipc call control-center toggle
    bind=SUPER,v,spawn,${bins.dms} ipc call clipboard toggle
    bind=SUPER+SHIFT,d,spawn,${bins.dms} ipc call dash toggle overview
    bind=SUPER+SHIFT,p,spawn,${bins.dms} ipc call processlist focusOrToggle
    bind=SUPER+CTRL,n,spawn,${bins.dms} ipc call notepad open
    bind=SUPER,comma,spawn,${bins.dms} ipc call settings focusOrToggle
    bind=SUPER,Delete,spawn,${bins.dms} ipc call powermenu toggle
    bind=CTRL+ALT,Delete,spawn,${bins.dms} ipc call powermenu toggle

    # reload config
    bind=SUPER,r,reload_config

    # terminal
    bind=SUPER,Return,spawn,${bins.terminal}

    # exit / kill
    bind=CTRL,d,killclient,
    bind=SUPER+SHIFT,q,quit
    bind=SUPER,m,quit
    bind=ALT,q,killclient,

    # focus (vim + arrows)
    bind=ALT,h,focusdir,left
    bind=ALT,l,focusdir,right
    bind=ALT,k,focusdir,up
    bind=ALT,j,focusdir,down
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
    bind=ALT,a,togglemaximizescreen,
    bind=ALT,Tab,toggleoverview,

    # tag switch (left/right)
    bind=SUPER,Left,viewtoleft,0
    bind=SUPER,Right,viewtoright,0

    # touchpad gestures (libinput)
    gesturebind=NONE,left,4,viewtoleft,0
    gesturebind=NONE,right,4,viewtoright,0

    # tags: view (Ctrl+<n>) and move (Alt+<n>)
    bind=CTRL,1,view,1,0
    bind=CTRL,2,view,2,0
    bind=CTRL,3,view,3,0
    bind=CTRL,4,view,4,0
    bind=CTRL,5,view,5,0
    bind=CTRL,6,view,6,0
    bind=CTRL,7,view,7,0
    bind=CTRL,8,view,8,0
    bind=CTRL,9,view,9,0

    bind=ALT,1,tag,1,0
    bind=ALT,2,tag,2,0
    bind=ALT,3,tag,3,0
    bind=ALT,4,tag,4,0
    bind=ALT,5,tag,5,0
    bind=ALT,6,tag,6,0
    bind=ALT,7,tag,7,0
    bind=ALT,8,tag,8,0
    bind=ALT,9,tag,9,0

    # monitor switch
    bind=ALT+SHIFT,Left,focusmon,left
    bind=ALT+SHIFT,Right,focusmon,right

    # move tag to monitor
    bind=SUPER+ALT,Left,tagmon,left,0
    bind=SUPER+ALT,Right,tagmon,right,0
  '';
}
