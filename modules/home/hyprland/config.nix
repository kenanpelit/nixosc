# Hyprland Window Manager Configuration - Dynamic Catppuccin Theme
# modules/home/hyprland/config.nix
{ config, lib, pkgs, ... }:
let
  # Catppuccin modülünden otomatik renk alımı
  inherit (config.catppuccin) sources;
  
  # Palette JSON'dan renkler - dinamik flavor desteği
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # FIXED: Simpler color function for Hyprland - using direct hex format
  mkColor = color: alpha:
    let
      hex = lib.removePrefix "#" color;
      # Convert alpha to 0-255 range and format as hex
      alphaInt = builtins.floor (alpha * 255);
      alphaHex = if alphaInt < 16 then "0${lib.toHexString alphaInt}" else lib.toHexString alphaInt;
    in "0x${alphaHex}${hex}";
    
  # Alternative: Simple rgba format that should work
  mkRgba = color: alpha:
    let
      hex = lib.removePrefix "#" color;
      r = lib.toInt "0x${builtins.substring 0 2 hex}";
      g = lib.toInt "0x${builtins.substring 2 2 hex}";
      b = lib.toInt "0x${builtins.substring 4 2 hex}";
      a = toString (builtins.floor (alpha * 255));
    in "rgba(${toString r}, ${toString g}, ${toString b}, ${a})";
