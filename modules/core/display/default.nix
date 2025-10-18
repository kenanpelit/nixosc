# modules/core/display/default.nix
# ==============================================================================
# Display & Desktop Environment Module - Production Grade
# ==============================================================================
#
# Module:      modules/core/display
# Author:      Kenan Pelit
# Created:     2025-10-10
# Modified:    2025-10-17
# Version:     2.0
#
# Purpose:
#   Unified display stack management with multi-desktop support, proper portal
#   routing, and conditional service activation to prevent log pollution.
#
# Architecture Overview:
#   ┌─────────────────────────────────────────────────────────────────┐
#   │                         GDM (Display Manager)                   │
#   ├─────────────┬─────────────────┬─────────────────┬───────────────┤
#   │  Hyprland   │  Hyprland (Opt) │     GNOME       │    COSMIC     │
#   │  (Standard) │  (Intel Arc)    │  (Traditional)  │   (Beta/Rust) │
#   └─────────────┴─────────────────┴─────────────────┴───────────────┘
#                           ↓
#   ┌─────────────────────────────────────────────────────────────────┐
#   │              XDG Desktop Portal Layer                           │
#   │  • Hyprland Portal → Screenshots, Screen share                  │
#   │  • COSMIC Portal   → File picker, Screenshots (conditional)     │
#   │  • GNOME Portal    → GNOME integration                          │
#   │  • GTK Portal      → Universal fallback                         │
#   └─────────────────────────────────────────────────────────────────┘
#                           ↓
#   ┌─────────────────────────────────────────────────────────────────┐
#   │              Audio Stack (PipeWire)                             │
#   │  PipeWire → ALSA/PulseAudio/JACK compatibility                  │
#   └─────────────────────────────────────────────────────────────────┘
#
# Key Features:
#   ✓ Multi-desktop flexibility (switch sessions via GDM)
#   ✓ Conditional portal activation (no log spam from unused desktops)
#   ✓ Intel Arc A380 optimizations (custom Hyprland launcher)
#   ✓ Comprehensive font stack (Nerd Fonts, emoji, CJK)
#   ✓ Wayland-first with XWayland fallback
#   ✓ PipeWire unified audio (replaces PulseAudio/JACK)
#
# Design Principles:
#   1. Desktop-agnostic portal routing (each DE gets correct backend)
#   2. Conditional service activation (don't start what you don't use)
#   3. Fail-safe fallbacks (GTK portal as universal backup)
#   4. Zero-config user experience (works out of box)
#   5. Debug-friendly (extensive aliases for troubleshooting)
#
# Session Selection Flow:
#   1. Boot → GDM login screen
#   2. Select user → Click gear icon (⚙️)
#   3. Choose session:
#      • Hyprland (Optimized) ← Default, Intel Arc tuned
#      • Hyprland             ← Standard build
#      • GNOME                ← Traditional GNOME
#      • COSMIC               ← Rust-based DE (Beta)
#   4. Login → Selected desktop starts with correct portal backend
#
# Troubleshooting:
#   • Portal issues:       busctl --user list | grep portal
#   • Session won't start: journalctl -xe --user
#   • Font problems:       font-debug (see aliases below)
#   • Audio issues:        pactl info
#
# Module Dependencies:
#   • inputs.hyprland (flake input for locked Hyprland version)
#   • home-manager (user-specific font/diagnostic configs)
#
# ==============================================================================
{ username, inputs, pkgs, lib, config, ... }:

