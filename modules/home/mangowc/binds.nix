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

    # --------------------------------------------------------------------------
    # Notes on syntax
    #
    # Mango `bind=` resolves letters by keycode (depends on XKB layout).
    # Use `binds=` for letter shortcuts so they follow the active layout (TR-F).
    #
    # Use `bindsl=` for keys that should work while locked (volume/media/brightness).
    # --------------------------------------------------------------------------

    # --------------------------------------------------------------------------
    # DMS Integration (match Niri muscle memory)
    # --------------------------------------------------------------------------
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

    # Bar & Dock
    binds=SUPER,b,spawn_shell,${bins.dms} ipc call bar toggle index 0
    binds=SUPER+CTRL,b,spawn_shell,${bins.dms} ipc call bar toggleAutoHide index 0
    binds=SUPER+SHIFT,b,spawn_shell,${bins.dms} ipc call dock toggle

    # Wallpaper & Theming
    binds=SUPER,y,spawn_shell,${bins.dms} ipc call dankdash wallpaper
    binds=SUPER,w,spawn_shell,${bins.dms} ipc call wallpaper next
    binds=SUPER+SHIFT,w,spawn_shell,${bins.dms} ipc call wallpaper prev
    binds=SUPER+SHIFT,t,spawn_shell,${bins.dms} ipc call theme toggle
    binds=SUPER+SHIFT,n,spawn_shell,${bins.dms} ipc call night toggle

    # Help / Keybinds (DMS settings page)
    binds=SUPER+ALT,slash,spawn_shell,${bins.dms} ipc call settings openWith keybinds
    binds=SUPER,F1,spawn_shell,${bins.dms} ipc call settings openWith keybinds
    binds=ALT,F1,spawn_shell,${bins.dms} ipc call settings openWith keybinds

    # Alt-Tab style app switcher (DMS)
    binds=ALT,Tab,spawn_shell,${bins.dms} ipc call spotlight openQuery "!"

    # Mango overview (restore legacy Super+Tab muscle memory)
    bind=SUPER,Tab,toggleoverview,

    # --------------------------------------------------------------------------
    # Core Window Management
    # --------------------------------------------------------------------------

    # Applications
    binds=SUPER,Return,spawn_shell,${bins.terminal}
    binds=SUPER,t,spawn_shell,${bins.terminal}
    binds=SUPER+ALT,Return,spawn_shell,${bins.semsumo} launch --daily -all

    # Window controls
    binds=SUPER,q,killclient
    binds=SUPER+SHIFT,q,quit
    binds=SUPER,f,togglemaximizescreen
    binds=SUPER+CTRL,f,togglemaximizescreen
    binds=SUPER+SHIFT,f,togglefullscreen
    binds=SUPER,o,toggleoverlay
    binds=SUPER,r,switch_proportion_preset
    binds=SUPER+SHIFT,space,togglefloating
    bind=SUPER,BackSpace,focuslast

    # Stack / "consume/expel"-like (cycle stack)
    bind=SUPER,bracketleft,exchange_stack_client,prev
    bind=SUPER,bracketright,exchange_stack_client,next

    # Focus (match Niri: Mod+H/L focus, Mod+K/J workspace)
    bind=SUPER,Left,focusdir,left
    bind=SUPER,Right,focusdir,right
    binds=SUPER,h,focusdir,left
    binds=SUPER,l,focusdir,right
    bind=ALT,Left,focusdir,left
    bind=ALT,Right,focusdir,right
    bind=ALT,Up,focusdir,up
    bind=ALT,Down,focusdir,down

    # Workspace (tags): your preferred Mod+Ctrl navigation
    bind=SUPER+CTRL,Right,viewtoleft,0
    bind=SUPER+CTRL,Left,viewtoright,0
    binds=SUPER,k,viewtoleft,0
    binds=SUPER,j,viewtoright,0
    bind=SUPER,Page_Up,viewtoleft,0
    bind=SUPER,Page_Down,viewtoright,0

    # Swap / move windows (Niri Mod+Shift+Arrows/HJKL)
    bind=SUPER+SHIFT,Left,exchange_client,left
    bind=SUPER+SHIFT,Right,exchange_client,right
    bind=SUPER+SHIFT,Up,exchange_client,up
    bind=SUPER+SHIFT,Down,exchange_client,down
    binds=SUPER+SHIFT,h,exchange_client,left
    binds=SUPER+SHIFT,l,exchange_client,right
    binds=SUPER+SHIFT,k,exchange_client,up
    binds=SUPER+SHIFT,j,exchange_client,down

    # Reload config (keep both)
    binds=SUPER+CTRL,r,reload_config
    binds=SUPER+CTRL+ALT,r,reload_config

    # --------------------------------------------------------------------------
    # Workspace numbers (Niri-style)
    # --------------------------------------------------------------------------
    bind=SUPER,1,view,1,0
    bind=SUPER,2,view,2,0
    bind=SUPER,3,view,3,0
    bind=SUPER,4,view,4,0
    bind=SUPER,5,view,5,0
    bind=SUPER,6,view,6,0
    bind=SUPER,7,view,7,0
    bind=SUPER,8,view,8,0
    bind=SUPER,9,view,9,0

    # Move focused window to workspace
    bind=ALT,1,tag,1,0
    bind=ALT,2,tag,2,0
    bind=ALT,3,tag,3,0
    bind=ALT,4,tag,4,0
    bind=ALT,5,tag,5,0
    bind=ALT,6,tag,6,0
    bind=ALT,7,tag,7,0
    bind=ALT,8,tag,8,0
    bind=ALT,9,tag,9,0

    # Move focused window to previous/next workspace (Niri Mod+Shift+Page_Up/Down)
    bind=SUPER+SHIFT,Page_Up,tagtoleft,0
    bind=SUPER+SHIFT,Page_Down,tagtoright,0

    # --------------------------------------------------------------------------
    # Monitors (directional, similar intent to Niri)
    # --------------------------------------------------------------------------
    binds=SUPER+ALT,h,focusmon,left
    binds=SUPER+ALT,l,focusmon,right
    binds=SUPER+ALT,k,focusmon,up
    binds=SUPER+ALT,j,focusmon,down

    # Move focused window to monitor (Niri Mod+Ctrl+Arrows)
    bind=SUPER+CTRL,Left,tagmon,left,0
    bind=SUPER+CTRL,Right,tagmon,right,0
    bind=SUPER+CTRL,Up,tagmon,up,0
    bind=SUPER+CTRL,Down,tagmon,down,0

    # --------------------------------------------------------------------------
    # Window sizing (Niri-like)
    # --------------------------------------------------------------------------
    # "Column width" analog: master area factor
    bind=SUPER+ALT,Left,setmfact,-0.05
    bind=SUPER+ALT,Right,setmfact,+0.05

    # Window height adjust (matches your Niri binds)
    bind=SUPER+ALT,Up,resizewin,+0,-100
    bind=SUPER+ALT,Down,resizewin,+0,+100

    # --------------------------------------------------------------------------
    # Utilities / Apps
    # --------------------------------------------------------------------------

    # Launchers
    binds=ALT,space,spawn_shell,rofi-launcher || pkill rofi
    binds=SUPER+CTRL,space,spawn_shell,walk

    # File Managers
    binds=ALT,f,spawn_shell,${bins.terminal} -e yazi
    binds=ALT+CTRL,f,spawn_shell,nemo

    # Notes
    binds=SUPER,m,spawn_shell,anotes

    # Color picker
    binds=SUPER+SHIFT,c,spawn_shell,hyprpicker -a

    # Clipboard TUI
    binds=SUPER+CTRL,v,spawn_shell,${bins.terminal} --class clipse -e ${bins.clipse}

    # Toggles
    binds=NONE,F10,spawn_shell,${bins.bluetoothToggle}
    binds=ALT,F12,spawn_shell,osc-mullvad toggle

    # KKENP
    binds=ALT,t,spawn_shell,${bins.startKkenp}

    # Audio scripts
    binds=ALT,a,spawn_shell,osc-soundctl switch
    binds=ALT+CTRL,a,spawn_shell,osc-soundctl switch-mic

    # Media scripts
    binds=ALT,e,spawn_shell,osc-spotify
    binds=ALT+CTRL,n,spawn_shell,osc-spotify next
    binds=ALT+CTRL,b,spawn_shell,osc-spotify prev
    binds=ALT+CTRL,e,spawn_shell,mpc-control toggle
    binds=ALT,i,spawn_shell,vlc-toggle

    # Lock / inhibit
    binds=ALT,l,spawn_shell,${bins.dms} ipc call lock lock || loginctl lock-session
    binds=SUPER+SHIFT,Delete,spawn_shell,${bins.dms} ipc call inhibit toggle

    # --------------------------------------------------------------------------
    # Media / Brightness keys (allow while locked)
    # --------------------------------------------------------------------------
    bindsl=NONE,XF86AudioRaiseVolume,spawn_shell,${bins.dms} ipc call audio increment 5
    bindsl=NONE,XF86AudioLowerVolume,spawn_shell,${bins.dms} ipc call audio decrement 5
    bindsl=NONE,XF86AudioMute,spawn_shell,${bins.dms} ipc call audio mute
    bindsl=NONE,XF86AudioMicMute,spawn_shell,${bins.dms} ipc call audio micmute

    bindsl=NONE,XF86AudioPlay,spawn_shell,${bins.dms} ipc call mpris playPause
    bindsl=NONE,XF86AudioNext,spawn_shell,${bins.dms} ipc call mpris next
    bindsl=NONE,XF86AudioPrev,spawn_shell,${bins.dms} ipc call mpris previous
    bindsl=NONE,XF86AudioStop,spawn_shell,${bins.dms} ipc call mpris stop

    bindsl=NONE,XF86MonBrightnessUp,spawn_shell,${bins.dms} ipc call brightness increment 5 ""
    bindsl=NONE,XF86MonBrightnessDown,spawn_shell,${bins.dms} ipc call brightness decrement 5 ""

    binds=SUPER+ALT,a,spawn_shell,${bins.dms} ipc call audio cycleoutput
    binds=SUPER+ALT,p,spawn_shell,pavucontrol

    # --------------------------------------------------------------------------
    # Screenshots
    # --------------------------------------------------------------------------
	    binds=NONE,Print,spawn_shell,${bins.screenshot} ri
	    binds=CTRL,Print,spawn_shell,${bins.screenshot} sc
	    binds=ALT,Print,spawn_shell,${bins.screenshot} wi

    # --------------------------------------------------------------------------
    # MPV manager (match Niri)
    # --------------------------------------------------------------------------
    binds=SUPER+SHIFT,1,spawn_shell,mpv-manager playback
    binds=SUPER+SHIFT,2,spawn_shell,mpv-manager play-yt
    binds=SUPER+SHIFT,3,spawn_shell,mpv-manager stick
    binds=SUPER+SHIFT,4,spawn_shell,mpv-manager move
    binds=SUPER+SHIFT,5,spawn_shell,mpv-manager save-yt
    binds=SUPER+SHIFT,6,spawn_shell,mpv-manager wallpaper

    ${lib.optionalString (!fusumaEnabled) ''
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
  '';
}
