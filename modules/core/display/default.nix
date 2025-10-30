# modules/core/display/default.nix
# ==============================================================================
# Display & Desktop Environment Configuration - Production Grade
# ==============================================================================
#
# Module:      modules/core/display
# Purpose:     Unified display stack with multi-desktop support and portal routing
# Author:      Kenan Pelit
# Created:     2025-10-10
# Modified:    2025-10-18
# Version:     2.1
#
# Architecture:
#   Display Manager (GDM) → Desktop Session → Portal Layer → Audio Stack
#        ↓                      ↓                  ↓              ↓
#   Auto-login         Hyprland/GNOME/COSMIC   XDG Portals   PipeWire
#        ↓                      ↓                  ↓              ↓
#   systemd-logind    Wayland Compositor    Session-aware   ALSA/Pulse
#        ↓                      ↓                  ↓              ↓
#   User Session       Window Management    File/Screenshot  Applications
#
# Display Stack Layers:
#   1. Hardware Layer      - GPU drivers, kernel modules (DRM/KMS)
#   2. Display Server      - Wayland compositors (Hyprland/Mutter/COSMIC)
#   3. Session Manager     - GDM login, systemd user session
#   4. Portal Layer        - XDG Desktop Portals (file picker, screenshot, etc.)
#   5. Audio Stack         - PipeWire (unified audio/video routing)
#   6. Font Rendering      - Fontconfig with subpixel rendering
#   7. Input Management    - Libinput (touchpad/mouse/keyboard)
#
# Key Features:
#   ✓ Multi-desktop support (Hyprland/GNOME/COSMIC)
#   ✓ Session-aware XDG portal routing (no conflicts)
#   ✓ Intel Arc A380 optimized Hyprland session
#   ✓ Systemd user session integration (no chroot issues)
#   ✓ Comprehensive font stack (Nerd Fonts/emoji/CJK)
#   ✓ Wayland-first with XWayland fallback
#   ✓ PipeWire audio with ALSA/PulseAudio compatibility
#   ✓ Turkish F-keyboard layout support
#
# Design Principles:
#   • Session Isolation - Each desktop has proper portal routing
#   • Wayland First - Native Wayland with X11 compatibility
#   • User-Centric - Auto-login, optimized sessions, no manual setup
#   • Performance - Hardware acceleration, proper systemd integration
#   • Compatibility - Multiple desktops coexist without conflicts
#
# Module Boundaries:
#   ✓ Display server configuration   (THIS MODULE)
#   ✓ Desktop environment setup       (THIS MODULE)
#   ✓ XDG portal routing              (THIS MODULE)
#   ✓ Font configuration              (THIS MODULE)
#   ✓ Audio stack (PipeWire)          (THIS MODULE)
#   ✗ Window manager config           (home-manager)
#   ✗ Application theming             (home-manager)
#   ✗ User-specific keybinds          (home-manager)
#   ✗ GPU drivers                     (hardware module)
#
# ==============================================================================

