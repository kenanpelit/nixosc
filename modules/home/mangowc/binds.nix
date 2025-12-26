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

    # exit / kill
    binds=CTRL,d,killclient,
    binds=SUPER,q,spawn_shell,true
    binds=SUPER+SHIFT,q,quit
    binds=SUPER,m,quit
    binds=ALT,q,killclient,

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
    # Route through our workspace router for consistent behavior (wrap-around).
    gesturebind=NONE,left,4,spawn_shell,${bins.wmWorkspace} -wl
    gesturebind=NONE,right,4,spawn_shell,${bins.wmWorkspace} -wr

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
