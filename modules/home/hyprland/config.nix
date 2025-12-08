# Hyprland Window Manager Configuration - Dynamic Catppuccin Theme
# modules/home/hyprland/config.nix
# Complete optimized configuration with performance enhancements and dynamic theming
{ config, lib, pkgs, ... }:

let
  # ============================================================================
  # HELPERS & COLORS
  # ============================================================================
  inherit (config.catppuccin) sources;
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;

  # Color format converter (Hex -> 0xAARRGGBB)
  mkColor = color: alpha:
    let
      hex = lib.removePrefix "#" color;
      alphaInt =
        let x = builtins.floor (alpha * 255);
        in if x < 0 then 0 else if x > 255 then 255 else x;
      toHex = n:
        let
          hexDigits = ["0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f"];
          hi = builtins.div n 16;
          lo = n - 16 * hi;
        in "${builtins.elemAt hexDigits hi}${builtins.elemAt hexDigits lo}";
    in "0x${toHex alphaInt}${hex}";

  # Binding generators
  mkWorkspaces = nums: map (n: "$mainMod, ${toString n}, workspace, ${toString n}") nums;
  mkMoveWorkspaces = nums: map (n: "$mainMod SHIFT, ${toString n}, movetoworkspacesilent, ${toString n}") nums;
  mkMoveMonitor = nums: map (n: "$mainMod CTRL, ${toString n}, exec, hypr-workspace-monitor -am ${toString n}") nums;

  # ============================================================================
  # USER CONFIGURATION (Edit these sections frequently)
  # ============================================================================
  
  # --- Startup Applications ---
  startupServices = [
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
    "nm-applet --indicator"
    "nwg-shell"
    "wl-clip-persist --clipboard both"
    "hyprctl setcursor catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors 24"
    "hypr-switch"
    "osc-soundctl init"
  ];

  # --- Monitor Configuration ---
  monitorConfig = [
    "desc:Dell Inc. DELL UP2716D KRXTR88N909L,2560x1440@59,0x0,1"
    "desc:Chimei Innolux Corporation 0x143F,1920x1200@60,320x1440,1"
    ",preferred,auto,1"
  ];

  # --- Workspace Configuration ---
  workspaceConfig = [
    "1, monitor:DELL UP2716D KRXTR88N909L, default:true"
    "2, monitor:DELL UP2716D KRXTR88N909L"
    "3, monitor:DELL UP2716D KRXTR88N909L"
    "4, monitor:DELL UP2716D KRXTR88N909L"
    "5, monitor:DELL UP2716D KRXTR88N909L"
    "6, monitor:DELL UP2716D KRXTR88N909L"
    "7, monitor:Chimei Innolux Corporation 0x143F, default:true"
    "8, monitor:Chimei Innolux Corporation 0x143F"
    "9, monitor:Chimei Innolux Corporation 0x143F"
    # Smart borders
    "w[tv1]s[false], bordersize:0, rounding:false"
    "f[1]s[false], bordersize:0, rounding:false"
    "w[t2-99]s[false], bordersize:3, rounding:true"
    # Special workspaces
    "special:dropdown, gapsout:0, gapsin:0"
    "special:scratchpad, gapsout:0, gapsin:0"
  ];

  # ============================================================================
  # WINDOW RULES DEFINITIONS
  # ============================================================================
  
  # --- Core & Stability Rules ---
  coreRules = [
    {
      name = "suppress-maximize-events";
      "match:class" = ".*";
      suppress_event = "maximize";
    }
    {
      name = "fix-xwayland-drags";
      "match:class" = "^$";
      "match:title" = "^$";
      "match:xwayland" = true;
      "match:float" = true;
      "match:fullscreen" = false;
      "match:pin" = false;
      no_focus = true;
    }
    {
      name = "context-menu-noshadow";
      "match:class" = "^()$";
      "match:title" = "^()$";
      no_shadow = true;
    }
    {
      name = "context-menu-noblur";
      "match:class" = "^()$";
      "match:title" = "^()$";
      no_blur = true;
    }
  ];

  # --- Media & Graphics Rules ---
  mediaRules = [
    {
      name = "mpv-pip";
      "match:class" = "^(mpv)$";
      float = true;
      size = "(monitor_w*0.19) (monitor_h*0.19)";
      move = "(monitor_w*0.01) (monitor_h*0.77)";
      opacity = "1.0 override 1.0 override";
      pin = true;
      idle_inhibit = "focus";
    }
    {
      name = "vlc-workspace";
      "match:class" = "^(vlc)$";
      float = true;
      size = "800 1250";
      move = "1700 90";
      workspace = 6;
      pin = true;
    }
    {
      name = "imv-float";
      "match:class" = "^(imv)$";
      float = true;
      center = true;
      size = "1200 725";
    }
    {
      name = "imv-opacity";
      "match:title" = "^(.*imv.*)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "audacious-float";
      "match:class" = "^(audacious)$";
      float = true;
    }
    {
      name = "audacious-workspace";
      "match:class" = "^(Audacious)$";
      workspace = 5;
    }
    {
      name = "pip-window";
      "match:title" = "^(Picture-in-Picture)$";
      float = true;
      pin = true;
      opacity = "1.0 override 1.0 override";
    }
  ];

  # --- Communication & Social Rules ---
  communicationRules = [
    {
      name = "discord-workspace";
      "match:class" = "^(Discord)$";
      workspace = "5 silent";
    }
    {
      name = "webcord-workspace";
      "match:class" = "^(WebCord)$";
      workspace = 5;
    }
    {
      name = "discord-lowercase";
      "match:class" = "^(discord)$";
      workspace = "5 silent";
      tile = true;
    }
    {
      name = "webcord-link-warning";
      "match:class" = "^(WebCord)$";
      "match:title" = "^(Warning: Opening link in external app)$";
      float = true;
      center = true;
    }
    {
      name = "discord-blob";
      "match:title" = "^(blob:https://discord.com).*$";
      float = true;
      center = true;
      animation = "popin";
    }
    {
      name = "whatsapp-brave";
      "match:title" = "^(web.whatsapp.com)$";
      "match:class" = "^(Brave-browser)$";
      workspace = "9 silent";
    }
    {
      name = "whatsapp-title";
      "match:title" = "^(web.whatsapp.com)$";
      workspace = "9 silent";
    }
    {
      name = "ferdium-whatsapp";
      "match:class" = "^(Ferdium)$";
      workspace = "9 silent";
    }
    {
      name = "google-meet";
      "match:title" = "^(Meet).*$";
      float = true;
      size = "918 558";
      workspace = 4;
      center = true;
    }
  ];

  # --- System & Utility Rules ---
  systemRules = [
    {
      name = "htop-float";
      "match:class" = "^(htop)$";
      float = true;
      size = "(monitor_w*0.80) (monitor_h*0.80)";
      center = true;
    }
    {
      name = "yazi-float";
      "match:class" = "^(yazi)$";
      float = true;
      center = true;
      size = "1920 1080";
    }
    {
      name = "vnc-float";
      "match:class" = "^(Vncviewer)$";
      float = true;
      center = true;
    }
    {
      name = "vnc-fullscreen";
      "match:class" = "^(Vncviewer)$";
      "match:title" = "^(.*TigerVNC)$";
      workspace = 6;
      fullscreen = true;
    }
    {
      name = "evince-workspace";
      "match:class" = "^(evince)$";
      workspace = 3;
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "rofi-pin";
      "match:class" = "^(rofi)$";
      pin = true;
    }
    {
      name = "waypaper-pin";
      "match:class" = "^(waypaper)$";
      pin = true;
    }
    {
      name = "dropdown-terminal";
      "match:class" = "^(dropdown)$";
      float = true;
      size = "(monitor_w*0.99) (monitor_h*0.50)";
      move = "(monitor_w*0.005) (monitor_h*0.03)";
      workspace = "special:dropdown";
    }
    {
      name = "scratchpad-float";
      "match:class" = "^(scratchpad)$";
      float = true;
      center = true;
    }
    {
      name = "kitty-scratch-float";
      "match:class" = "^(kitty-scratch)$";
      float = true;
      size = "(monitor_w*0.75) (monitor_h*0.60)";
      center = true;
    }
  ];

  # --- Workspace Assignment Rules ---
  workspaceRules = [
    # Browsers
    {
      name = "zen-browser";
      "match:class" = "^(zen)$";
      workspace = 1;
    }
    {
      name = "zen-private";
      "match:class" = "^(Kenp)$";
      "match:title" = "^(Zen Browser Private Browsing)$";
      workspace = "6 silent";
    }
    {
      name = "brave-private";
      "match:title" = "^(New Private Tab - Brave)$";
      workspace = "6 silent";
    }
    {
      name = "kenp-incognito";
      "match:title" = "^Kenp Browser (Inkognito)$";
      workspace = "6 silent";
    }
    {
      name = "brave-youtube";
      "match:class" = "^(brave-youtube.com__-Default)$";
      workspace = "7 silent";
    }
    {
      name = "brave-spotify";
      "match:class" = "^(Brave-browser)$";
      "match:title" = "^(Spotify - Web Player).*";
      workspace = "8 silent";
    }
    # Development
    {
      name = "tmux-workspace";
      "match:class" = "^(Tmux)$";
      "match:title" = "^(Tmux)$";
      workspace = "2 silent";
    }
    {
      name = "tmux-kenp";
      "match:class" = "^(TmuxKenp)$";
      workspace = "2 silent";
    }
    # AI / Docs / Work
    {
      name = "ai-workspace";
      "match:class" = "^(Ai)$";
      workspace = "3 silent";
    }
    {
      name = "compecta-class";
      "match:class" = "^(CompecTA)$";
      workspace = "4 silent";
    }
    {
      name = "compecta-title";
      "match:title" = "^(compecta)$";
      workspace = "4 silent";
    }
    # Security / Downloads
    {
      name = "keepassxc";
      "match:class" = "^(org.keepassxc.KeePassXC)$";
      workspace = "7 silent";
    }
    {
      name = "transmission";
      "match:class" = "^(com.transmissionbt.transmission.*)$";
      workspace = "7 silent";
    }
    {
      name = "transmission-float";
      "match:title" = "^(Transmission)$";
      float = true;
    }
    # Entertainment / VM
    {
      name = "spotify-app";
      "match:class" = "^(Spotify)$";
      workspace = "8 silent";
    }
    {
      name = "qemu-x86";
      "match:class" = "^(qemu-system-x86_64)$";
      workspace = "6 silent";
    }
    {
      name = "qemu-generic";
      "match:class" = "^(qemu)$";
      workspace = "6 silent";
    }
  ];

  # --- UI, Dialogs & Widgets Rules ---
  uiRules = [
    # Auth & Secrets
    {
      name = "ente-auth-float";
      "match:class" = "^(io.ente.auth)$";
      float = true;
      size = "400 900";
      center = true;
    }
    {
      name = "gcr-prompter";
      "match:class" = "^(gcr-prompter)$";
      float = true;
      center = true;
      pin = true;
      animation = "fade";
      opacity = "0.95 0.95";
    }
    # Audio / Network Controls
    {
      name = "volume-control-float";
      "match:title" = "^(Volume Control)$";
      float = true;
      size = "700 450";
      move = "40 55%";
    }
    {
      name = "pavucontrol-float";
      "match:class" = "^(org.pulseaudio.pavucontrol)$";
      float = true;
      size = "(monitor_w*0.60) (monitor_h*0.90)";
      animation = "popin";
    }
    {
      name = "nm-connection-editor";
      "match:class" = "^(nm-connection-editor)$";
      float = true;
      size = "1200 800";
      center = true;
    }
    {
      name = "nm-applet-float";
      "match:class" = "^(nm-applet)$";
      float = true;
      size = "360 440";
      center = true;
    }
    # Browser Specific
    {
      name = "firefox-sharing-indicator";
      "match:title" = "^(Firefox — Sharing Indicator)$";
      float = true;
      move = "0 0";
    }
    {
      name = "firefox-idle-inhibit";
      "match:class" = "^(firefox)$";
      "match:fullscreen" = true;
      idle_inhibit = "fullscreen";
    }
  ];

  # --- Generic Dialogs & Layout Rules ---
  dialogRules = [
    {
      name = "open-file-dialog";
      "match:title" = "^(Open File)$";
      float = true;
    }
    {
      name = "file-upload-dialog";
      "match:title" = "^(File Upload)$";
      float = true;
      size = "850 500";
    }
    {
      name = "replace-files-dialog";
      "match:title" = "^(Confirm to replace files)$";
      float = true;
    }
    {
      name = "file-operation-dialog";
      "match:title" = "^(File Operation Progress)$";
      float = true;
    }
    {
      name = "branch-dialog";
      "match:title" = "^(branchdialog)$";
      float = true;
    }
    {
      name = "file-progress-dialog";
      "match:class" = "^(file_progress)$";
      float = true;
    }
    {
      name = "confirm-dialog";
      "match:class" = "^(confirm)$";
      float = true;
    }
    {
      name = "dialog-generic";
      "match:class" = "^(dialog)$";
      float = true;
    }
    {
      name = "download-dialog";
      "match:class" = "^(download)$";
      float = true;
    }
    {
      name = "notification-dialog";
      "match:class" = "^(notification)$";
      float = true;
    }
    {
      name = "error-dialog";
      "match:class" = "^(error)$";
      float = true;
    }
    {
      name = "confirmreset-dialog";
      "match:class" = "^(confirmreset)$";
      float = true;
    }
    # Layout Defaults
    {
      name = "floating-border";
      "match:float" = true;
      border_size = 2;
    }
    {
      name = "floating-rounding";
      "match:float" = true;
      rounding = 10;
    }
  ];

  # --- Custom Tools (Clipboard, Notes) & Opacity Rules ---
  miscRules = [
    {
      name = "notes-float";
      "match:class" = "^(notes)$";
      float = true;
      size = "(monitor_w*0.70) (monitor_h*0.50)";
      center = true;
    }
    {
      name = "anote-float";
      "match:class" = "^(anote)$";
      float = true;
      center = true;
      size = "1536 864";
      animation = "slide";
      opacity = "0.95 0.95";
    }
    {
      name = "clipb-float";
      "match:class" = "^(clipb)$";
      float = true;
      center = true;
      size = "1536 864";
      animation = "slide";
    }
    {
      name = "copyq-float";
      "match:class" = "^(com.github.hluk.copyq)$";
      float = true;
      size = "(monitor_w*0.25) (monitor_h*0.80)";
      move = "(monitor_w*0.74) (monitor_h*0.10)";
      animation = "popin";
    }
    {
      name = "clipse-float";
      "match:class" = "^(clipse)$";
      float = true;
      size = "(monitor_w*0.25) (monitor_h*0.80)";
      move = "(monitor_w*0.74) (monitor_h*0.10)";
      animation = "popin";
    }
    # Opacity Overrides
    {
      name = "kitty-opacity";
      "match:class" = "^(kitty)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "foot-opacity";
      "match:class" = "^(foot)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "zen-opacity";
      "match:class" = "^(zen)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "brave-opacity";
      "match:class" = "^(Brave-browser)$";
      opacity = "1.0 override 1.0 override";
    }
    {
      name = "kenp-opacity";
      "match:class" = "^(Kenp)$";
      opacity = "1.0 override 1.0 override";
    }
  ];

  # ============================================================================
  # KEY BINDINGS DEFINITIONS
  # ============================================================================

  appBinds = [
    # Launchers
    "$mainMod, F1, exec, rofi-launcher keys || pkill rofi"
    "$mainMod, Space, exec, dms ipc call spotlight toggle"
    "ALT, Space, exec, rofi-launcher || pkill rofi"
    "$mainMod, backspace, exec, dms ipc call powermenu toggle"
    "$mainMod, Y, exec, dms ipc call dankdash wallpaper"
   
    # Terminals
    "$mainMod, Return, exec, kitty"
    "ALT, Return, exec, [float; center; size 950 650] kitty"
  
    # File Managers
    "ALT, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] kitty yazi'"
    "ALT CTRL, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] env GTK_THEME=catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal nemo'"
  ];

  mediaBinds = [
    # Audio Control
    "ALT, A, exec, osc-soundctl switch"
    "ALT CTRL, A, exec, osc-soundctl switch-mic"
    ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
    ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
    ", XF86AudioMute, exec, dms ipc call audio mute"
    ", XF86AudioMicMute, exec, dms ipc call audio micmute"
   
    # Playback Control (DMS MPRIS)
    ", XF86AudioPlay, exec, dms ipc call mpris playPause"
    ", XF86AudioNext, exec, dms ipc call mpris next"
    ", XF86AudioPrev, exec, dms ipc call mpris previous"
    ", XF86AudioStop, exec, dms ipc call mpris stop"
  
    # Spotify & MPV (özel scriptler)
    "ALT, E, exec, osc-spotify"
    "ALT CTRL, N, exec, osc-spotify next"
    "ALT CTRL, B, exec, osc-spotify prev"
    "ALT CTRL, E, exec, mpc-control toggle"
    "ALT, i, exec, hypr-vlc_toggle"
  
    # Brightness
    ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 backlight:intel_backlight"
    ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 backlight:intel_backlight"
  
    # MPV Manager
    "CTRL ALT, 1, exec, hypr-mpv-manager start"
    "ALT, 1, exec, hypr-mpv-manager playback"
    "ALT, 2, exec, hypr-mpv-manager play-yt"
    "ALT, 3, exec, hypr-mpv-manager stick"
    "ALT, 4, exec, hypr-mpv-manager move"
    "ALT, 5, exec, hypr-mpv-manager save-yt"
    "ALT, 6, exec, hypr-mpv-manager wallpaper"
  ];

  windowControlBinds = [
    # Basic Actions
    "$mainMod, Q, killactive"
    "$mainMod SHIFT, F, fullscreen, 1"
    "$mainMod CTRL, F, fullscreen, 0"
    "$mainMod, F, exec, toggle_float"
    "$mainMod, P, pseudo,"
    "$mainMod, X, togglesplit,"
    "$mainMod, G, togglegroup"
    "$mainMod, T, exec, toggle_opacity"
    "$mainMod, S, pin"
  
    # Layout
    "$mainMod CTRL, J, exec, hypr-layout_toggle"
    "$mainMod CTRL, RETURN, layoutmsg, swapwithmaster"
    "$mainMod, R, submap, resize"
  
    # Splitting
    "$mainMod ALT, left, exec, hyprctl dispatch splitratio -0.2"
    "$mainMod ALT, right, exec, hyprctl dispatch splitratio +0.2"
  ];

  systemBinds = [
    # Lock & Power
    # Lock screen
    "ALT, L, exec, hyprlock"
    "$mainMod CTRL, L, exec, dms ipc call inhibit toggle"
  
    # DMS Panels & Widgets
    "$mainMod, N, exec, dms ipc call notifications toggle"
    "$mainMod, comma, exec, dms ipc call settings focusOrToggle"
    "$mainMod CTRL, M, exec, dms ipc call processlist focusOrToggle"
    "$mainMod, D, exec, dms ipc call dash toggle ''"
    "$mainMod CTRL, D, exec, dms ipc call control-center toggle"
  
    # Theme & Night Mode
    "$mainMod SHIFT, T, exec, dms ipc call theme toggle"
    "$mainMod SHIFT, N, exec, dms ipc call night toggle"
  
    # Bar & Dock
    "$mainMod, B, exec, dms ipc call bar toggle index 0"
    "$mainMod SHIFT, B, exec, dms ipc call dock toggle"
    "$mainMod CTRL, B, exec, dms ipc call bar toggleAutoHide index 0"
  
    # Tools
    "$mainMod SHIFT, C, exec, hyprpicker -a"
  
    # Wallpaper
    "$mainMod, W, exec, dms ipc call wallpaper next"
    "$mainMod SHIFT, W, exec, dms ipc call wallpaper prev"
    "$mainMod CTRL, W, exec, dms ipc call file browse wallpaper"
  
    # Monitor
    "$mainMod, Escape, exec, pypr shift_monitors +1 || hyprctl dispatch focusmonitor -1"
    "$mainMod, A, exec, hyprctl dispatch focusmonitor -1"
    "$mainMod, E, exec, pypr shift_monitors +1"
  
    # Connectivity
    ", F10, exec, bluetooth_toggle"
    "ALT, F12, exec, osc-mullvad toggle"
  
    # Clipboard
    "$mainMod, V, exec, dms ipc call clipboard toggle"
    "$mainMod CTRL, V, exec, kitty --class clipse -e clipse"
  
    # Keybinds Cheatsheet
     "$mainMod, slash, exec, dms ipc call keybinds toggle hyprland"
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
    "$mainMod CTRL, N, exec, dms ipc call notepad open"
  ];

  navBinds = [
    # Workspace Nav
    "ALT, N, workspace, previous"
    "ALT, Tab, workspace, e+1"
    "ALT CTRL, tab, workspace, e-1"
    "$mainMod, page_up, exec, hypr-workspace-monitor -wl"
    "$mainMod, page_down, exec, hypr-workspace-monitor -wr"
    "$mainMod, bracketleft, workspace, e-1"
    "$mainMod, bracketright, workspace, e+1"
    "$mainMod, Tab, exec, dms ipc call hypr toggleOverview"
    "$mainMod CTRL, c, movetoworkspace, empty"
    "$mainMod, mouse_down, workspace, e-1"
    "$mainMod, mouse_up, workspace, e+1"
    
    # Scratchpad
    "$mainMod, minus, movetoworkspace, special:scratchpad"
    "$mainMod SHIFT, minus, togglespecialworkspace, scratchpad"
    
    # Focus Move (Arrow)
    "$mainMod, left, movefocus, l"
    "$mainMod, right, movefocus, r"
    "$mainMod, up, movefocus, u"
    "$mainMod, down, movefocus, d"
    # Focus Move (Vim)
    "$mainMod, h, movefocus, l"
    "$mainMod, j, movefocus, d"
    "$mainMod, k, movefocus, u"
    "$mainMod, l, movefocus, r"
    
    # Window Move (Arrow)
    "$mainMod SHIFT, left, movewindow, l"
    "$mainMod SHIFT, right, movewindow, r"
    "$mainMod SHIFT, up, movewindow, u"
    "$mainMod SHIFT, down, movewindow, d"
    # Window Move (Vim)
    "$mainMod SHIFT, h, movewindow, l"
    "$mainMod SHIFT, j, movewindow, d"
    "$mainMod SHIFT, k, movewindow, u"
    "$mainMod SHIFT, l, movewindow, r"
    
    # Resize (Arrow)
    "$mainMod CTRL, left, resizeactive, -80 0"
    "$mainMod CTRL, right, resizeactive, 80 0"
    "$mainMod CTRL, up, resizeactive, 0 -80"
    "$mainMod CTRL, down, resizeactive, 0 80"
    # Resize (Vim)
    "$mainMod CTRL, h, resizeactive, -80 0"
    "$mainMod CTRL, j, resizeactive, 0 80"
    "$mainMod CTRL, k, resizeactive, 0 -80"
    "$mainMod CTRL, l, resizeactive, 80 0"
    
    # Position (Arrow)
    "$mainMod ALT, left, moveactive,  -80 0"
    "$mainMod ALT, right, moveactive, 80 0"
    "$mainMod ALT, up, moveactive, 0 -80"
    "$mainMod ALT, down, moveactive, 0 80"
    # Position (Vim)
    "$mainMod ALT, h, moveactive,  -80 0"
    "$mainMod ALT, j, moveactive, 0 80"
    "$mainMod ALT, k, moveactive, 0 -80"
    "$mainMod ALT, l, moveactive, 80 0"
  ];

  cfg = config.my.desktop.hyprland;