{ username, inputs, pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkForce;
  
  # ----------------------------------------------------------------------------
  # Hyprland Packages (Locked Flake Version)
  # ----------------------------------------------------------------------------
  # Use pinned Hyprland from flake input for version consistency
  # Ensures portal and compositor versions match exactly
  
  hyprlandPkg = inputs.hyprland.packages.${pkgs.system}.default;
  hyprPortal  = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;

  # ----------------------------------------------------------------------------
  # Hyprland Optimized Session (Intel Arc A380 Hardware Acceleration)
  # ----------------------------------------------------------------------------
  # Custom GDM session that launches Hyprland with optimizations
  # 
  # Why a custom session?
  # - Direct launch via hyprland_tty (systemd integration handled internally)
  # - Intel Arc A380 specific optimizations (env vars, GPU params)
  # - Catppuccin theming preloaded
  # - Avoids "Running in chroot" systemd issues
  #
  # Session Flow:
  #   GDM → hyprland-optimized.desktop → /etc/profiles/per-user/kenan/bin/hyprland_tty
  #        ↓
  #   hyprland_tty script:
  #     1. Sets SYSTEMD_OFFLINE=0
  #     2. Imports systemd environment
  #     3. Starts Hyprland with proper D-Bus session
  #     4. User services (waybar, mako, etc.) start automatically
  
  hyprlandOptimizedSession = pkgs.writeTextFile {
    name = "hyprland-optimized-session";
    destination = "/share/wayland-sessions/hyprland-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland (Optimized)
      Comment=Hyprland with Intel Arc A380 optimizations and Catppuccin theming
      
      # Session type (Wayland native)
      Type=Application
      DesktopNames=Hyprland
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
      
      # Launch command (hyprland_tty handles systemd initialization)
      # This script is provided by home-manager in user PATH
      Exec=/etc/profiles/per-user/${username}/bin/hyprland_tty
      
      # Search keywords
      Keywords=wayland;wm;tiling;catppuccin;intel-arc;compositor;
    '';
    
    # Register this session with GDM
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

in
{
  # ============================================================================
  # Hyprland Compositor Configuration (Layer 1: Window Manager)
  # ============================================================================
  # Wayland compositor with dynamic tiling and advanced features
  # Features: Dynamic tiling, animations, blur, multi-monitor, IPC
  
  programs.hyprland = {
    enable = true;
    
    # ---- Package Versions ----
    # Use flake-locked versions to ensure compatibility
    # Portal and compositor MUST match versions
    package = hyprlandPkg;
    portalPackage = hyprPortal;
    
    # ---- XWayland Support ----
    # Enabled by default for X11 app compatibility
    # Examples: Steam, some Electron apps, legacy GUI tools
    # xwayland.enable = true;  # Default: true
  };

  # ============================================================================
  # System Services (Layer 2: Display Infrastructure)
  # ============================================================================
  services = {
    # ==========================================================================
    # X11 Server (XWayland + Keyboard Config)
    # ==========================================================================
    # Even on Wayland, X server config is needed for:
    # - XWayland (X11 app compatibility layer)
    # - Keyboard layout propagation to Wayland compositors
    # - Some legacy tools that query X server for input config
    
    xserver = {
      enable = true;
      
      # ---- Keyboard Layout ----
      # Turkish F-keyboard with Caps Lock → Control remapping
      # Propagated to: Wayland compositors, XWayland, console
      xkb = {
        layout  = "tr";            # Turkish keyboard
        variant = "f";             # F-layout (different from Q-layout)
        options = "ctrl:nocaps";   # Caps Lock becomes Control key
      };
      
      # Additional useful xkb options (commented):
      # options = "ctrl:nocaps,compose:ralt";  # Right Alt as Compose key
      # options = "ctrl:swapcaps";             # Swap Caps Lock and Control
      # options = "grp:alt_shift_toggle";      # Alt+Shift to switch layouts
    };

    # ==========================================================================
    # Display Manager (Layer 3: Login Screen)
    # ==========================================================================
    # GDM (GNOME Display Manager) - Modern Wayland-native login screen
    # Why GDM over SDDM/LightDM:
    # - Native Wayland support (no X11 dependency)
    # - Better session management
    # - Integrated with systemd-logind
    # - GNOME Keyring integration
    
    displayManager = {
      # ---- Session Registration ----
      # Register custom Hyprland session
      sessionPackages = [ hyprlandOptimizedSession ];
      
      # ---- GDM Configuration ----
      gdm = {
        enable = true;
        
        # Use Wayland for GDM itself (not just sessions)
        # Benefits: Better HiDPI, native Wayland, no X11 dependency
        wayland = true;
        
        # ---- Power Management ----
        # Disable auto-suspend during login screen
        # Useful for: Always-on systems, remote access, debugging
        autoSuspend = false;
      };
      
      # ---- Default Session ----
      # Session launched on auto-login or when user doesn't choose
      # Options: "hyprland-optimized", "gnome", "cosmic"
      defaultSession = "hyprland-optimized";
      
      # ---- Auto-login Configuration ----
      # Automatically log in specified user (no password prompt)
      # Security consideration: Only use on single-user systems
      autoLogin = {
        enable = true;
        user = "kenan";  # Should match your username variable
      };
      
      # ---- Disable SDDM ----
      # Prevent conflicts with multiple display managers
      # Note: NixOS only allows one display manager active at a time
      sddm.enable = false;
    };

    # ==========================================================================
    # Desktop Environments (Layer 4: Desktop Shells)
    # ==========================================================================
    # Multiple desktops can coexist - user selects at login
    # Each desktop provides: Window management, panels, settings, apps
    
    desktopManager = {
      # ---- GNOME Desktop ----
      # Traditional desktop environment (GTK-based)
      # Components: Mutter (compositor), GNOME Shell, System Settings
      # Use case: Familiar desktop, extensive app ecosystem, accessibility
      gnome.enable = true;
      
      # ---- COSMIC Desktop ----
      # Next-gen desktop by System76 (Rust-based, Iced toolkit)
      # Status: Beta (experimental features, active development)
      # Components: COSMIC Comp (compositor), COSMIC Panel, Settings
      # Use case: Modern design, performance, Rust ecosystem
      cosmic.enable = true;
      
      # Note: Hyprland is configured separately via programs.hyprland
      # It's a compositor, not a full desktop environment
    };

    # ==========================================================================
    # Input Devices (Layer 5: Human Interface)
    # ==========================================================================
    # Libinput provides unified input device handling
    # Supports: Touchpads, mice, keyboards, touchscreens, drawing tablets
    
    libinput = {
      enable = true;
      
      # ---- Touchpad Configuration ----
      # Default settings work well for most hardware
      # Customize in home-manager for per-user preferences
      
      # touchpad = {
      #   naturalScrolling = true;      # Two-finger scroll direction
      #   tapping = true;                # Tap-to-click
      #   disableWhileTyping = true;     # Prevent palm touches
      #   accelProfile = "adaptive";     # Mouse acceleration curve
      # };
    };

    # ==========================================================================
    # Session Security (Layer 6: Credential Storage)
    # ==========================================================================
    # GNOME Keyring: Password and credential management
    # 
    # DISABLED: Using GPG agent for unified key/password management
    # GPG agent provides:
    #   - SSH key management (programs.ssh.startAgent = false in security module)
    #   - GPG key management
    #   - Password caching
    #   - Works in both GUI and terminal
    #   - Not desktop-specific (portable across sessions)
    # 
    # To re-enable GNOME Keyring:
    #   1. Set: gnome.gnome-keyring.enable = true;
    #   2. Remove mkForce from security module:
    #      security.pam.services.login.enableGnomeKeyring
    
    gnome.gnome-keyring.enable = mkForce false;  # Using GPG agent (see security module)
    
    # Note: PAM integration is handled in security module
    # If you switch back to GNOME Keyring, update both locations
    
    # ==========================================================================
    # Audio Stack (Layer 7: PipeWire)
    # ==========================================================================
    # PipeWire: Modern audio/video routing daemon
    # Replaces: PulseAudio, JACK, and handles video routing
    # Benefits: Lower latency, better Bluetooth, unified API
    
    pipewire = {
      enable = true;
      
      # ---- ALSA Support ----
      # ALSA: Low-level Linux audio API
      # Enable for: Direct hardware access, professional audio, games
      alsa.enable = true;
      
      # ---- 32-bit ALSA Support ----
      # Required for: Steam games, Wine, 32-bit applications
      # Critical: Must match hardware.graphics.enable32Bit = true
      alsa.support32Bit = true;
      
      # ---- PulseAudio Compatibility ----
      # Provides PulseAudio API for legacy applications
      # Most apps use this: Firefox, Spotify, Discord, etc.
      pulse.enable = true;
      
      # ---- JACK Support ----
      # JACK: Professional audio with ultra-low latency
      # Use cases: Music production, live audio, DJ software
      # Note: Disabled by default (enable if needed for pro audio)
      jack.enable = false;
      
      # PipeWire replaces JACK but provides compatibility layer
      # Enable JACK if you need: Ardour, Bitwig, Carla, etc.
    };

    # ==========================================================================
    # D-Bus Service Registration (Layer 8: IPC)
    # ==========================================================================
    # D-Bus: Inter-process communication for desktop services
    # Registers: XDG portals, display servers, notification daemons
    
    dbus = {
      enable = true;
      
      # ---- Portal Packages ----
      # Register all portal implementations with D-Bus
      # Portal routing configured separately in xdg.portal.config
      packages = with pkgs; [
        xdg-desktop-portal          # Base portal framework
        xdg-desktop-portal-gtk      # GTK file picker, print dialog
        xdg-desktop-portal-gnome    # GNOME-specific portals
        xdg-desktop-portal-cosmic   # COSMIC-specific portals
        # xdg-desktop-portal-hyprland registered via programs.hyprland.portalPackage
      ];
    };
  };

  # ============================================================================
  # XDG Desktop Portals (Layer 9: Desktop Integration)
  # ============================================================================
  # Portals provide sandboxed applications access to desktop features
  # Features: File picker, screenshot, screen sharing, notifications, etc.
  #
  # Why portals matter:
  # - Flatpak apps require portals (sandboxing)
  # - Wayland apps need portals for some features (no X11 protocol)
  # - Consistent UX across different desktop environments
  #
  # Portal Architecture:
  #   Application → xdg-desktop-portal (router) → backend portal → Desktop
  #   (Flatpak)         (D-Bus service)        (GNOME/KDE/etc.)    (File manager)
  
  xdg.portal = {
    enable = true;
    
    # ---- XDG-Open Integration ----
    # Route xdg-open (file associations) through portal
    # Benefits: Respects desktop environment, better sandboxing
    xdgOpenUsePortal = true;
    
    # ==========================================================================
    # Portal Configuration (Session-Aware Routing)
    # ==========================================================================
    # Each desktop session gets appropriate portal backend
    # Prevents conflicts between GNOME/KDE/Hyprland portals
    #
    # Configuration format:
    #   <desktop-name>.default = [ "preferred-portal" "fallback-portal" ];
    #   <desktop-name>."org.freedesktop.impl.portal.Interface" = [ "portal" ];
    
    config = {
      # ========================================================================
      # Common Fallback (All Sessions)
      # ========================================================================
      # Used when session-specific config doesn't exist
      # GTK portal: Works everywhere, basic functionality
      common.default = [ "gtk" ];

      # ========================================================================
      # Hyprland Session
      # ========================================================================
      # Hyprland portal: Screenshot, screen sharing (wlroots-based)
      # GTK portal: File picker, print dialog (Hyprland portal doesn't provide)
      #
      # Interface routing:
      #   Screenshot   → hyprland (native screenshotter)
      #   ScreenCast   → hyprland (screen sharing via wlr-screencopy)
      #   FileChooser  → gtk (uses GTK file picker)
      #   Notification → gtk (desktop notifications)
      hyprland.default = [ "hyprland" "gtk" ];

      # ========================================================================
      # COSMIC Session
      # ========================================================================
      # COSMIC portal: Full portal implementation (Rust-based)
      # Explicit interface routing ensures COSMIC handles everything
      #
      # Why explicit routing?
      # - COSMIC is new, ensure it gets priority over older portals
      # - Prevents fallback to GNOME/GTK when COSMIC can handle it
      cosmic = {
        # Default fallback chain
        default = [ "cosmic" "gtk" ];
        
        # Explicit interface assignments (higher priority)
        "org.freedesktop.impl.portal.Screenshot"  = [ "cosmic" ];
        "org.freedesktop.impl.portal.ScreenCast"  = [ "cosmic" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "cosmic" ];
        "org.freedesktop.impl.portal.Notification" = [ "cosmic" ];
        "org.freedesktop.impl.portal.Print"       = [ "cosmic" ];
        
        # Additional interfaces (add as COSMIC implements them):
        # "org.freedesktop.impl.portal.Clipboard"    = [ "cosmic" ];
        # "org.freedesktop.impl.portal.RemoteDesktop" = [ "cosmic" ];
      };

      # ========================================================================
      # GNOME Session
      # ========================================================================
      # GNOME portal: Full desktop integration (Mutter-based)
      # GTK fallback: For interfaces GNOME doesn't implement
      #
      # GNOME portal handles:
      #   Screenshot, ScreenCast, FileChooser, Print, Notification,
      #   RemoteDesktop, Lockdown, Settings, Wallpaper, etc.
      gnome.default = [ "gnome" "gtk" ];
    };

    # ==========================================================================
    # Additional Portal Backends
    # ==========================================================================
    # Register extra portals not enabled by desktop environments
    # Note: Hyprland portal registered via programs.hyprland.portalPackage
    
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk     # GTK file picker, always useful
      pkgs.xdg-desktop-portal-gnome   # GNOME portal (when using GNOME)
      pkgs.xdg-desktop-portal-cosmic  # COSMIC portal (experimental)
    ];
    
    # Debugging portals:
    # busctl --user call org.freedesktop.portal.Desktop \
    #   /org/freedesktop/portal/desktop \
    #   org.freedesktop.portal.Screenshot Screenshot "ssa{sv}" "" "" {}
  };

  # ============================================================================
  # Systemd User Services (Layer 10: Session Management)
  # ============================================================================
  # User services run in systemd user session (not system-wide)
  # Examples: Waybar, Mako, Hyprland IPC, portals
  
  # ==========================================================================
  # Hyprland Session Target
  # ==========================================================================
  # Systemd target that represents an active Hyprland session
  # User services can depend on this target to start with Hyprland
  #
  # Usage in home-manager:
  #   systemd.user.services.waybar = {
  #     partOf = [ "hyprland-session.target" ];
  #     after = [ "hyprland-session.target" ];
  #   };
  
  systemd.user.targets.hyprland-session = {
    description = "Hyprland compositor session";
    
    # ---- Target Dependencies ----
    # bindsTo: Stop this target when graphical-session stops
    # wants: Start graphical-session-pre before this target
    # after: Wait for graphical-session-pre to complete
    bindsTo = [ "graphical-session.target" ];
    wants   = [ "graphical-session-pre.target" ];
    after   = [ "graphical-session-pre.target" ];
  };

  # ==========================================================================
  # COSMIC Portal Service (Conditional)
  # ==========================================================================
  # Only enabled when COSMIC desktop is active
  # Registers COSMIC portal with D-Bus for desktop integration
  
  systemd.user.services.xdg-desktop-portal-cosmic = mkIf config.services.desktopManager.cosmic.enable {
    description = "Portal service (COSMIC implementation)";
    
    # ---- Service Ordering ----
    # Start after graphical session is ready
    # Stop when graphical session stops
    # Start when xdg-desktop-portal.service starts
    after    = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];
    wantedBy = [ "xdg-desktop-portal.service" ];

    # ---- Service Configuration ----
    serviceConfig = {
      # D-Bus activated service (starts on portal request)
      Type    = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.cosmic";
      
      # Portal binary location
      ExecStart = "${pkgs.xdg-desktop-portal-cosmic}/libexec/xdg-desktop-portal-cosmic";
      
      # ---- Reliability ----
      # Restart on failure (portal crashes shouldn't break desktop)
      Restart    = "on-failure";
      RestartSec = "2s";
      
      # ---- Resource Management ----
      Slice = "session.slice";  # Group with other session services
      
      # ---- Timeouts ----
      TimeoutStartSec = "10s";  # Max startup time
      TimeoutStopSec  = "5s";   # Max shutdown time
    };

    # ---- Environment Variables ----
    # Tell portal which desktop environment it's serving
    environment = {
      XDG_CURRENT_DESKTOP = "COSMIC";
    };
  };

  # ============================================================================
  # Font Configuration (Layer 11: Text Rendering)
  # ============================================================================
  # Comprehensive font stack for all use cases
  # Categories: Terminal, UI, Emoji, Icons, CJK, Extended Unicode
  
  fonts = {
    # ==========================================================================
    # Font Packages
    # ==========================================================================
    # Install fonts system-wide (available to all users)
    
    packages = with pkgs; [
      # ========================================================================
      # Terminal & Coding Fonts (Monospace)
      # ========================================================================
      # Nerd Fonts: Includes programming ligatures + icon glyphs
      
      maple-mono.NF      # Maple Mono with Nerd Font patches (clean, modern)
      nerd-fonts.hack    # Hack Nerd Font (excellent readability)
      cascadia-code      # Microsoft's coding font (ligatures, Powerline)
      fira-code          # Popular font with extensive ligatures
      fira-code-symbols  # Icon set for Fira Code
      jetbrains-mono     # JetBrains IDE font (clear, ligatures)
      source-code-pro    # Adobe's monospace (highly readable)
      
      # Use cases:
      # - Terminal: Maple Mono NF, Hack Nerd Font
      # - IDE/Editor: JetBrains Mono, Fira Code
      # - Status bar: Any Nerd Font (includes icon glyphs)

      # ========================================================================
      # Emoji & Icon Fonts
      # ========================================================================
      # Essential for modern UI/UX (color emoji rendering)
      
      noto-fonts-color-emoji  # Google's color emoji (comprehensive)
      font-awesome            # Icon font (web icons, UI symbols)
      material-design-icons   # Google Material Design icons
      
      # Emoji rendering:
      # - Linux default: Black & white emoji (needs color font)
      # - Noto Color Emoji: Full color, updated regularly
      # - Twitter Emoji: Alternative (more expressive)

      # ========================================================================
      # System Fonts (UI & Document)
      # ========================================================================
      # Standard fonts for desktop applications
      
      liberation_ttf     # Libre alternative to Arial/Times/Courier
      dejavu_fonts       # Extended Unicode coverage, metric-compatible
      
      # Liberation fonts replace:
      # - Liberation Sans → Arial
      # - Liberation Serif → Times New Roman
      # - Liberation Mono → Courier New

      # ========================================================================
      # CJK (Chinese/Japanese/Korean) Support
      # ========================================================================
      # Essential for Asian language rendering
      
      noto-fonts-cjk-sans   # Sans-serif CJK (UI text)
      noto-fonts-cjk-serif  # Serif CJK (documents)
      
      # CJK fonts are large (~100-200MB each)
      # Only include if you need Asian language support

      # ========================================================================
      # Extended Unicode Coverage
      # ========================================================================
      # Fallback fonts for rare glyphs (math symbols, ancient scripts, etc.)
      
      noto-fonts         # Base Noto (Latin, Greek, Cyrillic)
      
      # Noto (No Tofu): Aims to cover all Unicode glyphs
      # "Tofu" = □ boxes shown for missing glyphs

      # ========================================================================
      # Modern UI Fonts
      # ========================================================================
      # Contemporary fonts for desktop applications and web
      
      inter               # Modern UI font (excellent legibility)
      roboto              # Google's Android/Material Design font
      ubuntu-classic      # Ubuntu system font (friendly, clean)
      open-sans           # Humanist sans-serif (web-optimized)
      
      # Use cases:
      # - Desktop UI: Inter, Roboto
      # - Document body: Open Sans, Ubuntu
      # - Headers: Inter, Roboto (bold weights)
    ];

    # ==========================================================================
    # Fontconfig Settings (Font Rendering Engine)
    # ==========================================================================
    # Controls font selection, aliasing, hinting, subpixel rendering
    
    fontconfig = {
      # ========================================================================
      # Default Font Families
      # ========================================================================
      # Fallback chain: First font tried, then next if glyph missing
      
      defaultFonts = {
        # ---- Monospace (Terminal/Code) ----
        # Priority: Nerd Fonts first (icon glyphs), then standard coding fonts
        monospace = [
          "Maple Mono NF"         # Primary terminal font
          "Hack Nerd Font Mono"   # Alternative with excellent readability
          "JetBrains Mono"        # IDE font (ligatures)
          "Fira Code"             # Popular coding font
          "Source Code Pro"       # Adobe's monospace
          "Liberation Mono"       # Fallback (always available)
          "Noto Color Emoji"      # Emoji in terminal (kitty, alacritty support)
        ];
        
        # Why this order?
        # 1. Nerd Fonts have icon glyphs (Powerline, Font Awesome, etc.)
        # 2. Coding fonts have ligatures (→ => != === etc.)
        # 3. Liberation Mono is metric-compatible fallback
        # 4. Emoji at end (only used when monospace doesn't have glyph)
        
        # ---- Emoji (Color Glyphs) ----
        # Single choice: Noto Color Emoji (best Linux support)
        emoji = [ "Noto Color Emoji" ];
        
        # Alternative emoji fonts (commented):
        # emoji = [ "Twitter Color Emoji" ];  # More expressive
        # emoji = [ "Segoe UI Emoji" ];       # Windows-style (proprietary)
        
        # ---- Serif (Documents, Books) ----
        # Traditional fonts with serifs (for long-form text)
        serif = [
          "Liberation Serif"   # Libre alternative to Times New Roman
          "Noto Serif"         # Google's serif (Unicode coverage)
          "DejaVu Serif"       # Extended Unicode fallback
        ];
        
        # ---- Sans-serif (UI, Web) ----
        # Modern fonts without serifs (most UI text)
        sansSerif = [
          "Liberation Sans"    # Libre alternative to Arial
          "Inter"              # Modern UI font (excellent for screens)
          "Noto Sans"          # Google's sans (Unicode coverage)
          "DejaVu Sans"        # Extended Unicode fallback
        ];
      };

      # ========================================================================
      # Subpixel Rendering (LCD Optimization)
      # ========================================================================
      # Uses RGB subpixels for sharper text on LCD screens
      # Note: May look worse on OLED or rotated displays
      
      subpixel = {
        # ---- RGB Order ----
        # Most LCDs use RGB subpixel order (Red-Green-Blue)
        # BGR for some displays (swap if text looks odd)
        rgba = "rgb";
        
        # Alternative orders (uncomment if needed):
        # rgba = "bgr";  # Blue-Green-Red (some LCDs)
        # rgba = "vrgb"; # Vertical RGB (rotated display)
        # rgba = "none"; # Disable subpixel (OLED, HiDPI)
        
        # ---- LCD Filter ----
        # Reduces color fringing from subpixel rendering
        # Options: default, light, legacy, none
        lcdfilter = "default";
      };

      # ========================================================================
      # Font Hinting (Grid Fitting)
      # ========================================================================
      # Aligns font outlines to pixel grid for sharper rendering
      # Trade-off: Sharpness vs shape accuracy
      
      hinting = {
        # ---- Hinting Enabled ----
        # Recommended for most screens (improves sharpness)
        enable = true;
        
        # ---- Autohint Disabled ----
        # Use font's native hinting (better quality)
        # Autohint: Automatic hinting (fallback for fonts without hints)
        autohint = false;
        
        # ---- Hinting Style ----
        # Options: none, slight, medium, full
        # slight: Best balance (shape accuracy + readability)
        # full: Maximum sharpness (may distort glyphs)
        style = "slight";
      };

      # ========================================================================
      # Anti-aliasing (Smoothing)
      # ========================================================================
      # Blurs edges for smoother curves (essential for modern displays)
      # Disable only on very low-resolution screens (~96 DPI)
      antialias = true;
    };

    # ==========================================================================
    # Font System Integration
    # ==========================================================================
    
    # ---- Default Font Packages ----
    # Include NixOS defaults (basic fonts, fallback sets)
    enableDefaultPackages = true;
    
    # ---- Font Directory ----
    # Create /run/current-system/sw/share/X11/fonts/
    # Used by: Legacy X11 apps, some font tools
    fontDir.enable = true;
  };

  # ============================================================================
  # System Environment (Layer 12: Global Variables)
  # ============================================================================
  # Environment variables affecting display, fonts, and internationalization
  
  environment = {
    # ==========================================================================
    # Global Environment Variables
    # ==========================================================================
    # Set system-wide (affect all users and sessions)
    
    variables = {
      # ---- Fontconfig Paths ----
      # Where fontconfig looks for configuration files
      FONTCONFIG_PATH = "/etc/fonts";
      FONTCONFIG_FILE = "/etc/fonts/fonts.conf";
      
      # ---- Locale Configuration ----
      # UTF-8 encoding for proper Unicode support
      # Required for: Emoji, CJK text, special symbols
      LC_ALL = "en_US.UTF-8";
      
      # ---- FreeType Font Rendering ----
      # Interpreter version affects hinting behavior
      # Version 40: Modern hinting (recommended)
      # Version 35: Legacy hinting (compatibility)
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    # ==========================================================================
    # System Packages (Layer 13: Font Tools)
    # ==========================================================================
    # Utilities for font management and debugging
    
    systemPackages = (with pkgs; [
      # ---- Font Management ----
      fontconfig     # Font configuration library (fc-cache, fc-list, etc.)
      font-manager   # GUI font browser and manager
      
      # ---- Debugging Tools (optional, uncomment if needed) ----
      # fontforge        # Font editor (create/modify fonts)
      # fontpreview      # Quick font preview in terminal
      # gucharmap        # GNOME Character Map (browse Unicode)
    ]) ++ [
      # ---- Custom Session Package ----
      # Make hyprland-optimized.desktop available system-wide
      hyprlandOptimizedSession
    ];
  };

  # ============================================================================
  # Home-Manager User Configuration (Layer 14: User Preferences)
  # ============================================================================
  # Per-user settings that complement system configuration
  # Note: Full user config lives in home-manager module
  
  home-manager.users.${username} = {
    # ==========================================================================
    # Home-Manager Version
    # ==========================================================================
    # Declare state version for compatibility tracking
    # Update cautiously (may break existing config)
    home.stateVersion = "25.11";

    # ==========================================================================
    # Font Configuration
    # ==========================================================================
    # Enable user-level fontconfig (respects system fonts)
    fonts.fontconfig.enable = true;

    # ==========================================================================
    # Application Font Settings
    # ==========================================================================
    # Configure fonts for user applications
    
    # ---- Rofi Launcher ----
    # Application launcher font configuration
    programs.rofi = {
      font = "Hack Nerd Font 13";              # Nerd Font for icon support
      terminal = "${pkgs.kitty}/bin/kitty";   # Terminal for "run in terminal"
    };
    
    # Additional application fonts can be configured here:
    # programs.alacritty.settings.font.normal.family = "Maple Mono NF";
    # programs.kitty.font.family = "Maple Mono NF";
    # programs.waybar.style = "* { font-family: 'Hack Nerd Font'; }";

    # ==========================================================================
    # Shell Aliases (Font Diagnostics & Testing)
    # ==========================================================================
    # Convenience commands for font debugging and verification
    
    home.shellAliases = {
      # ========================================================================
      # Font Information & Discovery
      # ========================================================================
      
      # ---- List Fonts ----
      "font-list"        = "fc-list";  # List all installed fonts
      "font-emoji"       = "fc-list | grep -i emoji";  # Find emoji fonts
      "font-nerd"        = "fc-list | grep -i 'nerd\\|hack\\|maple'";  # Find Nerd Fonts
      "font-maple"       = "fc-list | grep -i maple";  # Find Maple Mono variants
      
      # ---- Font Cache Management ----
      "font-reload"      = "fc-cache -f -v";  # Force rebuild font cache (verbose)
      "font-cache-clean" = "fc-cache -f -r -v";  # Clean + rebuild cache
      
      # ========================================================================
      # Font Rendering Tests
      # ========================================================================
      # Visual tests to verify font rendering
      
      # ---- Basic Font Test ----
      "font-test" = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols'";
      
      # ---- Emoji Test ----
      "emoji-test" = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
      
      # ---- Comprehensive Rendering Test ----
      "font-render-test" = "echo 'Rendering: ABCDabcd1234 ★♪●⚡▲ 🚀📱💬'";
      
      # ---- Ligature Test ----
      # Tests programming ligatures (requires ligature-capable terminal)
      "font-ligature-test" = "echo 'Ligatures: -> => != === >= <= && || /* */ //'";
      
      # ---- Nerd Font Icons Test ----
      # Tests Nerd Font icon glyphs (Powerline, Font Awesome, etc.)
      "font-nerd-icons" = "echo 'Nerd Icons:     󰈹 󰍛'";

      # ========================================================================
      # Notification Daemon Tests (Mako/Dunst)
      # ========================================================================
      # Test font rendering in notification popups
      
      # ---- Emoji in Notifications ----
      "mako-emoji-test" = "notify-send 'Emoji Test 🚀' 'Emojis: 📱 💬 🔥 ⭐ 🎵'";
      
      # ---- Font Symbols in Notifications ----
      "mako-font-test" = "notify-send 'Font Test' 'Symbols: ★ ♪ ● ⚡ ▲'";
      
      # ---- Nerd Font Icons in Notifications ----
      "mako-icons-test" = "notify-send 'Icon Test' 'Icons:     󰈹 󰍛'";

      # ========================================================================
      # Deep Diagnostics (Advanced Troubleshooting)
      # ========================================================================
      
      # ---- Font Info ----
      # Show detailed info about default font
      "font-info" = "fc-match -v";
      
      # ---- Font Debug ----
      # Show fallback chain for monospace fonts
      "font-debug" = "fc-match -s monospace | head -5";
      
      # ---- List Monospace Fonts ----
      # Find all available monospace fonts
      "font-mono" = "fc-list : family | grep -i mono | sort";
      
      # ---- List All Available Fonts ----
      # Show unique font families
      "font-available" = "fc-list : family | sort | uniq";
    };

    # ==========================================================================
    # Session Variables (User Environment)
    # ==========================================================================
    # User-specific environment variables
    
    home.sessionVariables = {
      # ---- Locale ----
      LC_ALL = "en_US.UTF-8";
      
      # ---- Fontconfig Paths ----
      # User config overrides system config
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
      
      # ---- FreeType Rendering ----
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    # ==========================================================================
    # User Packages (Font Utilities)
    # ==========================================================================
    # Additional font tools for user
    
    home.packages = with pkgs; [
      fontpreview   # Terminal-based font preview (quick testing)
      gucharmap     # GNOME Character Map (Unicode browser)
    ];
  };
}

# ==============================================================================
# Post-Installation Verification & Testing
# ==============================================================================
#
# After running `nixos-rebuild switch --flake .#hay`, verify setup:
#
# 1. Session Availability:
#    ─────────────────────────────────────────────────────────────────────────
#    $ ls /run/current-system/sw/share/wayland-sessions/
#    # Expected output:
#    #   hyprland.desktop
#    #   hyprland-optimized.desktop
#    #   gnome.desktop
#    #   cosmic.desktop
#    
#    $ ls /run/current-system/sw/share/xsessions/
#    # Expected: GNOME X11 session (fallback)
#
# 2. Portal Verification (in Hyprland session):
#    ─────────────────────────────────────────────────────────────────────────
#    $ busctl --user list | grep portal
#    # Expected output:
#    #   org.freedesktop.impl.portal.desktop.hyprland  (Hyprland portal)
#    #   org.freedesktop.impl.portal.desktop.gtk       (GTK portal)
#    #   org.freedesktop.portal.Desktop                (Portal router)
#    
#    # Optional (if COSMIC enabled):
#    #   org.freedesktop.impl.portal.desktop.cosmic
#    
#    # Test portal routing:
#    $ systemctl --user status xdg-desktop-portal.service
#    $ systemctl --user status xdg-desktop-portal-hyprland.service
#
# 3. Systemd User Session Health:
#    ─────────────────────────────────────────────────────────────────────────
#    $ systemctl --user is-system-running
#    # Expected: "running" or "degraded"
#    # NOT: "chroot" (indicates systemd not properly initialized)
#    
#    $ echo $SYSTEMD_OFFLINE
#    # Expected: "0" (systemd online)
#    # NOT: "1" (indicates offline/chroot mode)
#    
#    $ systemctl --user list-units --failed
#    # Check for any failed services (troubleshoot if present)
#
# 4. Font Verification:
#    ─────────────────────────────────────────────────────────────────────────
#    $ fc-list | grep -i "maple\|hack\|emoji"
#    # Expected: Maple Mono NF, Hack Nerd Font, Noto Color Emoji
#    
#    $ font-test
#    # Visual check: Symbols should render correctly (★ ♪ ● ⚡ ▲)
#    
#    $ emoji-test
#    # Visual check: Color emoji should display (🎵 📱 💬 🔥 ⭐ 🚀)
#    
#    $ font-debug
#    # Check font fallback chain (Maple Mono → Hack → etc.)
#
# 5. Audio Stack Verification:
#    ─────────────────────────────────────────────────────────────────────────
#    $ pactl info
#    # Expected output should include:
#    #   Server Name: PulseAudio (on PipeWire)
#    #   Server Version: 15.0.0
#    
#    $ wpctl status
#    # WirePlumber status (PipeWire session manager)
#    # Should show audio devices and running applications
#    
#    $ systemctl --user status pipewire.service
#    $ systemctl --user status wireplumber.service
#    # Both should be active (running)
#
# 6. User Services (Hyprland session):
#    ─────────────────────────────────────────────────────────────────────────
#    $ systemctl --user status waybar.service
#    # Expected: active (running)
#    # NOT: "Running in chroot" error
#    
#    $ systemctl --user status mako.service
#    # Notification daemon should be running
#    
#    $ journalctl --user -u waybar.service -n 50
#    # Check for errors if waybar not starting
#
# 7. Display Manager & Session:
#    ─────────────────────────────────────────────────────────────────────────
#    $ systemctl status display-manager.service
#    # Should be gdm.service (active)
#    
#    $ loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}')
#    # Check session properties (Type=wayland, Desktop=Hyprland)
#    
#    $ echo $XDG_SESSION_TYPE
#    # Expected: "wayland"
#    
#    $ echo $XDG_CURRENT_DESKTOP
#    # Expected: "Hyprland" (or "GNOME", "COSMIC" depending on session)
#
# ==============================================================================
# Troubleshooting Guide
# ==============================================================================
#
# Issue: Waybar or other user services not starting
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: systemctl --user shows "Running in chroot" or services fail
# Cause: Systemd user session not properly initialized by session manager
# 
# Fix:
#   1. Verify hyprland_tty script is being used (not direct Hyprland)
#      $ cat /run/current-system/sw/share/wayland-sessions/hyprland-optimized.desktop
#      # Should show: Exec=/etc/profiles/per-user/kenan/bin/hyprland_tty
#   
#   2. Check systemd status during session:
#      $ echo $SYSTEMD_OFFLINE  # Should be 0, not 1
#      $ systemctl --user is-system-running  # Should not be "chroot"
#   
#   3. Manual service restart:
#      $ systemctl --user restart waybar.service
#      $ journalctl --user -u waybar.service -f  # Watch logs
#   
#   4. If still broken, check D-Bus:
#      $ echo $DBUS_SESSION_BUS_ADDRESS
#      # Should be: unix:path=/run/user/1000/bus
#
# Issue: Portal conflicts or wrong portal being used
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: File picker shows wrong theme, screenshot tool doesn't work
# Cause: Multiple portals registered, wrong one taking precedence
# 
# Fix:
#   1. Check active portals:
#      $ busctl --user list | grep portal
#   
#   2. Check portal routing:
#      $ cat ~/.config/xdg-desktop-portal/portals.conf
#      # Or system-wide: /etc/xdg-desktop-portal/portals.conf
#   
#   3. Restart portal service:
#      $ systemctl --user restart xdg-desktop-portal.service
#      $ systemctl --user restart xdg-desktop-portal-hyprland.service
#   
#   4. Test portal explicitly:
#      $ XDG_CURRENT_DESKTOP=Hyprland \
#        busctl --user call org.freedesktop.portal.Desktop \
#        /org/freedesktop/portal/desktop \
#        org.freedesktop.portal.Screenshot Screenshot "ssa{sv}" "" "" {}
#
# Issue: Fonts not rendering correctly
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: Missing glyphs (□ boxes), wrong font displayed, no emoji
# Cause: Font cache outdated, font not installed, fontconfig misconfigured
# 
# Fix:
#   1. Rebuild font cache:
#      $ fc-cache -f -v  # Force rebuild, verbose output
#   
#   2. Check font availability:
#      $ font-list | grep -i "hack\|maple\|emoji"
#      # Should show: Hack Nerd Font, Maple Mono NF, Noto Color Emoji
#   
#   3. Test font fallback:
#      $ font-debug  # Shows fallback chain for monospace
#      $ fc-match "monospace"  # Shows primary monospace font
#   
#   4. Check specific font:
#      $ fc-list | grep "Maple Mono"
#      # Should show: Maple Mono NF Regular, Bold, Italic, etc.
#   
#   5. Test rendering:
#      $ font-test        # Symbols test
#      $ emoji-test       # Color emoji test
#      $ font-nerd-icons  # Nerd Font icons test
#
# Issue: Emoji showing as black & white
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: Emoji render but without color
# Cause: Terminal/app doesn't support color emoji, wrong font selected
# 
# Fix:
#   1. Verify Noto Color Emoji installed:
#      $ font-emoji
#      # Should show: Noto Color Emoji
#   
#   2. Check terminal support:
#      - Kitty: Full color emoji support ✓
#      - Alacritty: Limited support (recent versions)
#      - Foot: Full color emoji support ✓
#      - Wezterm: Full color emoji support ✓
#   
#   3. Test in supported app:
#      $ kitty +kitten icat <emoji-image>
#      $ emoji-test  # In Kitty terminal
#   
#   4. Force color emoji in fontconfig:
#      # Add to ~/.config/fontconfig/fonts.conf:
#      <alias>
#        <family>monospace</family>
#        <prefer>
#          <family>Noto Color Emoji</family>
#        </prefer>
#      </alias>
#
# Issue: COSMIC portal active in Hyprland session
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: busctl shows cosmic portal even in Hyprland
# Cause: Normal behavior - portal is registered but not used
# 
# Explanation:
#   - COSMIC portal registers with D-Bus (always shows in busctl)
#   - Portal router (xdg-desktop-portal) chooses correct backend
#   - xdg.portal.config ensures Hyprland portal used in Hyprland session
#   - No conflict - just registered, not active
# 
# Verify correct routing:
#   $ XDG_CURRENT_DESKTOP=Hyprland fc-match # Should use Hyprland config
#   # Test screenshot: should use Hyprland portal, not COSMIC
#
# Issue: GDM not showing sessions
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: Only one session available at login, or sessions missing
# Cause: Session files not in correct location
# 
# Fix:
#   1. Check session files:
#      $ ls /run/current-system/sw/share/wayland-sessions/
#      $ ls /run/current-system/sw/share/xsessions/
#   
#   2. Verify session packages registered:
#      $ nix eval --raw .#nixosConfigurations.hay.config.services.displayManager.sessionPackages
#   
#   3. Restart GDM:
#      $ sudo systemctl restart display-manager.service
#   
#   4. Check GDM logs:
#      $ journalctl -u display-manager.service -n 100
#
# Issue: Audio not working
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: No sound, application can't find audio device
# Cause: PipeWire not running, wrong audio server, permissions issue
# 
# Fix:
#   1. Check PipeWire status:
#      $ systemctl --user status pipewire.service
#      $ systemctl --user status wireplumber.service
#   
#   2. Verify PipeWire providing PulseAudio:
#      $ pactl info | grep "Server Name"
#      # Should show: PulseAudio (on PipeWire)
#   
#   3. List audio devices:
#      $ wpctl status  # WirePlumber status
#      $ pactl list sinks  # PulseAudio sinks
#   
#   4. Test audio:
#      $ speaker-test -t wav -c 2  # Generate test sound
#      $ paplay /usr/share/sounds/freedesktop/stereo/complete.oga
#   
#   5. Check permissions:
#      $ groups | grep audio  # User should be in audio group
#   
#   6. Restart audio stack:
#      $ systemctl --user restart pipewire.service
#      $ systemctl --user restart wireplumber.service
#
# Issue: Keyboard layout not working
# ─────────────────────────────────────────────────────────────────────────────
# Symptom: Turkish F-keyboard not active, Caps Lock still Caps Lock
# Cause: Layout not propagated to Wayland compositor
# 
# Fix:
#   1. Check X keyboard config (affects Wayland):
#      $ setxkbmap -query
#      # Should show: layout: tr, variant: f, options: ctrl:nocaps
#   
#   2. Hyprland uses XKB config from services.xserver.xkb
#      # Already configured in this module:
#      services.xserver.xkb = {
#        layout = "tr";
#        variant = "f";
#        options = "ctrl:nocaps";
#      };
#   
#   3. Manual Hyprland keyboard config (if needed):
#      # In ~/.config/hypr/hyprland.conf:
#      input {
#        kb_layout = tr
#        kb_variant = f
#        kb_options = ctrl:nocaps
#      }
#   
#   4. Reload Hyprland:
#      $ hyprctl reload
#      # Or: Super+Shift+Q (quit and restart)
#
# ==============================================================================
# Security Considerations
# ==============================================================================
#
# 1. Auto-login Security:
#    ─────────────────────────────────────────────────────────────────────────
#    Current config enables auto-login for user "kenan"
#    
#    Risks:
#    - Physical access = immediate system access (no password)
#    - Boot-to-desktop without authentication
#    - Suitable for: Single-user systems, trusted environments
#    
#    Hardening options:
#    a) Disable auto-login:
#       services.displayManager.autoLogin.enable = false;
#    
#    b) Enable disk encryption (LUKS):
#       - Requires password at boot (before auto-login)
#       - Protects data at rest
#       - Auto-login OK with full-disk encryption
#    
#    c) Enable lock screen timeout:
#       # In Hyprland: swayidle + swaylock
#       # Auto-lock after N minutes of inactivity
#
# 2. Portal Sandboxing:
#    ─────────────────────────────────────────────────────────────────────────
#    Portals provide security boundaries for applications
#    
#    Best practices:
#    - Review portal permissions for Flatpak apps (use Flatseal)
#    - Minimize filesystem access (avoid --filesystem=host)
#    - Use portal-based file access (picker dialog, not direct path)
#    - Monitor portal usage: journalctl --user -u xdg-desktop-portal.service
#
# 3. Session Security:
#    ─────────────────────────────────────────────────────────────────────────
#    - GNOME Keyring auto-unlock on login (convenience vs security)
#    - Consider separate keyring password for sensitive keys
#    - Use hardware tokens (YubiKey) for SSH keys
#    - Enable 2FA for critical services
#
# 4. Display Manager Hardening:
#    ─────────────────────────────────────────────────────────────────────────
#    - GDM runs as root (necessary for display management)
#    - Wayland isolates sessions (better than X11)
#    - Disable unused sessions to reduce attack surface
#    - Monitor GDM logs: journalctl -u display-manager.service
#
# ==============================================================================
# Performance Optimization
# ==============================================================================
#
# 1. Font Rendering Performance:
#    ─────────────────────────────────────────────────────────────────────────
#    Current config prioritizes quality over performance
#    
#    For faster rendering (lower-end hardware):
#    fonts.fontconfig = {
#      antialias = true;
#      hinting.enable = true;
#      hinting.style = "medium";  # Or "full" for maximum speed
#      subpixel.rgba = "none";     # Disable subpixel rendering
#    };
#
# 2. PipeWire Latency:
#    ─────────────────────────────────────────────────────────────────────────
#    Adjust quantum (buffer size) for latency vs stability
#    
#    For pro audio (low latency):
#    services.pipewire.extraConfig.pipewire = {
#      "context.properties" = {
#        "default.clock.rate" = 48000;
#        "default.clock.quantum" = 32;      # Lower = less latency
#        "default.clock.min-quantum" = 32;
#      };
#    };
#    
#    For stability (high latency):
#    # Use quantum = 1024 or 2048
#
# 3. Portal Performance:
#    ─────────────────────────────────────────────────────────────────────────
#    - Multiple portals = minor overhead (acceptable)
#    - Disable unused desktop environments to reduce services
#    - Monitor portal CPU usage: htop (filter: portal)
#
# ==============================================================================
# Advanced Configuration Examples
# ==============================================================================
#
# 1. HiDPI Scaling:
#    ─────────────────────────────────────────────────────────────────────────
#    # For 4K displays, add to home-manager:
#    home.sessionVariables = {
#      GDK_SCALE = "2";        # GTK apps 2x scaling
#      GDK_DPI_SCALE = "0.5";  # Compensate font scaling
#      QT_SCALE_FACTOR = "2";  # Qt apps 2x scaling
#    };
#    
#    # Hyprland monitor config:
#    monitor=DP-1,3840x2160@144,0x0,2  # 2x scale factor
#
# 2. Multi-Monitor Setup:
#    ─────────────────────────────────────────────────────────────────────────
#    # In ~/.config/hypr/hyprland.conf:
#    monitor=DP-1,2560x1440@144,0x0,1      # Primary (left)
#    monitor=DP-2,2560x1440@144,2560x0,1   # Secondary (right)
#    monitor=HDMI-A-1,1920x1080@60,5120x0,1  # Tertiary
#    
#    workspace=1,monitor:DP-1     # Workspace 1 on primary
#    workspace=2,monitor:DP-2     # Workspace 2 on secondary
#
# 3. Custom Font Directories:
#    ─────────────────────────────────────────────────────────────────────────
#    # Add user fonts:
#    fonts.fontDir.enable = true;
#    
#    # User fonts location: ~/.local/share/fonts/
#    # System fonts: /run/current-system/sw/share/X11/fonts/
#    
#    # Refresh cache after adding fonts:
#    $ fc-cache -f -v ~/.local/share/fonts
#
# 4. Fractional Scaling (Experimental):
#    ─────────────────────────────────────────────────────────────────────────
#    # Hyprland supports fractional scaling (1.5x, 1.25x, etc.)
#    monitor=DP-1,2560x1440@144,0x0,1.5  # 1.5x scaling
#    
#    # Note: May cause blurriness in some apps
#    # Xwayland apps scaled via xwayland:force_zero_scaling
#
# ==============================================================================
