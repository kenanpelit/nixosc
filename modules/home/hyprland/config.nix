# Hyprland Window Manager Configuration - Dynamic Catppuccin Theme
# modules/home/hyprland/config.nix
# Complete optimized configuration with performance enhancements and dynamic theming
{ config, lib, pkgs, ... }:
let
  # Import Catppuccin color palette from module
  inherit (config.catppuccin) sources;
  
  # Dynamic color palette based on selected flavor (mocha, latte, frappe, macchiato)
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Color format converter for Hyprland (RGBA hex: 0xAARRGGBB)
  # Alpha: 0.0-1.0 float value, converted to hex format
  mkColor = color: alpha:
    let
      hex = lib.removePrefix "#" color;

      # clamp + integer
      alphaInt =
        let x = builtins.floor (alpha * 255);
        in if x < 0 then 0 else if x > 255 then 255 else x;

      toHex = n:
        let
          hexDigits = ["0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f"];
          hi = builtins.div n 16;
          lo = n - 16 * hi;
          high = builtins.elemAt hexDigits hi;
          low  = builtins.elemAt hexDigits lo;
        in high + low;

      alphaHex = toHex alphaInt;
    in "0x${alphaHex}${hex}";
 in
{
  wayland.windowManager.hyprland = {
    settings = {
      # =====================================================
      # STARTUP APPLICATIONS & SYSTEM SERVICES
      # =====================================================
      exec-once = [
        # Import Wayland environment variables to systemd user session
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"
        
        # Update DBus activation environment for proper Wayland session integration
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
        
        # NetworkManager system tray applet for network management
        "nm-applet --indicator"
        
        # Clipboard persistence - maintains clipboard content after program closure
        "wl-clip-persist --clipboard both"
        
        # Clipboard history manager with text and image support
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        
        # Advanced clipboard manager with searchable history
        "clipse -listen"
        
        # Set system cursor theme and size - Dynamic Catppuccin theme
        "hyprctl setcursor catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors 24"
        
        # Wallpaper daemon for dynamic wallpaper management
        "swww-daemon"
        
        # Custom wallpaper manager service
        "wallpaper-manager start"
        
        # Initialize workspace layout configuration
        "hypr-switch"
        
        # Initialize audio control system
        "osc-soundctl init"
        
        # Initialize screen locker for security
        "hyprlock"
      ];

      # =====================================================
      # ENVIRONMENT VARIABLES - DYNAMIC CATPPUCCIN THEME
      # =====================================================
      env = [
        # === Wayland Core Configuration ===
        "XDG_SESSION_TYPE,wayland"                     # Define session type as Wayland
        "XDG_SESSION_DESKTOP,Hyprland"                 # Identify desktop session name
        "XDG_CURRENT_DESKTOP,Hyprland"                 # Tell apps the current desktop
        "DESKTOP_SESSION,Hyprland"                     # Used by some legacy clients

        # === Wayland Backend Settings ===
        "GDK_BACKEND,wayland,x11"                      # GTK: prefer Wayland, fallback to X11
        "SDL_VIDEODRIVER,wayland"                      # SDL: use Wayland for games/apps
        "CLUTTER_BACKEND,wayland"                      # Clutter: Wayland backend
        "OZONE_PLATFORM,wayland"                       # Chromium/Brave: force Wayland backend

        # === Hyprland Specific Settings ===
        "HYPRLAND_LOG_WLR,1"                           # Enable wlroots logging
        "HYPRLAND_NO_RT,1"                             # Disable real-time scheduling (safer)
        "HYPRLAND_NO_SD_NOTIFY,1"                      # Prevent systemd notification loops

        # === Dynamic GTK Theme (auto-updates with Catppuccin flavor) ===
        "GTK_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal"  
                                                      # GTK theme dynamically follows flavor/accent
        "GTK_USE_PORTAL,1"                             # Use xdg-desktop-portal for file dialogs
        "GTK_APPLICATION_PREFER_DARK_THEME,${if (config.catppuccin.flavor == "latte") then "0" else "1"}"  
                                                      # Disable dark theme for Latte, enable otherwise
        "GDK_SCALE,1"                                  # Set UI scale factor to 1× (no scaling)

        # === Dynamic Cursor Theme (synchronized with Catppuccin flavor) ===
        "XCURSOR_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors"  
                                                      # Cursor theme matches flavor/accent
        "XCURSOR_SIZE,24"                              # Cursor size for GTK/Qt apps
        "HYPRCURSOR_THEME,catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors"  
                                                      # Cursor theme for Hyprland surfaces
        "HYPRCURSOR_SIZE,32"                           # Slightly larger cursor in compositor

        # === Qt/KDE Theme Configuration ===
        "QT_QPA_PLATFORM,wayland;xcb"                  # Prefer Wayland, fallback to XCB/X11
        "QT_QPA_PLATFORMTHEME,kvantum"                 # Use Kvantum for theming consistency
        "QT_STYLE_OVERRIDE,kvantum"                    # Force Kvantum style on Qt apps
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"                # Enable auto-scaling on HiDPI
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"        # Disable native Qt decorations on Wayland
        "QT_WAYLAND_FORCE_DPI,96"                      # Force 96 DPI (prevents oversized UI)

        # === Firefox / Gecko Wayland Optimizations ===
        "MOZ_ENABLE_WAYLAND,1"                         # Enable native Wayland backend
        "MOZ_WEBRENDER,1"                              # Use GPU-accelerated rendering
        "MOZ_USE_XINPUT2,1"                            # Enable advanced input handling
        "MOZ_CRASHREPORTER_DISABLE,1"                  # Disable crash reporter (privacy, less noise)

        # === Font Rendering Configuration ===
        "FREETYPE_PROPERTIES,truetype:interpreter-version=40"  
                                                      # Sharper and more consistent text rendering

        # === OpenGL / Vulkan Renderer Configuration ===
        "WLR_RENDERER,vulkan"                          # Prefer Vulkan renderer for Hyprland

        # === Intel iGPU Optimizations ===
        "LIBVA_DRIVER_NAME,iHD"                        # Use Intel HD (iHD) VAAPI driver
        #"INTEL_DEBUG,norbc"                           # Optional debug: disable Render Buffer Compression

        # === Default System Applications ===
        "EDITOR,nvim"                                  # Default terminal editor
        "VISUAL,nvim"                                  # Visual editor for GUIs
        "TERMINAL,kitty"                               # Preferred terminal emulator
        "TERM,xterm-256color"                          # Terminal type definition for TUI apps
        "BROWSER,brave"                                # Default web browser

        # === Debugging / Theming Info ===
        "CATPPUCCIN_FLAVOR,${config.catppuccin.flavor}"# Export current Catppuccin flavor name
      ];

      # =====================================================
      # INPUT CONFIGURATION
      # =====================================================
      input = {
        # --- Keyboard layout ---
        kb_layout = "tr";                # Turkish keyboard layout
        kb_variant = "f";                # Turkish F layout variant
        kb_options = "ctrl:nocaps";      # Remap Caps Lock → Control
        repeat_rate = 35;                # Key repeat rate (characters per second)
        repeat_delay = 250;              # Delay before key repeat starts (ms)
        numlock_by_default = false;      # NumLock state at startup

        # --- Mouse configuration ---
        sensitivity = 0.0;               # Cursor sensitivity multiplier
        accel_profile = "flat";          # Disable pointer acceleration curve
        force_no_accel = true;           # Force raw linear pointer movement
        follow_mouse = 1;                # Focus follows mouse movement
        float_switch_override_focus = 2; # Better focus handling on floating windows
        left_handed = false;             # Swap mouse buttons if true

        # --- Touchpad configuration ---
        touchpad = {
          natural_scroll = false;        # Invert scroll direction (macOS style)
          disable_while_typing = true;   # Avoid accidental cursor moves while typing
          tap-to-click = true;           # Enable tap-to-click
          drag_lock = true;              # Hold drag after finger release
          scroll_factor = 1.0;           # Scroll sensitivity multiplier
          clickfinger_behavior = true;   # 2-finger = right click, 3-finger = middle click
          middle_button_emulation = true;# Emulate middle button if missing
          tap-and-drag = true;           # Allow dragging via touch
        };
      };

      # =====================================================
      # GENERAL SETTINGS - DYNAMIC CATPPUCCIN COLORS
      # =====================================================
      general = {
        "$mainMod" = "SUPER";  # Define main modifier key (used in bindings)

        # --- Window spacing & borders ---
        gaps_in = 0;                    # Gap between tiled windows
        gaps_out = 0;                   # Gap between windows and monitor edge
        border_size = 2;                # Border thickness in pixels

        # --- Border colors (dynamic with Catppuccin palette) ---
        "col.active_border" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg"; 
          # Gradient border for focused windows (blue→mauve, 45°)
        "col.inactive_border" = mkColor colors.overlay0.hex 0.66; 
          # Transparent border for unfocused windows

        # --- Window behavior ---
        layout = "master";              # Default tiling layout
        allow_tearing = false;          # Prevent screen tearing (vsync-friendly)
        resize_on_border = true;        # Allow resizing by dragging window border
        extend_border_grab_area = 15;   # Extra clickable area around borders
        hover_icon_on_border = true;    # Show resize icon on hover
        no_border_on_floating = false;  # Keep border visible on floating windows
      };

      # =====================================================
      # GROUP SETTINGS - DYNAMIC CATPPUCCIN COLORS
      # =====================================================
      group = {
        # --- Border gradients for group containers ---
        "col.border_active" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        "col.border_inactive" = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";

        # --- Locked groups (cannot be modified) ---
        "col.border_locked_active" = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
        "col.border_locked_inactive" = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";

        # --- Groupbar: mini bar displaying group info ---
        groupbar = {
          render_titles = false;        # Disable window titles inside group bar
          gradients = false;            # Flat color look for group bar
          font_size = 10;               # Font size for groupbar text

          # --- Groupbar colors synced with Catppuccin palette ---
          "col.active" = mkColor colors.blue.hex 0.93;
          "col.inactive" = mkColor colors.overlay0.hex 0.66;
          "col.locked_active" = mkColor colors.mauve.hex 0.93;
          "col.locked_inactive" = mkColor colors.surface1.hex 0.66;
        };
      };

      # =====================================================
      # MISC SETTINGS - ADVANCED FEATURES & OPTIMIZATIONS
      # =====================================================
      misc = {
        # === Visual Appearance ===
        disable_hyprland_logo = true;        # Hide Hyprland splash logo
        disable_splash_rendering = true;     # Skip startup splash rendering
        force_default_wallpaper = 0;         # Use custom wallpaper instead of default
        background_color = mkColor colors.base.hex 1.0;  # Dynamic background color (Catppuccin base)

        # === Power Management ===
        mouse_move_enables_dpms = true;      # Wake screen on mouse movement
        key_press_enables_dpms = true;       # Wake screen on keypress
        vrr = 1;                             # Enable VRR (FreeSync / G-Sync)

        # === Performance Optimizations ===
        vfr = true;                          # Variable frame rate when idle
        disable_autoreload = false;          # Allow config auto-reload on change
        disable_hyprland_guiutils_check = true;  # Skip GUI utils check (using custom tools)

        # === Window Behavior ===
        focus_on_activate = true;            # Automatically focus new active window
        always_follow_on_dnd = true;         # Move with drag-and-drop
        layers_hog_keyboard_focus = true;    # Layer surfaces capture keyboard
        animate_manual_resizes = true;       # Animate when manually resizing
        animate_mouse_windowdragging = true; # Animate while dragging windows
        new_window_takes_over_fullscreen = 2;# Bring new window above fullscreen apps

        # === Terminal Swallowing ===
        enable_swallow = true;               # Hide terminal when launching GUI apps
        swallow_regex = "^(kitty|foot|alacritty|wezterm)$"; # Match these terminals
        swallow_exception_regex = "^(wev|Wayland-desktop|wl-clipboard)$"; # Exceptions not to swallow

        # === Monitor & Focus Management ===
        mouse_move_focuses_monitor = true;   # Switch monitor focus when cursor moves
        initial_workspace_tracking = 1;      # Start tracking workspaces from index 1

        # === Special Features ===
        close_special_on_empty = true;       # Auto-close special workspaces when empty
        allow_session_lock_restore = true;   # Restore session after lock
      };

      # =====================================================
      # GESTURES CONFIGURATION
      # =====================================================
      gestures = {
        # --- Touchpad swipe gestures ---
        # workspace_swipe = true;            # Enable gesture workspace switching
        # workspace_swipe_fingers = 3;       # Number of fingers for swipe
        # workspace_swipe_min_fingers = false;
        workspace_swipe_distance = 300;      # Swipe travel distance in pixels
        workspace_swipe_touch = false;       # Disable touchscreen gesture control
        workspace_swipe_touch_invert = false;# Normal direction for touchscreen
        workspace_swipe_invert = true;       # Invert touchpad direction
        workspace_swipe_min_speed_to_force = 20; # Min speed before gesture triggers
        workspace_swipe_cancel_ratio = 0.3;  # Cancel if finger returns >30% of swipe
        workspace_swipe_create_new = true;   # Create new workspace if swiped beyond last
        workspace_swipe_direction_lock = true;       # Lock axis (horizontal/vertical)
        workspace_swipe_direction_lock_threshold = 15; # Angle threshold before lock
        workspace_swipe_forever = true;      # Continuous “scroll through” workspaces
      };

      # =====================================================
      # LAYOUT CONFIGURATIONS
      # =====================================================

      # --- Dwindle Layout (Binary Tree) ---
      dwindle = {
        pseudotile = true;               # Allow floating inside tiled space
        preserve_split = true;           # Keep splits when closing windows
        special_scale_factor = 0.8;      # Shrink special workspaces to 80%
        force_split = 2;                 # Force split direction (1=horizontal, 2=vertical)
        split_width_multiplier = 1.0;    # Adjust default split ratio multiplier
        use_active_for_splits = true;    # Split relative to active window
        default_split_ratio = 1.0;       # Equal split by default
      };

      # --- Master Layout (Primary + Slave) ---
      master = {
        new_on_top = false;              # New windows stack below master
        new_status = "slave";            # Default new windows as slave
        mfact = 0.60;                    # Master area ratio (0.6 = 60%)
        orientation = "left";            # Master window on left side
        inherit_fullscreen = true;       # Keep fullscreen on workspace change
        smart_resizing = true;           # Proportional resizing logic
        drop_at_cursor = false;          # Disable cursor drop placement
        allow_small_split = false;       # Prevent tiny sub-windows
        special_scale_factor = 0.8;      # Scale special workspace
        new_on_active = "after";         # Spawn new windows next to active one
      };

      # =====================================================
      # KEYBINDING SETTINGS
      # =====================================================
      binds = {
        pass_mouse_when_bound = true;     # Allow mouse pass-through when keybound
        workspace_back_and_forth = true;  # Jump between two recent workspaces
        allow_workspace_cycles = true;    # Wrap-around workspace cycling
        workspace_center_on = 1;          # Center view on switched workspace
        focus_preferred_method = 0;       # Default focus method (0 = click-to-focus)
        ignore_group_lock = true;         # Allow keybinds inside locked groups
      };

      # =====================================================
      # VISUAL EFFECTS - DYNAMIC CATPPUCCIN THEME
      # =====================================================
      decoration = {
        rounding = 10;                    # Window corner radius (px)

        # --- Opacity settings ---
        active_opacity = 1.0;             # Focused window opacity
        inactive_opacity = 0.95;          # Unfocused window opacity
        fullscreen_opacity = 1.0;         # Fullscreen window opacity

        # --- Dimming effect ---
        dim_inactive = true;              # Enable dimming for inactive windows
        dim_strength = 0.15;              # 15% dim strength

        # --- Blur configuration ---
        blur = {
          enabled = true;                 # Enable window background blur
          size = 10;                      # Blur radius
          passes = 3;                     # Quality (more passes = smoother)
          ignore_opacity = true;          # Apply blur even on transparent layers
          new_optimizations = true;       # Use modern blur backend
          xray = true;                    # Enhance floating window clarity
          vibrancy = 0.1696;              # Subtle color bleeding intensity
          vibrancy_darkness = 0.0;        # No darkening on blur
          special = false;                # Skip blur on special workspaces
          popups = true;                  # Enable blur for popups
          popups_ignorealpha = 0.2;       # Ignore alpha under popups
        };

        # --- Shadow effect ---
        shadow = {
          enabled = true;                 # Enable shadows under windows
          ignore_window = true;           # Ignore shadow overlap logic
          offset = "0 4";                 # Shadow offset (x y)
          range = 25;                     # Shadow spread radius
          render_power = 2;               # Intensity falloff
          color = mkColor colors.crust.hex 0.26; # Shadow color (Catppuccin crust tone)
          scale = 0.97;                   # Slight downscale for soft edge
        };
      };

      # =====================================================
      # ANIMATIONS - SMOOTH CATPPUCCIN TRANSITIONS
      # =====================================================
      animations = {
        # ---------------------------------------------------
        # Master switch: enables or disables all animations.
        # true  → animations active
        # false → all animations instantly jump to target state
        # ---------------------------------------------------
        enabled = true;

        # ---------------------------------------------------
        # Custom Bezier curves
        # Each entry defines an easing function used by animations.
        # Format: "name, p0x, p0y, p1x, p1y"
        # - p0x/p0y/p1x/p1y are control points for a cubic-bezier curve.
        # ---------------------------------------------------
        bezier = [
          # Gentle deceleration similar to Fluent UI transitions.
          "fluent, 0.05, 0.20, 0.00, 1.00"

          # Classic “ease out” curve for fades (starts fast, ends slow).
          "easeOutCirc, 0.00, 0.55, 0.45, 1.00"

          # Slight overshoot for “elastic” effect (window open/close).
          "overshoot, 0.20, 0.80, 0.20, 1.20"

          # Balanced Catppuccin feel — slightly smoother at the end.
          "catppuccinSmooth, 0.25, 0.1, 0.25, 1"

          # Linear motion: constant velocity (used for borders).
          "linear, 0.00, 0.00, 1.00, 1.00"
        ];

        # ---------------------------------------------------
        # Animation definitions
        # Format: "object, enabled, speed, curve, style"
        # - object : what to animate (windows, fade, workspaces, etc.)
        # - enabled: 1 to enable, 0 to disable
        # - speed  : higher = slower animation
        # - curve  : bezier name defined above
        # - style  : animation style (slide, popin, fade, etc.)
        # ---------------------------------------------------
        animation = [
          # -----------------------------------------------
          # Window appearing and disappearing
          # slide   → moves window slightly from spawn point
          # overshoot → gives a tiny elastic bounce effect
          # -----------------------------------------------
          "windows, 1, 3, overshoot, slide"

          # -----------------------------------------------
          # Window close effect
          # popin 80% → shrink inward to 80% before disappearing
          # easeOutCirc → smooth deceleration toward end
          # -----------------------------------------------
          "windowsOut, 1, 2, easeOutCirc, popin 80%"

          # -----------------------------------------------
          # Fade in/out transitions (used for blur, menus, etc.)
          # Speed 4 gives moderate fade length.
          # -----------------------------------------------
          "fade, 1, 4, easeOutCirc"

          # -----------------------------------------------
          # Workspace transitions when swiping or switching
          # catppuccinSmooth → smooth cross-slide between spaces
          # -----------------------------------------------
          "workspaces, 1, 4, catppuccinSmooth, slide"

          # -----------------------------------------------
          # Border color transition (when window focus changes)
          # linear → instant color interpolation without easing.
          # -----------------------------------------------
          "border, 1, 1, linear"
        ];
      };

      # =====================================================
      # WINDOW RULES - APPLICATION-SPECIFIC CONFIGURATIONS
      # =====================================================
      windowrule = [
        # === Media Applications ===
        # MPV Video Player - Picture-in-Picture style
        "float,class:^(mpv)$"
        "size 19% 19%,class:^(mpv)$"
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

        # === Image Viewers ===
        "float,class:^(Viewnior)$"
        "center,class:^(Viewnior)$"
        "size 1200 800,class:^(Viewnior)$"
        "float,class:^(imv)$"
        "center,class:^(imv)$"
        "size 1200 725,class:^(imv)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"

        # === Audio Applications ===
        "float,class:^(audacious)$"
        "workspace 5,class:^(Audacious)$"

        # === Productivity Applications ===
        # Aseprite - Pixel art editor
        "tile,class:^(Aseprite)$"
        "workspace 4,class:^(Aseprite)$"
        "opacity 1.0 override 1.0 override,class:^(Aseprite)$"
        
        # GIMP
        "workspace 4,class:^(Gimp-2.10)$"
        
        # Neovide
        "tile,class:^(neovide)$"
        
        # Unity
        "opacity 1.0 override 1.0 override,class:^(Unity)$"

        # === Document Viewer ===
        "workspace 3,class:^(evince)$"
        "opacity 1.0 override 1.0 override,class:^(evince)$"

        # === OBS Studio ===
        "workspace 8,class:^(com.obsproject.Studio)$"

        # === System Utilities ===
        # VNC Viewer
        "float,class:^(Vncviewer)$"
        "center,class:^(Vncviewer)$"
        "workspace 6,class:^(Vncviewer)$,title:^(.*TigerVNC)$"
        "fullscreen,class:^(Vncviewer)$,title:^(.*TigerVNC)$"

        # === File Management ===
        "float,class:^(udiskie)$"
        "float,class:^(org.gnome.FileRoller)$"
        "center,class:^(org.gnome.FileRoller)$"
        "size 850 500,class:^(org.gnome.FileRoller)$"

        # === Terminal Applications ===
        # Yazi file manager
        "float,class:^(yazi)$"
        "center,class:^(yazi)$"
        "size 1920 1080,class:^(yazi)$"
        
        # Ranger file manager
        "float,class:^(ranger)$"
        "size 75% 60%,class:^(ranger)$"
        "center,class:^(ranger)$"

        # === System Monitor ===
        "float,class:^(htop)$"
        "size 80% 80%,class:^(htop)$"
        "center,class:^(htop)$"

        # === Scratchpad Terminals ===
        "float,class:^(scratchpad)$"
        "center,class:^(scratchpad)$"
        "float,class:^(kitty-scratch)$"
        "size 75% 60%,class:^(kitty-scratch)$"
        "center,class:^(kitty-scratch)$"

        # === Communication Apps ===
        # Discord
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
        "workspace 9 silent,title:^(web.whatsapp.com)$, class:^(Brave-browser)$"
        "workspace 9 silent,title:^(web.whatsapp.com)$"
        "workspace 9 silent,class:^(Ferdium)$,title:^(Ferdium)$"

        # === Video Conferencing ===
        "float,title:^(Meet).*$"
        "size 918 558,title:^(Meet).*$"
        "workspace 4,title:^(Meet).*$"
        "center,title:^(Meet).*$"

        # === Workspace Assignments ===
        # Browser workspaces
        "workspace 1,class:^(zen)$"
        "workspace 6 silent,class:^(Kenp)$,title:^(Zen Browser Private Browsing)$"
        "workspace 6 silent,title:^(New Private Tab - Brave)$"
        "workspace 6 silent,title:^Kenp Browser (Inkognito)$"
        "workspace 7 silent,title:^(brave-youtube.com__-Default)$"
        "workspace 8 silent,class:^(Brave-browser)$,title:^(Spotify - Web Player).*"

        # Development workspaces
        "workspace 2 silent,class:^(Tmux)$,title:^(Tmux)$"
        "workspace 2 silent,class:^(TmuxKenp)$"

        # AI and documents
        "workspace 3 silent,class:^(AI)$"

        # Work and projects
        "workspace 4 silent,class:^(CompecTA)$"
        "workspace 4 silent,title:^(compecta)$"

        # Security and system
        "workspace 7 silent,class:^(org.keepassxc.KeePassXC)$"
        "workspace 7 silent,class:^(com.transmissionbt.transmission.*)$"

        # Entertainment
        "workspace 8 silent,class:^(Spotify)$"
        "workspace 6 silent,class:^(qemu-system-x86_64)$"
        "workspace 6 silent,class:^(qemu)$"

        # === Launcher & System Tools ===
        "pin,class:^(rofi)$"
        "pin,class:^(waypaper)$"

        # === Notes & Clipboard ===
        # Notes application
        "float,class:^(notes)$"
        "size 70% 50%,class:^(notes)$"
        "center,class:^(notes)$"
        "float,class:^(anote)$"
        "center,class:^(anote)$"
        "size 1536 864,class:^(anote)$"
        "animation slide,class:^(anote)$"
        "opacity 0.95 0.95,class:^(anote)$"

        # Clipboard managers
        "float,class:^(clipb)$"
        "center,class:^(clipb)$"
        "size 1536 864,class:^(clipb)$"
        "animation slide,class:^(clipb)$"
        
        # CopyQ clipboard manager
        "float,class:^(com.github.hluk.copyq)$"
        "size 25% 80%,class:^(com.github.hluk.copyq)$"
        "move 74% 10%,class:^(com.github.hluk.copyq)$"
        "animation popout,class:^(com.github.hluk.copyq)$"
        "dimaround,class:^(com.github.hluk.copyq)$"
        
        # Clipse clipboard manager
        "float,class:^(clipse)$"
        "size 25% 80%,class:^(clipse)$"
        "move 74% 10%,class:^(clipse)$"
        "animation popout,class:^(clipse)$"
        "dimaround,class:^(clipse)$"

        # === Dropdown Terminal ===
        "float,class:^(dropdown)$"
        "size 99% 50%,class:^(dropdown)$"
        "move 0.5% 3%,class:^(dropdown)$"
        "workspace special:dropdown,class:^(dropdown)$"

        # === Shortwave Radio Player ===
        "float,class:^(de.haeckerfelix.Shortwave)$"
        "size 30% 80%,class:^(de.haeckerfelix.Shortwave)$"
        "move 65% 10%,class:^(de.haeckerfelix.Shortwave)$"
        "workspace 8,class:^(de.haeckerfelix.Shortwave)$"

        # === Authentication & Security ===
        # OTP Client
        "float,class:^(otpclient)$"
        "size 20%,class:^(otpclient)$"
        "move 79% 40%,class:^(otpclient)$"
        "opacity 1.0 1.0,class:^(otpclient)$"
        
        # Ente Auth
        "float,class:^(io.ente.auth)$"
        "size 400 900,class:^(io.ente.auth)$"
        "center,class:^(io.ente.auth)$"

        # === System Prompts ===
        "float,class:^(gcr-prompter)$"
        "center,class:^(gcr-prompter)$"
        "pin,class:^(gcr-prompter)$"
        "animation fade,class:^(gcr-prompter)$"
        "opacity 0.95 0.95,class:^(gcr-prompter)$"

        # === Audio Control ===
        # Volume control
        "float,title:^(Volume Control)$"
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
        
        # PulseAudio volume control
        "float,class:^(org.pulseaudio.pavucontrol)$"
        "size 60% 90%,class:^(org.pulseaudio.pavucontrol)$"
        "animation popin,class:^(org.pulseaudio.pavucontrol)$"
        "dimaround,class:^(org.pulseaudio.pavucontrol)$"

        # === Network Management ===
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

        # === Gaming & Emulation ===
        "float,class:^(.sameboy-wrapped)$"
        "float,class:^(SoundWireServer)$"

        # === Generic Dialog Rules ===
        "float,title:^(Open File)$"
        "float,title:^(File Upload)$"
        "size 850 500,title:^(File Upload)$"
        "float,title:^(Confirm to replace files)$"
        "float,title:^(File Operation Progress)$"
        "float,title:^(branchdialog)$"

        # === System Dialogs ===
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

        # === Browser Specific ===
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"
        "idleinhibit fullscreen,class:^(firefox)$"

        # === Transmission ===
        "float,title:^(Transmission)$"

        # === Picture-in-Picture ===
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
        "opacity 1.0 override 1.0 override,title:^(Picture-in-Picture)$"

        # === XWayland Video Bridge ===
        "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"

        # === Context Menu Optimization ===
        "opaque,class:^()$,title:^()$"
        "noshadow,class:^()$,title:^()$"
        "noblur,class:^()$,title:^()$"

        # === Terminal Opacity Overrides ===
        "opacity 1.0 override 1.0 override,class:^(kitty)$"
        "opacity 1.0 override 1.0 override,class:^(foot)$"
        "opacity 1.0 override 1.0 override,class:^(Alacritty)$"

        # === Browser Opacity Overrides ===
        "opacity 1.0 override 1.0 override,class:^(zen)$"

        # === Global Layout Rules ===
        "bordersize 2, floating:0"
        "rounding 10, floating:0"
      ];

      # =====================================================
      # WORKSPACE RULES - NO GAPS CONFIGURATION
      # =====================================================
      workspace = [
        "1, gapsout:0, gapsin:0"
        "2, gapsout:0, gapsin:0"
        "3, gapsout:0, gapsin:0"
        "4, gapsout:0, gapsin:0"
        "5, gapsout:0, gapsin:0"
        "6, gapsout:0, gapsin:0"
        "7, gapsout:0, gapsin:0"
        "8, gapsout:0, gapsin:0"
        "9, gapsout:0, gapsin:0"
      ];

      # =====================================================
      # KEY BINDINGS - COMPREHENSIVE KEYBOARD SHORTCUTS
      # =====================================================
      bind = [
        # === Application Launchers ===
        "$mainMod, F1, exec, rofi-launcher keys || pkill rofi"  # Show keybinds
        "ALT, Space, exec, rofi-launcher custom || pkill rofi"  # Custom launcher
        "$mainMod CTRL, Space, exec, rofi-launcher default || pkill rofi"  # Default launcher
        "$mainMod, backspace, exec, rofi-launcher power || pkill rofi"  # Power menu
        "$mainMod, Space, exec, walk"  # Walk launcher

        # === Terminal Emulators ===
        "$mainMod, Return, exec, kitty"  # Standard terminal
        "ALT, Return, exec, [float; center; size 950 650] kitty"  # Floating terminal
        "$mainMod SHIFT, Return, exec, [fullscreen] kitty"  # Fullscreen terminal

        # === Basic Window Management ===
        "$mainMod, Q, killactive"  # Close active window
        "ALT, F4, killactive"  # Alternative close
        #"$mainMod SHIFT, F, exec, hyprctl dispatch fullscreen 1 toggle"  # Maximize toggle
        #"$mainMod CTRL, F, exec, hyprctl dispatch fullscreen 0 toggle"   # True fullscreen toggle
        "$mainMod SHIFT, F, fullscreen, 1"  # Maximize fullscreen
        "$mainMod CTRL, F, fullscreen, 0"  # True fullscreen
        "$mainMod, F, exec, toggle_float"  # Toggle floating
        "$mainMod, P, pseudo,"  # Pseudo tile
        "$mainMod, X, togglesplit,"  # Toggle split
        "$mainMod, G, togglegroup"  # Toggle group
        "$mainMod, T, exec, toggle_opacity"  # Toggle opacity
        "$mainMod, S, pin"  # Pin window (always on top)

        # === File Managers ===
        "ALT, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] kitty yazi'"  # Yazi file manager
        "ALT CTRL, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] env GTK_THEME=catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal nemo'"  # Nemo file manager

        # === Media and Audio Control ===
        "ALT, A, exec, osc-soundctl switch"  # Switch audio output
        "ALT CTRL, A, exec, osc-soundctl switch-mic"  # Switch microphone
        "ALT, E, exec, osc-spotify"  # Spotify control
        "ALT CTRL, N, exec, osc-spotify next"  # Next track
        "ALT CTRL, B, exec, osc-spotify prev"  # Previous track
        "ALT CTRL, E, exec, mpc-control toggle"  # MPD toggle
        "ALT, i, exec, hypr-vlc_toggle"  # VLC toggle

        # === MPV Management ===
        "CTRL ALT, 1, exec, hypr-mpv-manager start"  # Start MPV
        "ALT, 1, exec, hypr-mpv-manager playback"  # MPV playback control
        "ALT, 2, exec, hypr-mpv-manager play-yt"  # Play YouTube
        "ALT, 3, exec, hypr-mpv-manager stick"  # Stick MPV window
        "ALT, 4, exec, hypr-mpv-manager move"  # Move MPV window
        "ALT, 5, exec, hypr-mpv-manager save-yt"  # Save YouTube video
        "ALT, 6, exec, hypr-mpv-manager wallpaper"  # Set as wallpaper

        # === Wallpaper Management ===
        "$mainMod, W, exec, wallpaper-manager select"  # Select wallpaper
        "ALT, 0, exec, wallpaper-manager now"  # Current wallpaper info
        "$mainMod SHIFT, W, exec, hyprctl dispatch exec '[float; center; size 925 615] waypaper'"  # Waypaper GUI

        # === System Tools ===
        "ALT, L, exec, hyprlock"  # Lock screen
        "$mainMod, C, exec, hyprpicker -a"  # Color picker
        "$mainMod, N, exec, makoctl restore"  # Restore notification
        "$mainMod CTRL, N, exec, makoctl dismiss --all"  # Dismiss all notifications
        "$mainMod CTRL, Escape, exec, hyprctl dispatch exec '[workspace 12] resources'"  # System monitor

        # === Monitor and Display Management ===
        "$mainMod, Escape, exec, pypr shift_monitors +1 || hyprctl dispatch focusmonitor -1"  # Cycle monitors
        "$mainMod, A, exec, hyprctl dispatch focusmonitor -1"  # Focus previous monitor
        "$mainMod, E, exec, pypr shift_monitors +1"  # Shift to next monitor
        "$mainMod SHIFT, B, exec, toggle_waybar"  # Toggle waybar

        # === Special Applications ===
        "$mainMod SHIFT, D, exec, webcord --enable-features=UseOzonePlatform --ozone-platform=wayland"  # Discord
        "$mainMod SHIFT, K, exec, hyprctl dispatch exec '[workspace 1 silent] start-brave-kenp'"  # Brave browser
        "$mainMod SHIFT, C, exec, hyprctl dispatch exec '[workspace 4 silent] start-brave-compecta'"  # Work browser
        "$mainMod SHIFT, S, exec, hyprctl dispatch exec '[workspace 8 silent] start-spotify'"  # Spotify
        "$mainMod SHIFT, X, exec, hyprctl dispatch exec '[workspace 11 silent] SoundWireServer'"  # SoundWire
        "ALT CTRL, W, exec, whatsie -w"  # WhatsApp
        "ALT, T, exec, start-kkenp"  # Custom launcher
        "ALT CTRL, C, exec, start-mkenp"  # Custom launcher
        "$mainMod ALT, RETURN, exec, semsumo launch --daily"  # Daily planner

        # === System Functions ===
        ",F10, exec, bluetooth_toggle"  # Bluetooth toggle
        "ALT, F12, exec, osc-mullvad toggle"  # VPN toggle
        "$mainMod, M, exec, anotes"  # Notes application
        "$mainMod CTRL, M, exec, anotes -t"  # Notes with terminal
        "$mainMod, B, exec, hypr-start-manager tcopyb"  # Clipboard manager

        # === Screenshot Shortcuts ===
        # Region capture
        ",Print, exec, screenshot ri"  # Region to clipboard
        "$mainMod SHIFT, Print, exec, screenshot rf"  # Region to file
        "CTRL, Print, exec, screenshot rc"  # Region copy
        "$mainMod CTRL, Print, exec, screenshot rec"  # Region record
        
        # Screen capture
        "$mainMod, Print, exec, screenshot si"  # Screen to clipboard
        "SHIFT, Print, exec, screenshot sf"  # Screen to file
        "CTRL SHIFT, Print, exec, screenshot sc"  # Screen copy
        "$mainMod SHIFT CTRL, Print, exec, screenshot sec"  # Screen record
        
        # Window capture
        "ALT, Print, exec, screenshot wi"  # Window to clipboard
        "ALT SHIFT, Print, exec, screenshot wf"  # Window to file
        "ALT CTRL, Print, exec, screenshot wc"  # Window copy
        
        # Special captures
        "$mainMod ALT, Print, exec, screenshot p"  # Pick window
        "$mainMod ALT CTRL, Print, exec, screenshot o"  # OCR

        # === Workspace Window Movement ===
        # Move windows from specific workspaces to current workspace
        "$mainMod CTRL, 1, exec, hypr-workspace-monitor -am 1"
        "$mainMod CTRL, 2, exec, hypr-workspace-monitor -am 2"
        "$mainMod CTRL, 3, exec, hypr-workspace-monitor -am 3"
        "$mainMod CTRL, 4, exec, hypr-workspace-monitor -am 4"
        "$mainMod CTRL, 5, exec, hypr-workspace-monitor -am 5"
        "$mainMod CTRL, 6, exec, hypr-workspace-monitor -am 6"
        "$mainMod CTRL, 7, exec, hypr-workspace-monitor -am 7"
        "$mainMod CTRL, 8, exec, hypr-workspace-monitor -am 8"
        "$mainMod CTRL, 9, exec, hypr-workspace-monitor -am 9"

        # === Focus Movement (Arrow Keys) ===
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # === Focus Movement (Vim Keys) ===
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"

        # === Workspace Switching ===
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"

        # === Ergonomic Workspace Cycling ===
        "$mainMod, bracketleft, workspace, e-1"   # Previous workspace
        "$mainMod, bracketright, workspace, e+1"  # Next workspace

        # === Move to Workspace (Silent) ===
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod CTRL, c, movetoworkspace, empty"  # Move to empty workspace

        # === Window Movement (Arrow Keys) ===
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"

        # === Window Movement (Vim Keys) ===
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        # === Window Resizing (Arrow Keys) ===
        "$mainMod CTRL, left, resizeactive, -80 0"
        "$mainMod CTRL, right, resizeactive, 80 0"
        "$mainMod CTRL, up, resizeactive, 0 -80"
        "$mainMod CTRL, down, resizeactive, 0 80"

        # === Window Resizing (Vim Keys) ===
        "$mainMod CTRL, h, resizeactive, -80 0"
        "$mainMod CTRL, j, resizeactive, 0 80"
        "$mainMod CTRL, k, resizeactive, 0 -80"
        "$mainMod CTRL, l, resizeactive, 80 0"

        # === Window Positioning (Arrow Keys) ===
        "$mainMod ALT, left, moveactive,  -80 0"
        "$mainMod ALT, right, moveactive, 80 0"
        "$mainMod ALT, up, moveactive, 0 -80"
        "$mainMod ALT, down, moveactive, 0 80"

        # === Window Positioning (Vim Keys) ===
        "$mainMod ALT, h, moveactive,  -80 0"
        "$mainMod ALT, j, moveactive, 0 80"
        "$mainMod ALT, k, moveactive, 0 -80"
        "$mainMod ALT, l, moveactive, 80 0"

        # === Media Keys ===
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop,exec, playerctl stop"
        ",XF86AudioMicMute, exec, toggle-mic"

        # === Mouse Wheel Workspace Switching ===
        "$mainMod, mouse_down, workspace, e-1"
        "$mainMod, mouse_up, workspace, e+1"

        # === Clipboard Manager ===
        "$mainMod, V, exec, kitty --class clipse -e clipse"  # Clipse clipboard
        "$mainMod CTRL, V, exec, clipmaster all"  # Clipmaster
         
        # === Layout Management ===
        "$mainMod CTRL, J, exec, hypr-layout_toggle"  # Toggle layout
        "$mainMod CTRL, RETURN, layoutmsg, swapwithmaster"  # Swap with master
        "$mainMod, R, submap, resize"  # Enter resize mode

        # === Workspace Navigation ===
        "ALT, N, workspace, previous"  # Previous workspace
        "ALT, Tab, workspace, e+1"  # Next workspace
        "ALT CTRL, tab, workspace, e-1"  # Previous workspace

        # === Cyclical Workspace Navigation ===
        "$mainMod, page_up, exec, hypr-workspace-monitor -wl"  # Workspace left
        "$mainMod, page_down, exec, hypr-workspace-monitor -wr"  # Workspace right

        # === Window Navigation ===
        "$mainMod, Tab, cyclenext"  # Cycle next window
        "$mainMod, Tab, bringactivetotop"  # Bring to top
        "$mainMod, Tab, changegroupactive"  # Change active group

        # === Special Workspace (Scratchpad) ===
        "$mainMod, minus, movetoworkspace, special:scratchpad"  # Send to scratchpad
        "$mainMod SHIFT, minus, togglespecialworkspace, scratchpad"  # Toggle scratchpad

        # === Window Splitting (Dwindle Layout) ===
        "$mainMod ALT, left, exec, hyprctl dispatch splitratio -0.2"
        "$mainMod ALT, right, exec, hyprctl dispatch splitratio +0.2"
      ];

      # === Resize Submap - Precise Window Resizing ===
      # Press $mainMod+R to enter resize mode, ESC or RETURN to exit
      # This is defined in extraConfig below

      # =====================================================
      # MOUSE BINDINGS
      # =====================================================
      bindm = [
        "$mainMod, mouse:272, movewindow"  # Move window with left click
        "$mainMod, mouse:273, resizewindow"  # Resize window with right click
      ];
    };

    # =====================================================
    # EXTRA CONFIGURATION - MONITORS & SUBMAPS
    # =====================================================
    extraConfig = ''
      # === Monitor Configuration ===
      # Primary monitor - Dell 2560x1440
      monitor=desc:Dell Inc. DELL UP2716D KRXTR88N909L,2560x1440@59,0x0,1
      # Secondary monitor - Chimei Innolux 1920x1200
      monitor=desc:Chimei Innolux Corporation 0x143F,1920x1200@60,320x1440,1
      # Fallback for unknown monitors
      monitor=,preferred,auto,1

      # === Workspace to Monitor Assignments ===
      # Primary monitor (Dell) - Workspaces 1-6
      workspace = 1, monitor:DELL UP2716D KRXTR88N909L, default:true
      workspace = 2, monitor:DELL UP2716D KRXTR88N909L
      workspace = 3, monitor:DELL UP2716D KRXTR88N909L
      workspace = 4, monitor:DELL UP2716D KRXTR88N909L
      workspace = 5, monitor:DELL UP2716D KRXTR88N909L
      workspace = 6, monitor:DELL UP2716D KRXTR88N909L
      
      # Secondary monitor (Chimei) - Workspaces 7-9
      workspace = 7, monitor:Chimei Innolux Corporation 0x143F, default:true
      workspace = 8, monitor:Chimei Innolux Corporation 0x143F
      workspace = 9, monitor:Chimei Innolux Corporation 0x143F

      # === XWayland Configuration ===
      xwayland {
        force_zero_scaling = true
      }

      # === Resize Submap - Precise Window Resizing ===
      # Enter with $mainMod+R, exit with ESC or RETURN
      submap = resize
      
      # Precise resize with Vim keys (10px increments)
      binde = , h, resizeactive, -10 0
      binde = , l, resizeactive, 10 0
      binde = , k, resizeactive, 0 -10
      binde = , j, resizeactive, 0 10
      
      # Precise resize with arrow keys (10px increments)
      binde = , left, resizeactive, -10 0
      binde = , right, resizeactive, 10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      
      # Exit resize mode
      bind = , escape, submap, reset
      bind = , return, submap, reset
      
      submap = reset
    '';
  };
}