in
lib.mkIf cfg.enable {
  wayland.windowManager.hyprland = {
    settings = {
      # =====================================================
      # CORE CONFIGURATION (Mapped from lists above)
      # =====================================================
      exec-once = startupServices;
      monitor = monitorConfig;
      workspace = workspaceConfig;

      input = {
        kb_layout = "tr";
        kb_variant = "f";
        kb_options = "ctrl:nocaps";
        repeat_rate = 35;
        repeat_delay = 250;
        numlock_by_default = false;
        sensitivity = 0.0;
        accel_profile = "flat";
        force_no_accel = true;
        follow_mouse = 1;
        float_switch_override_focus = 2;
        left_handed = false;
        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
          tap-to-click = true;
          drag_lock = true;
          scroll_factor = 1.0;
          clickfinger_behavior = true;
          middle_button_emulation = true;
          tap-and-drag = true;
        };
      };

      gestures = {
        workspace_swipe_distance = 300;
        workspace_swipe_touch = false;
        workspace_swipe_touch_invert = false;
        workspace_swipe_invert = true;
        workspace_swipe_min_speed_to_force = 20;
        workspace_swipe_cancel_ratio = 0.3;
        workspace_swipe_create_new = true;
        workspace_swipe_direction_lock = true;
        workspace_swipe_direction_lock_threshold = 15;
        workspace_swipe_forever = true;
      };

      # Explicit gesture bindings (Hyprland 1:1 gestures)
      gesture = [ ];

      # =====================================================
      # THEME & ENVIRONMENT
      # =====================================================
      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "DESKTOP_SESSION,Hyprland"
        "GDK_BACKEND,wayland,x11"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "OZONE_PLATFORM,wayland"
        "HYPRLAND_LOG_WLR,1"
        "HYPRLAND_NO_RT,1"
        "HYPRLAND_NO_SD_NOTIFY,1"
        "HYPRLAND_NO_WATCHDOG_WARNING,1"
        "GTK_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal"
        "GTK_USE_PORTAL,1"
        "GTK_APPLICATION_PREFER_DARK_THEME,${if (config.catppuccin.flavor == "latte") then "0" else "1"}"
        "GDK_SCALE,1"
        "XCURSOR_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors"
        "HYPRCURSOR_SIZE,32"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,kvantum"
        "QT_STYLE_OVERRIDE,kvantum"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_WAYLAND_FORCE_DPI,96"
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_WEBRENDER,1"
        "MOZ_USE_XINPUT2,1"
        "MOZ_CRASHREPORTER_DISABLE,1"
        "FREETYPE_PROPERTIES,truetype:interpreter-version=40"
        "WLR_RENDERER,vulkan"
        "LIBVA_DRIVER_NAME,iHD"
        "EDITOR,nvim"
        "VISUAL,nvim"
        "TERMINAL,kitty"
        "TERM,xterm-256color"
        "BROWSER,brave"
        "CATPPUCCIN_FLAVOR,${config.catppuccin.flavor}"
      ];

      general = {
        "$mainMod" = "SUPER";
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        "col.active_border" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        "col.inactive_border" = mkColor colors.overlay0.hex 0.66;
        layout = "master";
        allow_tearing = false;
        resize_on_border = true;
        extend_border_grab_area = 15;
        hover_icon_on_border = true;
      };

      group = {
        "col.border_active" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        "col.border_inactive" = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";
        "col.border_locked_active" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        "col.border_locked_inactive" = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";
        groupbar = {
          render_titles = false;
          gradients = false;
          font_size = 10;
          "col.active" = mkColor colors.blue.hex 0.93;
          "col.inactive" = mkColor colors.overlay0.hex 0.66;
          "col.locked_active" = mkColor colors.mauve.hex 0.93;
          "col.locked_inactive" = mkColor colors.surface1.hex 0.66;
        };
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        fullscreen_opacity = 1.0;
        dim_inactive = true;
        dim_strength = 0.15;
        blur = {
          enabled = true;
          size = 10;
          passes = 3;
          ignore_opacity = true;
          new_optimizations = true;
          xray = true;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
          special = false;
          popups = true;
          popups_ignorealpha = 0.2;
        };
        shadow = {
          enabled = true;
          ignore_window = true;
          offset = "0 4";
          range = 25;
          render_power = 2;
          color = mkColor colors.crust.hex 0.26;
          scale = 0.97;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "fluent, 0.05, 0.20, 0.00, 1.00"
          "easeOutCirc, 0.00, 0.55, 0.45, 1.00"
          "overshoot, 0.20, 0.80, 0.20, 1.20"
          "catppuccinSmooth, 0.25, 0.1, 0.25, 1"
          "linear, 0.00, 0.00, 1.00, 1.00"
        ];
        animation = [
          "windows, 1, 3, overshoot, slide"
          "windowsOut, 1, 2, easeOutCirc, popin 80%"
          "fade, 1, 4, easeOutCirc"
          "workspaces, 1, 4, catppuccinSmooth, slide"
          "border, 1, 1, linear"
        ];
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        background_color = mkColor colors.base.hex 1.0;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 1;
        vfr = true;
        disable_autoreload = false;
        disable_hyprland_guiutils_check = true;
        focus_on_activate = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        enable_swallow = true;
        swallow_regex = "^(kitty|foot|alacritty|wezterm)$";
        swallow_exception_regex = "^(wev|Wayland-desktop|wl-clipboard)$";
        mouse_move_focuses_monitor = true;
        initial_workspace_tracking = 1;
        close_special_on_empty = true;
        allow_session_lock_restore = true;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        special_scale_factor = 0.8;
        force_split = 2;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        default_split_ratio = 1.0;
      };

      master = {
        new_on_top = false;
        new_status = "slave";
        mfact = 0.60;
        orientation = "left";
        smart_resizing = true;
        drop_at_cursor = false;
        allow_small_split = false;
        special_scale_factor = 0.8;
        new_on_active = "after";
      };

      binds = {
        pass_mouse_when_bound = true;
        workspace_back_and_forth = true;
        allow_workspace_cycles = true;
        workspace_center_on = 1;
        focus_preferred_method = 0;
        ignore_group_lock = true;
      };

      # =====================================================
      # CONSOLIDATED LISTS
      # =====================================================
      windowrule = 
        coreRules ++ 
        mediaRules ++ 
        communicationRules ++ 
        systemRules ++ 
        workspaceRules ++ 
        uiRules ++ 
        dialogRules ++ 
        miscRules;

      bind = 
        appBinds ++
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
    };

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
  };
}
