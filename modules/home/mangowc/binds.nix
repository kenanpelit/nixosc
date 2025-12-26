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
    # NOTE: On non-QWERTY layouts, some key combos may not work reliably; use keycodes.
    # QWERTY keycode reference: q=24 w=25 e=26 r=27 t=28 y=29 u=30 i=31 o=32 p=33
    #                  a=38 s=39 d=40 f=41 g=42 h=43 j=44 k=45 l=46
    #                  z=52 x=53 c=54 v=55 b=56 n=57 m=58 comma=59
    #
    # Use `spawn_shell` for reliable argv parsing (avoids ambiguity around spaces/quotes).
    bind=SUPER,code:65,spawn_shell,${bins.dms} ipc call spotlight toggle
    bind=SUPER,code:40,spawn_shell,${bins.dms} ipc call dash toggle ""
    bind=SUPER,code:57,spawn_shell,${bins.dms} ipc call notifications toggle
    bind=SUPER,code:54,spawn_shell,${bins.dms} ipc call control-center toggle
    bind=SUPER,code:55,spawn_shell,${bins.dms} ipc call clipboard toggle
    bind=SUPER+SHIFT,code:40,spawn_shell,${bins.dms} ipc call dash toggle overview
    bind=SUPER+SHIFT,code:33,spawn_shell,${bins.dms} ipc call processlist focusOrToggle
    bind=SUPER+CTRL,code:57,spawn_shell,${bins.dms} ipc call notepad open
    bind=SUPER,code:59,spawn_shell,${bins.dms} ipc call settings focusOrToggle
    bind=SUPER,Delete,spawn_shell,${bins.dms} ipc call powermenu toggle
    bind=CTRL+ALT,Delete,spawn_shell,${bins.dms} ipc call powermenu toggle

    # reload config
    bind=SUPER,code:27,reload_config

    # terminal
    bind=SUPER,code:36,spawn_shell,${bins.terminal}

    # exit / kill
    bind=CTRL,code:40,killclient,
    bind=SUPER,code:24,spawn_shell,true
    bind=SUPER+SHIFT,code:24,quit
    bind=SUPER,code:58,quit
    bind=ALT,code:24,killclient,

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
    bind=SUPER+SHIFT,1,tag,1,0
    bind=SUPER+SHIFT,2,tag,2,0
    bind=SUPER+SHIFT,3,tag,3,0
    bind=SUPER+SHIFT,4,tag,4,0
    bind=SUPER+SHIFT,5,tag,5,0
    bind=SUPER+SHIFT,6,tag,6,0
    bind=SUPER+SHIFT,7,tag,7,0
    bind=SUPER+SHIFT,8,tag,8,0
    bind=SUPER+SHIFT,9,tag,9,0

    # touchpad gestures (libinput)
    # Keep these native gestures enabled in Mango; Fusuma is configured to no-op
    # for Mango's 4-finger left/right to avoid double-trigger.
    gesturebind=NONE,left,4,viewtoleft_have_client,0
    gesturebind=NONE,right,4,viewtoright_have_client,0

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