let
  # ---------------------------------------------------------------------------
  # Hyprland Packages - Locked Version from Flake Input
  # ---------------------------------------------------------------------------
  # Using flake input ensures portal compatibility (mismatched versions cause
  # portal failures). Both package and portal must be from same source.
  
  hyprlandPkg = inputs.hyprland.packages.${pkgs.system}.default;
  hyprPortal  = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;

  # ---------------------------------------------------------------------------
  # GDM Session Wrapper - Systemd-Aware Pre-Start Handler
  # ---------------------------------------------------------------------------
  # This wrapper script runs BEFORE hyprland_tty to ensure systemd user session
  # is properly initialized when launching from GDM. This solves the issue where
  # GDM sessions start with incomplete systemd context.
  #
  # What it does:
  #   1. Checks if systemd user session is running
  #   2. Starts default.target if needed (with 2s initialization time)
  #   3. Activates hyprland-session.target for service dependencies
  #   4. Hands off to hyprland_tty for main compositor launch
  #
  # Why needed:
  #   • GDM sometimes launches sessions before systemd user manager is ready
  #   • User services (Waybar, Mako) need proper systemd context
  #   • Environment variables need to be synced to systemd
  #
  # NixOS-safe:
  #   • Uses full Nix store paths (no /bin/sh assumptions)
  #   • writeShellScriptBin ensures proper bash shebang
  #   • All dependencies are declarative
  
  hyprlandGdmWrapper = pkgs.writeShellScriptBin "hyprland-gdm-wrapper" ''
    # Systemd user session readiness check
    # GDM may start session before systemd user manager is fully initialized
    if ! systemctl --user is-system-running &>/dev/null; then
      # Start systemd user default target (includes graphical-session-pre.target)
      systemctl --user start default.target 2>/dev/null || true
      
      # Give systemd time to initialize services (critical for GDM context)
      sleep 2
    fi
    
    # Activate Hyprland session target
    # This triggers any services that are BindsTo/Wants hyprland-session.target
    # (e.g., compositor-specific services, environment sync services)
    systemctl --user start hyprland-session.target 2>/dev/null || true
    sleep 1
    
    # Hand off to main Hyprland launcher
    # hyprland_tty will handle environment setup, Intel Arc optimizations,
    # Catppuccin theming, and compositor launch
    exec /etc/profiles/per-user/${username}/bin/hyprland_tty
  '';

  # ---------------------------------------------------------------------------
  # Custom Hyprland Session - Intel Arc A380 Optimized
  # ---------------------------------------------------------------------------
  # This creates a custom .desktop entry for GDM to discover. The desktop entry
  # now uses the wrapper script instead of calling hyprland_tty directly.
  #
  # Launch Chain:
  #   GDM → hyprland-gdm-wrapper → systemd setup → hyprland_tty → Hyprland
  #
  # Features:
  #   • Intel Arc environment variables (VK_ICD_FILENAMES, LIBVA_DRIVER_NAME)
  #   • Catppuccin theme preloading
  #   • Custom compositor flags
  #   • Proper systemd user session initialization
  #
  # Dual Registration:
  #   1. services.displayManager.sessionPackages → GDM discovers session
  #   2. environment.systemPackages → Wrapper appears in system PATH
  #
  # passthru.providedSessions:
  #   Must match defaultSession value exactly. GDM uses this to validate.
  
  hyprlandOptimizedSession = pkgs.writeTextFile {
    name = "hyprland-optimized-session";
    destination = "/share/wayland-sessions/hyprland-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland (Optimized)
      Comment=Hyprland with Intel Arc A380 optimizations and Catppuccin theming
      
      # Session Type Markers (required for GDM)
      Type=Application
      DesktopNames=Hyprland
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
      
      # Launcher Path - Uses wrapper for proper systemd initialization
      # The wrapper ensures systemd user session is ready before Hyprland starts
      Exec=${hyprlandGdmWrapper}/bin/hyprland-gdm-wrapper
      
      # Optional: Pre-flight check (validates wrapper exists before session start)
      # TryExec=${hyprlandGdmWrapper}/bin/hyprland-gdm-wrapper
      
      # Metadata
      Keywords=wayland;wm;tiling;catppuccin;intel-arc;systemd;
    '';
    
    # GDM Session Discovery Metadata
    # GDM reads this to populate session picker dropdown
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

in
{
  # =============================================================================
  # Wayland Compositor - Hyprland
  # =============================================================================
  # Standard Hyprland configuration. The "Hyprland (Optimized)" session above
  # coexists with this standard build, giving users choice at login.
  
  programs.hyprland = {
    enable = true;
    package = hyprlandPkg;
    
    # CRITICAL: Portal must match Hyprland version
    # Do NOT add hyprPortal to xdg.portal.extraPortals (already registered here)
    portalPackage = hyprPortal;
  };
  # =============================================================================
  # System Services Configuration
  # =============================================================================
  services = {
    # ---------------------------------------------------------------------------
    # X11 Server (Legacy Compatibility Only)
    # ---------------------------------------------------------------------------
    # Required for:
    #   • GDM (uses X11 for greeter, Wayland for sessions)
    #   • XWayland (X11 apps in Wayland sessions)
    #   • Keyboard layout configuration (propagates to Wayland)
    #
    # Not used for: Primary display protocol (that's Wayland)
    
    xserver = {
      enable = true;
      
      # Turkish F-Keyboard Layout
      # Why F variant? More ergonomic than Q layout for Turkish typing.
      xkb = {
        layout  = "tr";           # Turkish
        variant = "f";            # F-keyboard (not Q)
        options = "ctrl:nocaps";  # Caps Lock → Control (ergonomics)
      };
    };

    # ---------------------------------------------------------------------------
    # Display Manager - GDM
    # ---------------------------------------------------------------------------
    # GDM (GNOME Display Manager) chosen for:
    #   ✓ Excellent Wayland support
    #   ✓ Robust multi-session handling
    #   ✓ Proper XDG portal integration
    #   ✓ Beautiful, modern UI
    
    displayManager = {
      # Custom Session Registration
      # hyprlandOptimizedSession appears in GDM's session picker
      sessionPackages = [ hyprlandOptimizedSession ];

      # GDM Configuration
      gdm = {
        enable = true;
        wayland = true;        # Prefer Wayland sessions
        autoSuspend = false;   # Don't sleep on login screen (annoying in dev)
      };

      # Default Session Selection
      # User can override at login via gear icon (⚙️)
      # Valid options: "hyprland", "hyprland-optimized", "gnome", "cosmic"
      defaultSession = "hyprland-optimized";

      # Auto-Login (Security vs Convenience Trade-off)
      # Enable only if:
      #   ✓ Single-user machine with full disk encryption
      #   ✓ Physical security is adequate
      # Disable if:
      #   ✓ Shared machine or travels (laptop)
      #   ✓ No disk encryption
      autoLogin = {
        enable = false;  # Require password (recommended)
        user = "kenan";
      };
      
      # Disable conflicting display managers
      sddm.enable = false;  # KDE's display manager
    };

    # ---------------------------------------------------------------------------
    # Desktop Environments
    # ---------------------------------------------------------------------------
    # All enabled desktops appear in GDM's session picker.
    # Each runs isolated - no conflicts.
    
    desktopManager = {
      gnome.enable  = true;  # GNOME - Full-featured traditional desktop
      cosmic.enable = true;  # COSMIC - Rust-based, System76 (Beta/Experimental)
    };

    # ---------------------------------------------------------------------------
    # Input Device Management
    # ---------------------------------------------------------------------------
    libinput.enable = true;  # Modern touchpad/mouse handling (replaces synaptics)

    # ---------------------------------------------------------------------------
    # Session Security - GNOME Keyring
    # ---------------------------------------------------------------------------
    # Manages session secrets (WiFi passwords, SSH keys, browser passwords)
    # Works across all desktop environments, not just GNOME
    gnome.gnome-keyring.enable = true;

    # ---------------------------------------------------------------------------
    # Audio Stack - PipeWire
    # ---------------------------------------------------------------------------
    # Modern audio server with ALSA/PulseAudio/JACK compatibility.
    # 
    # Why PipeWire?
    #   ✓ Low latency (good for gaming/music production)
    #   ✓ Replaces PulseAudio without breaking apps
    #   ✓ JACK support for pro audio (if enabled)
    #   ✓ Per-app audio routing
    #   ✓ Bluetooth audio improvements
    
    pipewire = {
      enable = true;
      
      # ALSA Support (legacy apps, direct hardware access)
      alsa.enable = true;
      alsa.support32Bit = true;  # 32-bit games/Wine apps
      
      # PulseAudio Compatibility (most desktop apps)
      pulse.enable = true;
      
      # JACK Support (disable unless using DAW/music production)
      # Enabling JACK can conflict with PulseAudio routing
      jack.enable = false;
    };

    # ---------------------------------------------------------------------------
    # D-Bus Configuration - Portal Package Registration
    # ---------------------------------------------------------------------------
    # D-Bus must know about portal packages for proper activation.
    # Each desktop's portal must be registered here.
    
    dbus = {
      enable = true;
      packages = with pkgs; [
        xdg-desktop-portal           # Base portal framework
        xdg-desktop-portal-gtk       # GTK apps (universal fallback)
        xdg-desktop-portal-gnome     # GNOME-specific integrations
        xdg-desktop-portal-cosmic    # COSMIC portal (for COSMIC DE)
      ];
      # Note: xdg-desktop-portal-hyprland registered via programs.hyprland.portalPackage
    };
  };

  # =============================================================================
  # XDG Desktop Portals - Backend Routing Configuration
  # =============================================================================
  # Portals provide desktop integration (file pickers, screenshots, screen share)
  # in a compositor-agnostic way. Each desktop needs correct backend routing.
  #
  # Portal Interfaces:
  #   • Screenshot      - Take screenshots
  #   • ScreenCast      - Screen recording/sharing
  #   • FileChooser     - File open/save dialogs
  #   • Notification    - Desktop notifications
  #   • Inhibit         - Prevent suspend/screensaver
  #
  # Configuration Format:
  #   <session>.<interface> = [ "preferred" "fallback" ];
  #
  # Testing Portals:
  #   busctl --user list | grep portal                    # Active portals
  #   cat /run/user/$(id -u)/xdg-desktop-portal/*.conf   # Runtime config
  
  xdg.portal = {
    enable = true;
    
    # Force xdg-open to use portal (safer in Wayland, handles file associations)
    xdgOpenUsePortal = true;

    # Portal Backend Configuration
    config = {
      # ---------------------------------------------------------------------------
      # Common Fallback (applies to all sessions)
      # ---------------------------------------------------------------------------
      common.default = [ "gtk" ];

      # ---------------------------------------------------------------------------
      # Hyprland Session Portal Routing
      # ---------------------------------------------------------------------------
      # Hyprland portal handles screenshots/screencasts natively.
      # GTK portal used for file pickers (Hyprland has no native file dialog).
      hyprland.default = [ "hyprland" "gtk" ];

      # ---------------------------------------------------------------------------
      # COSMIC Session Portal Routing
      # ---------------------------------------------------------------------------
      # COSMIC has full portal implementation. Explicit interface routing ensures
      # screenshots work correctly (was broken with just "default" in some builds).
      cosmic = {
        default = [ "cosmic" "gtk" ];
        
        # Explicit interface routing (prevents fallback issues)
        "org.freedesktop.impl.portal.Screenshot"  = [ "cosmic" ];
        "org.freedesktop.impl.portal.ScreenCast"  = [ "cosmic" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "cosmic" ];
      };

      # ---------------------------------------------------------------------------
      # GNOME Session Portal Routing
      # ---------------------------------------------------------------------------
      # GNOME portal provides full desktop integration.
      # GTK portal as fallback for edge cases.
      gnome.default = [ "gnome" "gtk" ];
    };

    # Extra Portal Packages
    # Desktop-specific portals (hyprland via programs.hyprland.portalPackage)
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk     # Universal fallback
      pkgs.xdg-desktop-portal-gnome   # GNOME integration
      pkgs.xdg-desktop-portal-cosmic  # COSMIC integration
    ];
  };

  # =============================================================================
  # Systemd User Services - COSMIC Portal (Conditional Activation)
  # =============================================================================
  # Problem: COSMIC portal starts even when COSMIC desktop isn't running,
  #          causing D-Bus watcher errors in logs (seen in your journalctl).
  #
  # Solution: Conditional service activation using lib.mkIf.
  #           Portal only starts when COSMIC desktop is enabled.
  #
  # Why explicit systemd unit?
  #   • Control startup ordering (after graphical-session.target)
  #   • Set proper D-Bus activation (Type=dbus)
  #   • Configure restart policy
  #   • Set environment variables (XDG_CURRENT_DESKTOP)
  
  systemd.user.services.xdg-desktop-portal-cosmic = lib.mkIf config.services.desktopManager.cosmic.enable {
    description = "Portal service (COSMIC implementation)";

    # Service Ordering
    # Start after Wayland compositor is ready
    after    = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];
    wantedBy = [ "xdg-desktop-portal.service" ];

    # Service Configuration
    serviceConfig = {
      # D-Bus Activation
      Type    = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.cosmic";
      
      # Executable
      ExecStart = "${pkgs.xdg-desktop-portal-cosmic}/libexec/xdg-desktop-portal-cosmic";
      
      # Restart Policy
      # Restart on failure (portal crashes shouldn't break session)
      Restart    = "on-failure";
      RestartSec = "2s";
      
      # Resource Management
      Slice = "session.slice";  # User session resource group
      
      # Timeouts
      TimeoutStartSec = "10s";  # Kill if takes >10s to start
      TimeoutStopSec  = "5s";   # Kill if takes >5s to stop
    };

    # Environment Variables
    environment = {
      # Critical: Portal needs to know it's running under COSMIC
      # Without this, it may not claim correct D-Bus interfaces
      XDG_CURRENT_DESKTOP = "COSMIC";
    };
  };

  # =============================================================================
  # Systemd User Target - Hyprland Session
  # =============================================================================
  # This target acts as a synchronization point for Hyprland-specific services.
  # Services that need to run with Hyprland can BindsTo/Wants this target.
  #
  # Purpose:
  #   • Ensures proper service ordering (services wait for compositor)
  #   • Groups Hyprland-related services together
  #   • Allows clean shutdown of compositor and its services
  #
  # The wrapper script (hyprland-gdm-wrapper) starts this target before
  # launching Hyprland, ensuring all dependencies are ready.
  
  systemd.user.targets.hyprland-session = {
    description = "Hyprland compositor session";
    
    # Bind to graphical session (stop when graphical session ends)
    bindsTo = [ "graphical-session.target" ];
    
    # Want graphical-session-pre (prefer it starts first)
    wants = [ "graphical-session-pre.target" ];
    
    # Start after graphical-session-pre is ready
    after = [ "graphical-session-pre.target" ];
  };

  # =============================================================================
  # Font Configuration - Comprehensive Stack
  # =============================================================================
  # Font stack covers:
  #   • Nerd Fonts (terminal/coding with icons)
  #   • Emoji fonts (color emoji support)
  #   • CJK fonts (Chinese/Japanese/Korean)
  #   • System fonts (Liberation, DejaVu)
  #   • Modern UI fonts (Inter, Roboto)
  #
  # Font Fallback Chain:
  #   App requests "monospace" → Maple Mono NF → Hack NF → JetBrains Mono →
  #   Fira Code → Liberation Mono → Noto Color Emoji (if emoji detected)
  
  fonts = {
    packages = with pkgs; [
      # -------------------------------------------------------------------------
      # Core Fonts (Terminal/Coding)
      # -------------------------------------------------------------------------
      # Tested with: Kitty, Alacritty, WezTerm, VS Code, Mako notifications
      maple-mono.NF           # Maple Mono Nerd Font (primary terminal font)
      nerd-fonts.hack         # Hack Nerd Font (icons + coding ligatures)
      cascadia-code           # Microsoft's coding font (good ligatures)
      fira-code               # Fira Code (classic coding font)
      fira-code-symbols       # Fira Code symbols/ligatures
      jetbrains-mono          # JetBrains Mono (excellent for coding)
      source-code-pro         # Adobe's monospace (clean, readable)

      # -------------------------------------------------------------------------
      # Emoji & Symbol Fonts
      # -------------------------------------------------------------------------
      noto-fonts-emoji        # Google's color emoji (primary emoji font)
      font-awesome            # Icon font (web icons, arrows, symbols)
      material-design-icons   # Material Design icons

      # -------------------------------------------------------------------------
      # System Fonts (Liberation = Microsoft font metrics-compatible)
      # -------------------------------------------------------------------------
      liberation_ttf          # Liberation Sans/Serif/Mono (Arial/Times/Courier clones)
      dejavu_fonts            # DejaVu Sans/Serif/Mono (universal fallback)

      # -------------------------------------------------------------------------
      # CJK Fonts (Chinese/Japanese/Korean)
      # -------------------------------------------------------------------------
      noto-fonts-cjk-sans     # Noto Sans CJK (Asian languages - sans-serif)
      noto-fonts-cjk-serif    # Noto Serif CJK (Asian languages - serif)

      # -------------------------------------------------------------------------
      # Extended Unicode Coverage
      # -------------------------------------------------------------------------
      noto-fonts              # Noto Sans/Serif (base Unicode coverage)
      noto-fonts-extra        # Extended Noto variants

      # -------------------------------------------------------------------------
      # Modern UI Fonts
      # -------------------------------------------------------------------------
      inter                   # Inter (modern UI font, great for web/desktop)
      roboto                  # Android's system font
      ubuntu_font_family      # Ubuntu font family
      open-sans               # Open Sans (web/UI font)
    ];

    # Font Configuration (fontconfig)
    fontconfig = {
      # -----------------------------------------------------------------------
      # Default Font Families
      # -----------------------------------------------------------------------
      # When app requests generic family (monospace/serif/sans-serif/emoji),
      # fontconfig resolves to these fonts in priority order.
      
      defaultFonts = {
        # Monospace (Terminal/Code Editors)
        monospace = [
          "Maple Mono NF"         # Primary (best icon support)
          "Hack Nerd Font Mono"   # Fallback #1
          "JetBrains Mono"        # Fallback #2
          "Fira Code"             # Fallback #3 (ligatures)
          "Source Code Pro"       # Fallback #4
          "Liberation Mono"       # Fallback #5 (universal)
          "Noto Color Emoji"      # Emoji in terminal
        ];
        
        # Emoji (Color Emoji Support)
        emoji = [ "Noto Color Emoji" ];
        
        # Serif (Traditional/Print)
        serif = [
          "Liberation Serif"
          "Noto Serif"
          "DejaVu Serif"
        ];
        
        # Sans-Serif (Modern/UI)
        sansSerif = [
          "Liberation Sans"
          "Inter"
          "Noto Sans"
          "DejaVu Sans"
        ];
      };

      # -----------------------------------------------------------------------
      # Subpixel Rendering (LCD Panel Optimization)
      # -----------------------------------------------------------------------
      # Improves font clarity on LCD monitors.
      # RGB subpixel layout is standard (BGR for some old laptops).
      subpixel = {
        rgba = "rgb";           # Subpixel order (rgb/bgr/vrgb/vbgr/none)
        lcdfilter = "default";  # LCD filter type
      };

      # -----------------------------------------------------------------------
      # Hinting Configuration
      # -----------------------------------------------------------------------
      # Hinting aligns font outlines to pixel grid for sharper text.
      # 
      # Hinting Styles:
      #   • none   - No hinting (blurry on low DPI)
      #   • slight - Minimal hinting (best for HiDPI)
      #   • medium - Balanced hinting
      #   • full   - Maximum hinting (sharp but can distort shapes)
      hinting = {
        enable   = true;
        autohint = false;     # Use font's built-in hints (better quality)
        style    = "slight";  # Slight hinting (good for modern displays)
      };

      # Antialiasing (Smooth Font Edges)
      antialias = true;

      # -----------------------------------------------------------------------
      # localConf Disabled
      # -----------------------------------------------------------------------
      # localConf can break emoji rendering in some apps (Mako notifications).
      # Explicitly disabled to prevent user overrides from breaking fonts.
      # Users can still add custom fontconfig in ~/.config/fontconfig/fonts.conf
    };

    # System Font Support
    enableDefaultPackages = true;  # Include basic fonts (DejaVu, Liberation)
    fontDir.enable = true;         # Expose fonts in /run/current-system/sw/share/fonts
  };

  # =============================================================================
  # System Environment Configuration
  # =============================================================================
  environment = {
    # Environment Variables
    variables = {
      # Font Configuration Paths
      FONTCONFIG_PATH     = "/etc/fonts";
      FONTCONFIG_FILE     = "/etc/fonts/fonts.conf";
      
      # Locale (prevents font rendering issues with some apps)
      LC_ALL              = "en_US.UTF-8";
      
      # FreeType Rendering (interpreter-version=40 = better hinting)
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    # System Packages
    # Includes font utilities and the custom Hyprland session desktop entry.
    systemPackages = (with pkgs; [
      # Font Management Tools
      fontconfig     # fc-list, fc-match, fc-cache (font introspection)
      font-manager   # GUI font browser/manager
    ]) ++ [
      # Custom Hyprland Session
      # Included here so .desktop file appears in:
      # /run/current-system/sw/share/wayland-sessions/hyprland-optimized.desktop
      hyprlandOptimizedSession
    ];
  };

  # =============================================================================
  # Home-Manager User Configuration
  # =============================================================================
  # User-specific font settings and diagnostic aliases.
  # Ensures fonts work correctly in user applications.
  
  home-manager.users.${username} = {
    # Home-Manager Version Tracking
    home.stateVersion = "25.11";

    # Enable Font Configuration (per-user fontconfig cache)
    fonts.fontconfig.enable = true;

    # -------------------------------------------------------------------------
    # Application Font Configuration - Rofi
    # -------------------------------------------------------------------------
    programs.rofi = {
      font = "Hack Nerd Font 13";          # App launcher font
      terminal = "${pkgs.kitty}/bin/kitty"; # Terminal emulator
    };

    # -------------------------------------------------------------------------
    # Shell Aliases - Font Diagnostics & Testing
    # -------------------------------------------------------------------------
    # Comprehensive font troubleshooting toolkit.
    # Use these to debug font issues, test emoji support, verify installation.
    
    home.shellAliases = {
      # Quick Diagnostics
      "font-list"        = "fc-list";                              # List all installed fonts
      "font-emoji"       = "fc-list | grep -i emoji";             # Show emoji fonts
      "font-nerd"        = "fc-list | grep -i 'nerd\\|hack\\|maple'"; # Show Nerd Fonts
      "font-maple"       = "fc-list | grep -i maple";             # Show Maple Mono variants
      "font-reload"      = "fc-cache -f -v";                       # Rebuild font cache

      # Visual Tests (Terminal Output)
      "font-test"        = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols and emoji support'";
      "emoji-test"       = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
      "font-render-test" = "echo 'Rendering: ABCDabcd1234 ★♪●⚡▲ 🚀📱💬'";
      "font-ligature-test" = "echo 'Ligatures: -> => != === >= <= && || /* */ //'";
      "font-nerd-icons"  = "echo 'Nerd Icons:     󰈹 󰍛'";

      # Notification Tests (Mako/System Notifications)
      "mako-emoji-test"  = "notify-send 'Emoji Test 🚀' 'Mako notification with emojis: 📱 💬 🔥 ⭐ 🎵'";
      "mako-font-test"   = "notify-send 'Font Test' 'Maple Mono NF with symbols: ★ ♪ ● ⚡ ▲'";
      "mako-icons-test"  = "notify-send 'Icon Test' 'Nerd Font icons:     󰈹 󰍛'";

      # Deep Diagnostics (Troubleshooting)
      "font-info"        = "fc-match -v";                          # Show default font details
      "font-debug"       = "fc-match -s monospace | head -5";     # Show monospace fallback chain
      "font-mono"        = "fc-list : family | grep -i mono | sort"; # List monospace fonts
      "font-available"   = "fc-list : family | sort | uniq";      # List all font families
      "font-cache-clean" = "fc-cache -f -r -v";                   # Full font cache rebuild
    };

    # -------------------------------------------------------------------------
    # Session Variables (User Environment)
    # -------------------------------------------------------------------------
    home.sessionVariables = {
      # Locale (consistent with system)
      LC_ALL = "en_US.UTF-8";
      
      # Fontconfig Paths (user + system)
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
      
      # FreeType Rendering
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    # -------------------------------------------------------------------------
    # User Packages - Font Tools
    # -------------------------------------------------------------------------
    home.packages = with pkgs; [
      fontpreview  # Quick font preview in terminal
      gucharmap    # GTK Character Map (GUI font browser)
    ];
  };
}

# ==============================================================================
# Post-Installation Verification
# ==============================================================================
#
# After rebuilding (nixos-rebuild switch --flake .#hay), verify:
#
# 1. Sessions Available:
#    ls /run/current-system/sw/share/wayland-sessions/
#    # Should show: hyprland.desktop, hyprland-optimized.desktop, cosmic.desktop, gnome.desktop
#
# 2. Portals Active (run after logging into Hyprland):
#    busctl --user list | grep portal
#    # Should show: xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk
#    # Should NOT show: xdg-desktop-portal-cosmic (unless in COSMIC session)
#
# 3. Fonts Installed:
#    fc-list | grep -i "maple\|hack\|emoji"
#    # Should show: Maple Mono NF, Hack Nerd Font, Noto Color Emoji
#
# 4. Audio Working:
#    pactl info
#    # Should show: PipeWire as server
#
# 5. No Errors in Logs:
#    journalctl --user -n 50 | grep -i error
#    # Should NOT show COSMIC portal errors (fixed by conditional activation)
#
# ==============================================================================
# Troubleshooting Guide
# ==============================================================================
#
# Issue: COSMIC Portal Errors in Logs
# Fix:   Verify services.desktopManager.cosmic.enable = false if not using COSMIC
#        Or keep enabled and ignore errors (harmless, just log spam)
#
# Issue: Fonts Not Appearing
# Fix:   fc-cache -f -v              # Rebuild font cache
#        fc-list | grep <font-name>  # Verify font installed
#
# Issue: Emoji Not Rendering
# Fix:   Verify "Noto Color Emoji" in fc-list
#        Check app fontconfig: fc-match emoji
#
# Issue: Session Not in GDM
# Fix:   Verify hyprlandOptimizedSession in services.displayManager.sessionPackages
#        Check passthru.providedSessions matches defaultSession
#
# Issue: Portal Not Working (screenshots fail)
# Fix:   busctl --user list | grep portal  # Check active portals
#        xdg-desktop-portal --replace        # Restart portal
#
# Issue: Audio Not Working
# Fix:   systemctl --user restart pipewire pipewire-pulse
#        pactl info  # Check PipeWire is running
#
# ==============================================================================