in
{
  wayland.windowManager.hyprland = {
    settings = {
      # =====================================================
      # Startup Applications and System Services
      # =====================================================
      exec-once = [
        # Initialize Wayland environment variables for proper system integration
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"
        # Update DBus environment for Wayland session
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
        # NetworkManagerApplet
        "nm-applet --indicator"
        # Keep clipboard content persistent across program restarts
        "wl-clip-persist --clipboard both"
        # Enhanced clipboard management with cliphist
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        # Advanced clipboard manager with searchable history
        "copyq"
        # Set system cursor theme and size - Dynamic Catppuccin
        "hyprctl setcursor catppuccin-${config.catppuccin.flavor}-cursor 24"
        # Initialize wallpaper daemon for dynamic wallpapers
        "swww-daemon"
        # Start wallpaper rotation/management service
        "wallpaper-manager start"
        # Initialize workspace layout
        "m2w2"
        # Start in service-mode application launcher
        "walker --gapplication-service"
        # Initialize screen locker for security
        "hyprlock"
        # Set initial audio levels
        "osc-soundctl init"
      ];

      # =====================================================
      # Environment Variables - Dynamic Catppuccin Theme
      # =====================================================
      env = [
        # Wayland Core Settings
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_CURRENT_DESKTOP,Hyprland"
	      "DESKTOP_SESSION,Hyprland"

        # Wayland Backend Settings
        "GDK_BACKEND,wayland"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "OZONE_PLATFORM,wayland"

        # Hyprland Specific Settings
        "HYPRLAND_LOG_WLR,1"
        "HYPRLAND_NO_RT,1"
        "HYPRLAND_NO_SD_NOTIFY,1"

        # Dynamic GTK Theme - Changes with flavor
        "GTK_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal"
        "GTK_USE_PORTAL,1"
        "GTK_APPLICATION_PREFER_DARK_THEME,${if (config.catppuccin.flavor == "latte") then "0" else "1"}"
        "GDK_SCALE,1"
        
        # Dynamic Cursor Theme - Changes with flavor  
        "XCURSOR_THEME,catppuccin-${config.catppuccin.flavor}-dark-cursors"
        "XCURSOR_SIZE,24"

        # Qt/KDE Theme Settings
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,gtk3"
        "QT_STYLE_OVERRIDE,kvantum"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"

        # Firefox Settings
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_WEBRENDER,1"
        "MOZ_USE_XINPUT2,1"
        "MOZ_CRASHREPORTER_DISABLE,1"

        # Font Rendering
        "FREETYPE_PROPERTIES,truetype:interpreter-version=40"

        # System Variables
        "EDITOR,nvim"
        "VISUAL,nvim"
        "TERMINAL,kitty"
        "TERM,xterm-256color"
        "BROWSER,brave"
        
        # Debug: Show current flavor
        "CATPPUCCIN_FLAVOR,${config.catppuccin.flavor}"
      ];

      # =====================================================
      # Input Configuration
      # =====================================================
      input = {
        kb_layout = "tr";
        kb_variant = "f";
        kb_options = "ctrl:nocaps";
        repeat_rate = 35;
        repeat_delay = 250;
        sensitivity = 0.0;
        accel_profile = "flat";

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

        numlock_by_default = false;
        left_handed = false;
        follow_mouse = 1;
        float_switch_override_focus = 2;
        force_no_accel = true;
      };

      # =====================================================
      # General Settings - Dynamic Catppuccin Colors
      # =====================================================
      general = {
        "$mainMod" = "SUPER";
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        
        # Dynamic Catppuccin Colors - Using hex format instead of RGBA
        "col.active_border" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        # Dynamic Catppuccin Colors - Inactive border with overlay0
        "col.inactive_border" = mkColor colors.overlay0.hex 0.66;
        
        layout = "master";
        allow_tearing = false;
        resize_on_border = true;
        extend_border_grab_area = 15;
        hover_icon_on_border = true;
        no_border_on_floating = false;
      };

      # =====================================================
      # Group Settings - Dynamic Catppuccin Colors
      # =====================================================
      group = {
        # Dynamic active group border
        "col.border_active" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        # Dynamic inactive group border
        "col.border_inactive" = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";
        # Dynamic locked active group border
        "col.border_locked_active" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        # Dynamic locked inactive group border
        "col.border_locked_inactive" = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";
        
        groupbar = {
          render_titles = false;
          gradients = false;
          font_size = 10;
          # Dynamic groupbar colors
          "col.active" = mkColor colors.blue.hex 0.93;
          "col.inactive" = mkColor colors.overlay0.hex 0.66;
          "col.locked_active" = mkColor colors.mauve.hex 0.93;
          "col.locked_inactive" = mkColor colors.surface1.hex 0.66;
        };
      };

      # =====================================================
      # Misc Settings - Dynamic Catppuccin Background
      # =====================================================
      misc = {
        # Appearance
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;

        # Power Management
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 1;

        # Performance
        vfr = true;
        disable_autoreload = false;

        # Window Behavior
        focus_on_activate = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;

        # Terminal Swallow
        enable_swallow = true;
        swallow_regex = "^(kitty|foot|alacritty|wezterm)$";
        swallow_exception_regex = "^(wev|Wayland-desktop)$";

        # Monitor & Focus
        mouse_move_focuses_monitor = true;
        initial_workspace_tracking = 1;

        # Special Features
        close_special_on_empty = true;
        new_window_takes_over_fullscreen = 2;
        allow_session_lock_restore = true;
        
        # Dynamic background color - using hex format
        background_color = mkColor colors.base.hex 1.0;
      };

      # =====================================================
      # Gestures Configuration
      # =====================================================
      gestures = {
      #  workspace_swipe = false;
      #  workspace_swipe_fingers = 3;
      #  workspace_swipe_min_fingers = false;
        workspace_swipe_distance = 200;
        workspace_swipe_touch = false;
        workspace_swipe_touch_invert = false;
        workspace_swipe_invert = true;
        workspace_swipe_min_speed_to_force = 20;
        workspace_swipe_cancel_ratio = 0.3;
        workspace_swipe_create_new = true;
        workspace_swipe_direction_lock = true;
        workspace_swipe_direction_lock_threshold = 15;
        workspace_swipe_forever = false;
        workspace_swipe_use_r = false;
      };

      # =====================================================
      # Layout Configurations
      # =====================================================
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
        inherit_fullscreen = true;
        smart_resizing = true;
        drop_at_cursor = false;
        allow_small_split = false;
        special_scale_factor = 0.8;
      };

      # =====================================================
      # Keybinding Settings
      # =====================================================
      binds = {
        pass_mouse_when_bound = true;
        workspace_back_and_forth = true;
        allow_workspace_cycles = true;
        workspace_center_on = true;
        focus_preferred_method = 0;
        ignore_group_lock = true;
      };

      # =====================================================
      # Visual Effects - Dynamic Catppuccin Colors
      # =====================================================
      decoration = {
        rounding = 10;

        # Opacity
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        fullscreen_opacity = 1.0;

        # Dimming
        dim_inactive = true;
        dim_strength = 0.15;

        # Blur Effects
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
          ignore_opacity = true;
          new_optimizations = true;
          xray = false;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
          special = false;
          popups = true;
          popups_ignorealpha = 0.2;
        };

        # Dynamic Shadow - using crust color with transparency
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

      # =====================================================
      # Animations - Dynamic Catppuccin Smooth Transitions
      # =====================================================
      animations = {
        enabled = true;

        bezier = [
          "fluent_decel, 0, 0.2, 0.4, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "catppuccinSmooth, 0.25, 0.1, 0.25, 1"
        ];

        animation = [
          "windows, 1, 2, easeOutCubic, slide"
          "windowsOut, 1, 2, easeOutCubic, slide"
          "fade, 1, 3, easeOutCirc"
          "workspaces, 1, 3, catppuccinSmooth"
          "border, 1, 1, linear"
        ];
      };

      # =====================================================
      # Window Rules (keeping all your existing rules)
      # =====================================================
      windowrule = [
        # Media Applications
        "float,class:^(mpv)$"
        "size 19%,class:^(mpv)$"
        "move 1% 77%,class:^(mpv)$"
        "opacity 1.0 override 1.0 override,class:^(mpv)$"
        "pin,class:^(mpv)$"
        "idleinhibit focus,class:^(mpv)$"

        # VLC Media Player
        "float,class:^(vlc)$"
        "size 800 1250,class:^(vlc)$"
        "move 1700 90,class:^(vlc)$"
        "workspace 6,class:^(vlc)$"
        "pin,class:^(vlc)$"

        # Image Viewers
        "float,class:^(Viewnior)$"
        "center,class:^(Viewnior)$"
        "size 1200 800,class:^(Viewnior)$"
        "float,class:^(imv)$"
        "center,class:^(imv)$"
        "size 1200 725,class:^(imv)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"

        # Audio
        "float,class:^(audacious)$"
        "workspace 5,class:^(Audacious)$"

        # Productivity Applications
        "tile,class:^(Aseprite)$"
        "workspace 4,class:^(Aseprite)$"
        "opacity 1.0 override 1.0 override,class:^(Aseprite)$"
        "workspace 4,class:^(Gimp-2.10)$"
        "tile,class:^(neovide)$"
        "opacity 1.0 override 1.0 override,class:^(Unity)$"

        # Document Viewer
        "workspace 3,class:^(evince)$"
        "opacity 1.0 override 1.0 override,class:^(evince)$"

        # OBS Studio
        "workspace 8,class:^(com.obsproject.Studio)$"

        # System Utilities
        "float,class:^(Vncviewer)$"
        "center,class:^(Vncviewer)$"
        "workspace 6,class:^(Vncviewer)$,title:^(.*TigerVNC)$"
        "fullscreen,class:^(Vncviewer)$,title:^(.*TigerVNC)$"

        # File Management
        "float,class:^(udiskie)$"
        "float,class:^(org.gnome.FileRoller)$"
        "center,class:^(org.gnome.FileRoller)$"
        "size 850 500,class:^(org.gnome.FileRoller)$"

        # Terminal Applications
        "float,class:^(yazi)$"
        "center,class:^(yazi)$"
        "size 1920 1080,class:^(yazi)$"
        "float,class:^(ranger)$"
        "size 75% 60%,class:^(ranger)$"
        "center,class:^(ranger)$"

        # System Monitor
        "float,class:^(htop)$"
        "size 80% 80%,class:^(htop)$"
        "center,class:^(htop)$"

        # Scratchpad Terminals
        "float,class:^(scratchpad)$"
        "center,class:^(scratchpad)$"
        "float,class:^(kitty-scratch)$"
        "size 75% 60%,class:^(kitty-scratch)$"
        "center,class:^(kitty-scratch)$"

        # Communication
        "workspace 5 silent,class:^(Discord)$"
        "workspace 5,class:^(WebCord)$"
        "workspace 5 silent,tile,class:^(discord)$"
        "float,class:^(WebCord)$,title:^(Warning: Opening link in external app)$"
        "center,class:^(WebCord)$,title:^(Warning: Opening link in external app)$"
        "float,title:^(blob:https://discord.com).*$"
        "center,title:^(blob:https://discord.com).*$"
        "animation popin,title:^(blob:https://discord.com).*$"

        # WhatsApp
        "workspace 9 silent,class:^(Whats)$"
        "workspace 9 silent,title:^(web.whatsapp.com)$ class:^(Brave-browser)$"
        "workspace 9 silent,title:^(web.whatsapp.com)$"
        "workspace 9 silent,class:^(Ferdium)$,title:^(Ferdium)$"

        # Video Conferencing
        "float,title:^(Meet).*$"
        "size 918 558,title:^(Meet).*$"
        "workspace 4,title:^(Meet).*$"
        "center,title:^(Meet).*$"

        # Workspace Assignments
        "workspace 1,class:^(zen)$"
        "workspace 6 silent,class:^(Kenp)$,title:^(Zen Browser Private Browsing)$"
        "workspace 6 silent,title:^(New Private Tab - Brave)$"
        "workspace 6 silent,title:^Kenp Browser (Inkognito)$"
        "workspace 7 silent,title:^(brave-youtube.com__-Default)$"
        "workspace 8 silent,class:^(Brave-browser)$,title:^(Spotify - Web Player).*"

        # Development/Terminal
        "workspace 2 silent,class:^(Tmux)$,title:^(Tmux)$"
        "workspace 2 silent,class:^(TmuxKenp)$"

        # AI/Documents
        "workspace 3 silent,class:^(AI)$"

        # Work/Projects
        "workspace 4 silent,class:^(CompecTA)$"
        "workspace 4 silent,title:^(compecta)$"

        # Security/System
        "workspace 7 silent,class:^(org.keepassxc.KeePassXC)$"
        "workspace 7 silent,class:^(com.transmissionbt.transmission.*)$"

        # Entertainment
        "workspace 8 silent,class:^(Spotify)$"
        "workspace 6 silent,class:^(qemu-system-x86_64)$"
        "workspace 6 silent,class:^(qemu)$"

        # Launcher & System Tools
        "pin,class:^(rofi)$"
        "pin,class:^(waypaper)$"

        # Notes & Clipboard
        "float,class:^(notes)$"
        "size 70% 50%,class:^(notes)$"
        "center,class:^(notes)$"
        "float,class:^(anote)$"
        "center,class:^(anote)$"
        "size 1536 864,class:^(anote)$"
        "animation slide,class:^(anote)$"
        "opacity 0.95 0.95,class:^(anote)$"

        # Clipboard Manager
        "float,class:^(clipb)$"
        "center,class:^(clipb)$"
        "size 1536 864,class:^(clipb)$"
        "animation slide,class:^(clipb)$"
        "float,class:^(com.github.hluk.copyq)$"
        "size 25% 80%,class:^(com.github.hluk.copyq)$"
        "move 74% 10%,class:^(com.github.hluk.copyq)$"
        "animation popout,class:^(com.github.hluk.copyq)$"
        "dimaround,class:^(com.github.hluk.copyq)$"

        # Dropdown Terminal
        "float,class:^(dropdown)$"
        "size 99% 50%,class:^(dropdown)$"
        "move 0.5% 3%,class:^(dropdown)$"
        "workspace special:dropdown,class:^(dropdown)$"

        # Shortwave Radio Player
        "float,class:^(de.haeckerfelix.Shortwave)$"
        "size 30% 80%,class:^(de.haeckerfelix.Shortwave)$"
        "move 65% 10%,class:^(de.haeckerfelix.Shortwave)$"
        "workspace 8,class:^(de.haeckerfelix.Shortwave)$"

        # Authentication & Security
        "float,class:^(otpclient)$"
        "size 20%,class:^(otpclient)$"
        "move 79% 40%,class:^(otpclient)$"
        "opacity 1.0 1.0,class:^(otpclient)$"
        "float,class:^(io.ente.auth)$"
        "size 400 900,class:^(io.ente.auth)$"
        "center,class:^(io.ente.auth)$"

        # System Prompts
        "float,class:^(gcr-prompter)$"
        "center,class:^(gcr-prompter)$"
        "pin,class:^(gcr-prompter)$"
        "animation fade,class:^(gcr-prompter)$"
        "opacity 0.95 0.95,class:^(gcr-prompter)$"

        # Audio Control
        "float,title:^(Volume Control)$"
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
        "float,class:^(org.pulseaudio.pavucontrol)$"
        "size 60% 90%,class:^(org.pulseaudio.pavucontrol)$"
        "animation popin,class:^(org.pulseaudio.pavucontrol)$"
        "dimaround,class:^(org.pulseaudio.pavucontrol)$"

        # Network Management
        "float,class:^(org.twosheds.iwgtk)$"
        "size 1536 864,class:^(org.twosheds.iwgtk)$"
        "center,class:^(org.twosheds.iwgtk)$"
        "float,class:^(iwgtk)$"
        "size 360 440,class:^(iwgtk)$"
        "center,class:^(iwgtk)$"
        "float,class:^(nm-connection-editor)$"
        "size 1200 800,class:^(nm-connection-editor)$"
        "center,class:^(nm-connection-editor)$"
        "float,class:^(org.gnome.NetworkDisplays)$"
        "size 1200 800,class:^(org.gnome.NetworkDisplays)$"
        "center,class:^(org.gnome.NetworkDisplays)$"
        "float,class:^(nm-applet)$"
        "size 360 440,class:^(nm-applet)$"
        "center,class:^(nm-applet)$"

        # Gaming & Emulation
        "float,class:^(.sameboy-wrapped)$"
        "float,class:^(SoundWireServer)$"

        # Generic Dialog Rules
        "float,title:^(Open File)$"
        "float,title:^(File Upload)$"
        "size 850 500,title:^(File Upload)$"
        "float,title:^(Confirm to replace files)$"
        "float,title:^(File Operation Progress)$"
        "float,title:^(branchdialog)$"

        # System Dialogs
        "float,class:^(file_progress)$"
        "float,class:^(confirm)$"
        "float,class:^(dialog)$"
        "float,class:^(download)$"
        "float,class:^(notification)$"
        "float,class:^(error)$"
        "float,class:^(confirmreset)$"
        "float,class:^(zenity)$"
        "center,class:^(zenity)$"
        "size 850 500,class:^(zenity)$"

        # Browser Specific
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"
        "idleinhibit fullscreen,class:^(firefox)$"

        # Transmission
        "float,title:^(Transmission)$"

        # Picture-in-Picture
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
        "opacity 1.0 override 1.0 override,title:^(Picture-in-Picture)$"

        # XWayland Video Bridge
        "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"

        # Context Menu Optimization
        "opaque,class:^()$,title:^()$"
        "noshadow,class:^()$,title:^()$"
        "noblur,class:^()$,title:^()$"

        # Terminal Opacity Overrides
        "opacity 1.0 override 1.0 override,class:^(kitty)$"
        "opacity 1.0 override 1.0 override,class:^(foot)$"
        "opacity 1.0 override 1.0 override,class:^(Alacritty)$"

        # Browser Opacity Overrides
        "opacity 1.0 override 1.0 override,class:^(zen)$"

        # Global Layout Rules
        "bordersize 2, floating:0"
        "rounding 10, floating:0"
      ];

      # No gaps workspace rules
      workspace = [
        "w[1], gapsout:0, gapsin:0"
        "w[2], gapsout:0, gapsin:0"
        "w[3], gapsout:0, gapsin:0"
        "w[4], gapsout:0, gapsin:0"
        "w[5], gapsout:0, gapsin:0"
        "w[6], gapsout:0, gapsin:0"
        "w[7], gapsout:0, gapsin:0"
        "w[8], gapsout:0, gapsin:0"
        "w[9], gapsout:0, gapsin:0"
      ];

      # Key Bindings (keeping all your existing bindings)
      bind = [
        # show keybinds list
        "$mainMod, F1, exec, rofi-hypr-keybinds"

        # Terminal Emulators
        "$mainMod, Return, exec, kitty"
        "ALT, Return, exec, [float; center; size 950 650] kitty"
        "$mainMod SHIFT, Return, exec, [fullscreen] kitty"

        # Basic Window Management
        "$mainMod, Q, killactive"
        "ALT, F4, killactive"
        "$mainMod SHIFT, F, fullscreen, 1"
        "$mainMod CTRL, F, fullscreen, 0"
        "$mainMod, F, exec, toggle_float"
        "$mainMod, P, pseudo,"
        "$mainMod, X, togglesplit,"
        "$mainMod, G, togglegroup"
        "$mainMod, T, exec, toggle_oppacity"

        # Application Launchers
        "$mainMod, Space, exec, rofi-launcher || pkill rofi"
        "ALT, Space, exec, rofi-custom-launcher || pkill rofi"
        #"ALT, Space, exec, walker"
        #"$mainMod ALT, Space, exec, ulauncher-toggle"
        "ALT, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] kitty yazi'"
        "ALT CTRL, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] env GTK_THEME=catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal nemo'"

        # Media and Audio Control
        "ALT, A, exec, osc-soundctl switch"
        "ALT CTRL, A, exec, osc-soundctl switch-mic"
        "ALT, E, exec, osc-spotify"
        "ALT CTRL, N, exec, osc-spotify next"
        "ALT CTRL, B, exec, osc-spotify prev"
        "ALT CTRL, E, exec, mpc-control toggle"
        "ALT, i, exec, hypr-vlc_toggle"

        # MPV Management
        "CTRL ALT, 1, exec, hypr-mpv-manager start"
        "ALT, 1, exec, hypr-mpv-manager playback"
        "ALT, 2, exec, hypr-mpv-manager play-yt"
        "ALT, 3, exec, hypr-mpv-manager stick"
        "ALT, 4, exec, hypr-mpv-manager move"
        "ALT, 5, exec, hypr-mpv-manager save-yt"
        "ALT, 6, exec, hypr-mpv-manager wallpaper"

        # Wallpaper Management
        "$mainMod, W, exec, wallpaper-manager select"
        "ALT, 0, exec, wallpaper-manager"
        "$mainMod SHIFT, W, exec, hyprctl dispatch exec '[float; center; size 925 615] waypaper'"

        # System Tools
        "ALT, L, exec, hyprlock"
        "$mainMod, backspace, exec, power-menu"
        "$mainMod, C, exec, hyprpicker -a"
        "$mainMod, N, exec, makoctl restore"
        "$mainMod CTRL, N, exec, makoctl dismiss --all"
        "$mainMod CTRL, Escape, exec, hyprctl dispatch exec '[workspace 12] resources'"

        # Monitor and Display Management
        "$mainMod, Escape, exec, pypr shift_monitors +1 || hypr-ctl_focusmonitor"
        "$mainMod, A, exec, hypr-ctl_focusmonitor"
        "$mainMod, E, exec, pypr shift_monitors +1"
        "$mainMod SHIFT, B, exec, toggle_waybar"

        # Special Applications
        "$mainMod SHIFT, D, exec, webcord --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "$mainMod SHIFT, K, exec, hyprctl dispatch exec '[workspace 1 silent] start-brave-kenp'"
        "$mainMod SHIFT, C, exec, hyprctl dispatch exec '[workspace 4 silent] start-brave-compecta'"
        "$mainMod SHIFT, S, exec, hyprctl dispatch exec '[workspace 8 silent] start-spotify'"
        "$mainMod SHIFT, X, exec, hyprctl dispatch exec '[workspace 11 silent] SoundWireServer'"
        "ALT CTRL, W, exec, whatsie -w"
        "ALT, T, exec, start-kkenp"
        "ALT CTRL, C, exec, start-mkenp"
        "$mainMod ALT, RETURN, exec, osc-start_hypr launch --daily"

        # System Functions
        ",F10, exec, hypr-bluetooth_toggle"
        "ALT, F12, exec, osc-mullvad toggle"
        "$mainMod, M, exec, anotes"
        "$mainMod CTRL, M, exec, anotes -t"
        "$mainMod, B, exec, hypr-start-manager tcopyb"

        # Screenshot Shortcuts
        ",Print, exec, screenshot ri"
        "$mainMod SHIFT, Print, exec, screenshot rf"
        "CTRL, Print, exec, screenshot rc"
        "$mainMod CTRL, Print, exec, screenshot rec"
        "$mainMod, Print, exec, screenshot si"
        "SHIFT, Print, exec, screenshot sf"
        "CTRL SHIFT, Print, exec, screenshot sc"
        "$mainMod SHIFT CTRL, Print, exec, screenshot sec"
        "ALT, Print, exec, screenshot wi"
        "ALT SHIFT, Print, exec, screenshot wf"
        "ALT CTRL, Print, exec, screenshot wc"
        "$mainMod ALT, Print, exec, screenshot p"
        "$mainMod ALT CTRL, Print, exec, screenshot o"

        # Move apps from specific workspaces to current workspace
        "$mainMod CTRL, 1, exec, hypr_move_app_from_workspace 1"
        "$mainMod CTRL, 2, exec, hypr_move_app_from_workspace 2"
        "$mainMod CTRL, 3, exec, hypr_move_app_from_workspace 3"
        "$mainMod CTRL, 4, exec, hypr_move_app_from_workspace 4"
        "$mainMod CTRL, 5, exec, hypr_move_app_from_workspace 5"
        "$mainMod CTRL, 6, exec, hypr_move_app_from_workspace 6"
        "$mainMod CTRL, 7, exec, hypr_move_app_from_workspace 7"
        "$mainMod CTRL, 8, exec, hypr_move_app_from_workspace 8"
        "$mainMod CTRL, 9, exec, hypr_move_app_from_workspace 9"

        # Focus Movement
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"

        # Workspace Switching
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"

        # Move to Workspace
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod CTRL, c, movetoworkspace, empty"

        # Window Movement
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        # Window Resizing
        "$mainMod CTRL, left, resizeactive, -80 0"
        "$mainMod CTRL, right, resizeactive, 80 0"
        "$mainMod CTRL, up, resizeactive, 0 -80"
        "$mainMod CTRL, down, resizeactive, 0 80"
        "$mainMod CTRL, h, resizeactive, -80 0"
        "$mainMod CTRL, j, resizeactive, 0 80"
        "$mainMod CTRL, k, resizeactive, 0 -80"
        "$mainMod CTRL, l, resizeactive, 80 0"

        # Window Moving
        "$mainMod ALT, left, moveactive,  -80 0"
        "$mainMod ALT, right, moveactive, 80 0"
        "$mainMod ALT, up, moveactive, 0 -80"
        "$mainMod ALT, down, moveactive, 0 80"
        "$mainMod ALT, h, moveactive,  -80 0"
        "$mainMod ALT, j, moveactive, 0 80"
        "$mainMod ALT, k, moveactive, 0 -80"
        "$mainMod ALT, l, moveactive, 80 0"

        # Media Keys
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop,exec, playerctl stop"
        ",XF86AudioMicMute, exec, toggle-mic"

        # Mouse Wheel
        "$mainMod, mouse_down, workspace, e-1"
        "$mainMod, mouse_up, workspace, e+1"

        # Clipboard Manager
        "$mainMod, V, exec, copyq toggle"
        "$mainMod CTRL, V, exec, chist all"
         
        # Layout Management
        "$mainmod CTRL, J, exec, hypr-layout_toggle"
        "$mainMod CTRL, RETURN, layoutmsg, swapwithmaster"

        # Workspace Navigation
        "ALT, N, workspace, previous"
        "ALT, Tab, workspace, e+1"
        "ALT CTRL, tab, workspace, e-1"

        # Cyclical Workspace Navigation
        "$mainMod, page_up, exec, hypr-workspace-monitor -wl"
        "$mainMod, page_down, exec, hypr-workspace-monitor -wr"

        # Window Navigation
        "$mainMod, Tab, cyclenext"
        "$mainMod, Tab, bringactivetotop"
        "$mainMod, Tab, changegroupactive"

        # Window Splitting
        "$mainMod ALT, left, exec, hyprctl dispatch splitratio -0.2"
        "$mainMod ALT, right, exec, hyprctl dispatch splitratio +0.2"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };

    # =====================================================
    # Extra Configuration and Monitor Settings
    # =====================================================
    extraConfig = ''
      # Monitor definitions
      monitor=desc:Dell Inc. DELL UP2716D KRXTR88N909L,2560x1440@59,0x0,1
      monitor=desc:Chimei Innolux Corporation 0x143F,1920x1200@60,320x1440,1

      # Workspace assignments
      workspace = 1, monitor:DELL UP2716D KRXTR88N909L,1, default:true
      workspace = 2, monitor:DELL UP2716D KRXTR88N909L,2
      workspace = 3, monitor:DELL UP2716D KRXTR88N909L,3
      workspace = 4, monitor:DELL UP2716D KRXTR88N909L,4
      workspace = 5, monitor:DELL UP2716D KRXTR88N909L,5
      workspace = 6, monitor:DELL UP2716D KRXTR88N909L,6
      workspace = 7, monitor:Chimei Innolux Corporation 0x143F,7, default:true
      workspace = 8, monitor:Chimei Innolux Corporation 0x143F,8
      workspace = 9, monitor:Chimei Innolux Corporation 0x143F,9

      # XWayland settings
      xwayland {
        force_zero_scaling = true
      }
    '';
  };
}

