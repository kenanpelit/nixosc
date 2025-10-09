# modules/core/display/default.nix
# ==============================================================================
# Display & Desktop Environment Module
# ==============================================================================
#
# Module: modules/core/display
# Author: Kenan Pelit
# Date:   2025-10-04
#
# Purpose: Unified management of display, audio, fonts, and desktop portals
# 
# Why Single File?
#   - Consolidates scattered desktop settings (display, portal, fonts, audio)
#   - Eliminates "where was that setting?" searches
#   - Prevents common conflicts when running GNOME + Hyprland + COSMIC side-by-side
#
# Design Principles:
#
#   1. Desktop-Specific Portal Strategy
#      - Each desktop uses its own portal implementation
#      - COSMIC portal for COSMIC sessions with screenshot support
#      - Hyprland portal for Hyprland sessions
#      - GNOME portal for GNOME sessions
#      - GTK portal as universal fallback
#
#   2. Xorg Compatibility Layer
#      - GNOME + Hyprland + COSMIC primarily use Wayland
#      - Xorg enabled only as fallback for legacy applications
#
#   3. PipeWire Central Audio Stack
#      - ALSA/Pulse compatibility through PipeWire
#      - JACK disabled by default (enable if needed)
#      - rtkit in security module handles latency/priorities
#
#   4. Conservative Fontconfig
#      - Let apps choose their sans/serif preferences
#      - Explicitly manage monospace and emoji fonts
#      - No localConf to avoid Mako emoji conflicts
#
#   5. Living Documentation
#      - Each block has WHY/HOW explanations
#      - Quick decision support (e.g., enabling JACK, changing portals)
#
#   6. Multi-Desktop Support
#      - GNOME: Traditional desktop with Wayland
#      - Hyprland: Tiling compositor for power users with custom optimizations
#      - COSMIC: Next-gen Rust-based desktop (Beta - from nixpkgs)
#
#   7. Session Selection Strategy
#      - GDM provides graphical session selection with proper XDG discovery
#      - TTY2: Direct hyprland_tty launch with full optimizations
#      - Both methods supported - user can choose workflow preference
#
# Conflict Prevention:
#   - Hyprland portal via programs.hyprland.portalPackage (no duplication)
#   - COSMIC portal automatically provided by services.desktopManager.cosmic
#   - GNOME keyring here; PAM/Security in security module
#   - Font env vars identical in system and home-manager layers
#
# Module Consolidation:
#   - Replaces: ./fonts, ./xdg, ./audio modules
#   - Single import: ./display in modules/core/default.nix
#
# ==============================================================================

{ username, inputs, pkgs, lib, ... }:

let
  # Hyprland packages from flake input
  # Locked versions ensure portal compatibility
  hyprlandPkg = inputs.hyprland.packages.${pkgs.system}.default;
  hyprPortal  = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  
  # COSMIC packages from nixpkgs unstable
  # COSMIC portal is automatically provided by services.desktopManager.cosmic
in
{
  # ============================================================================
  # Wayland Compositor - Hyprland
  # ============================================================================
  # Modern Wayland compositor with proper portal integration.
  # Critical for screen sharing and xdg-open when running alongside GNOME.
  
  programs.hyprland = {
    enable = true;
    package = hyprlandPkg;
    portalPackage = hyprPortal;  # Portal defined HERE - don't add to extraPortals
  };

  # ============================================================================
  # Display Stack Configuration
  # ============================================================================
  
  services = {
    # --------------------------------------------------------------------------
    # X11 Server (Legacy Compatibility)
    # --------------------------------------------------------------------------
    xserver = {
      enable = true;
      xkb = {
        layout = "tr";              # Turkish layout
        variant = "f";              # TR-F variant
        options = "ctrl:nocaps";    # Caps Lock → Control (ergonomics)
      };
    };

    # --------------------------------------------------------------------------
    # Display Manager - GDM (GNOME Display Manager)
    # --------------------------------------------------------------------------
    # GDM provides robust session selection with full XDG portal support
    # Automatically discovers sessions from:
    #   - services.displayManager.sessionPackages (custom sessions)
    #   - /run/current-system/sw/share/wayland-sessions/ (system packages)
    #   - /etc/wayland-sessions/ (fallback)
    #
    # Why GDM over cosmic-greeter?
    #   - Mature, well-tested with comprehensive session discovery
    #   - Proper XDG standards compliance (crucial for custom sessions)
    #   - Better integration with GNOME components (keyring, portals)
    #   - Reliable multi-session support (GNOME + Hyprland + COSMIC)
    #
    # Note: cosmic-greeter currently only scans system package paths,
    # missing custom sessions defined via sessionPackages or environment.etc
    
    displayManager = {
        # --------------------------------------------------------------------------
        # Custom Session Packages
        # --------------------------------------------------------------------------
        # Register custom desktop sessions with display manager
        # This makes sessions discoverable by GDM and other display managers
        # CRITICAL: This is the proper NixOS way to add custom sessions
        
        sessionPackages = [
          # Custom Hyprland Optimized session
          (pkgs.writeTextFile rec {
            name = "hyprland-optimized-session";
            destination = "/share/wayland-sessions/hyprland-optimized.desktop";
            text = ''
              [Desktop Entry]
              Name=Hyprland (Optimized)
              Comment=Hyprland with Intel Arc optimizations and Catppuccin theme support
              Exec=hyprland_tty
              Type=Application
              DesktopNames=Hyprland
              Keywords=wayland;wm;tiling;catppuccin;
            '';
            
            # CRITICAL: providedSessions tells NixOS which session names this package provides
            passthru.providedSessions = [ "hyprland-optimized" ];
          })

          # GNOME Optimized session
          (pkgs.writeTextFile rec {
            name = "gnome-optimized-session";
            destination = "/share/wayland-sessions/gnome-optimized.desktop";
            text = ''
              [Desktop Entry]
              Name=GNOME (Optimized)
              Comment=GNOME with Catppuccin theme and performance optimizations
              Exec=gnome_tty
              Type=Application
              DesktopNames=GNOME
              X-GDM-SessionRegisters=true
              X-GDM-SessionType=wayland
            '';
            passthru.providedSessions = [ "gnome-optimized" ];
          })
        ];
        
        # --------------------------------------------------------------------------
        # GDM Configuration
        # --------------------------------------------------------------------------
        
        gdm = {
            enable = true;
            wayland = true;             # Wayland-first approach
            autoSuspend = false;        # Prevent auto-suspend on login screen
        };
        
        # Default session selection
        # Available options: "hyprland", "hyprland-optimized", "cosmic", "gnome"
        # "hyprland-optimized" uses hyprland_tty script with Intel Arc optimizations
        defaultSession = "hyprland-optimized";
        
        # Security: no auto-login
        autoLogin.enable = false;
    };

    # --------------------------------------------------------------------------
    # Desktop Environments
    # --------------------------------------------------------------------------
    # Multiple desktops enabled for flexibility
    # User can select at login screen
    
    desktopManager = {
      gnome.enable = true;          # GNOME - Traditional desktop
      cosmic.enable = true;         # COSMIC - Rust-based desktop (Beta)
    };

    # --------------------------------------------------------------------------
    # Input Management
    # --------------------------------------------------------------------------
    libinput.enable = true;         # Modern input device handling

    # --------------------------------------------------------------------------
    # Session Security - Keyring
    # --------------------------------------------------------------------------
    gnome.gnome-keyring.enable = true;  # Session secrets management

    # --------------------------------------------------------------------------
    # Audio Stack - PipeWire
    # --------------------------------------------------------------------------
    # Modern audio/video server with broad compatibility
    
    pipewire = {
      enable = true;
      
      # ALSA support (native + 32-bit for games)
      alsa.enable = true;
      alsa.support32Bit = true;
      
      # PulseAudio compatibility layer
      pulse.enable = true;
      
      # JACK disabled (enable for DAW/studio use)
      jack.enable = false;
    };

    # --------------------------------------------------------------------------
    # D-Bus Configuration - Portal Support
    # --------------------------------------------------------------------------
    # Ensure portal packages are registered with D-Bus
    dbus = {
      enable = true;
      packages = with pkgs; [ 
        xdg-desktop-portal 
        xdg-desktop-portal-cosmic
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };
  };

  # ============================================================================
  # XDG Desktop Portals
  # ============================================================================
  # Portal routing ensures applications use the correct backend for
  # screen sharing, file selection, and external link handling.
  # Each desktop environment gets its optimal portal configuration.
  #
  # CRITICAL: COSMIC screenshot fix
  # The cosmic portal must be explicitly set for Screenshot and ScreenCast
  # interfaces to make cosmic-screenshot work properly.
  #
  # NOTE: COSMIC portal is automatically provided by services.desktopManager.cosmic
  # Hyprland portal is provided by programs.hyprland.portalPackage
  
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;  # Route xdg-open through portal (Wayland-safe)

    # Portal priority configuration per desktop session
    # Format: desktop_name.interface = [ "preferred_impl" "fallback_impl" ];
    config = {
      # Common fallback for all desktops
      common.default = [ "gtk" ];
      
      # Hyprland session - uses hyprland portal with gtk fallback
      hyprland.default = [ "gtk" "hyprland" ];
      
      # COSMIC session - uses cosmic portal with explicit screenshot support
      cosmic = {
        default = [ "cosmic" "gtk" ];
        # CRITICAL: These lines fix cosmic-screenshot
        "org.freedesktop.impl.portal.Screenshot" = [ "cosmic" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "cosmic" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "cosmic" ];
      };
      
      # GNOME session - uses gnome portal with gtk fallback
      gnome.default = [ "gnome" "gtk" ];
    };

    # GTK and GNOME portals explicitly added
    # Desktop-specific portals (cosmic, hyprland) are provided by their respective modules
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk 
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-cosmic 
    ];
  };

  # ============================================================================
  # Systemd User Services - COSMIC Portal (FIXED)
  # ============================================================================
  # Fixed service definition with proper dependencies
  # Key changes:
  # - after = graphical-session.target (wait for Wayland)
  # - Removed 'before' directive (was creating circular dependency)
  # - Added RestartSec for stability
  
  systemd.user.services.xdg-desktop-portal-cosmic = {
    description = "Portal service (COSMIC implementation)";
    
    # Wait for graphical session to be ready (Wayland display available)
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "xdg-desktop-portal.service" ];
    
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.cosmic";
      ExecStart = "${pkgs.xdg-desktop-portal-cosmic}/libexec/xdg-desktop-portal-cosmic";
      Restart = "on-failure";
      RestartSec = "2s";           # Wait 2 seconds before restart
      Slice = "session.slice";
      
      # Timeout configuration
      TimeoutStartSec = "30s";     # Give portal 30 seconds to start
      TimeoutStopSec = "10s";      # 10 seconds to stop gracefully
    };
    
    environment = {
      # Ensure portal knows it's running in COSMIC
      XDG_CURRENT_DESKTOP = "COSMIC";
    };
  };

  # ============================================================================
  # Wayland Session Files - Desktop Entry Definitions
  # ============================================================================
  # Session registration strategy:
  #   1. hyprland-optimized: Registered via services.displayManager.sessionPackages
  #      (This is the proper NixOS way and ensures GDM discovery)
  #   2. Other sessions: Defined here in environment.etc for compatibility
  #
  # Why both methods?
  #   - sessionPackages is the official NixOS method (GDM sees it)
  #   - environment.etc provides fallback and documentation
  #   - TTY2 can use these files directly without display manager
  #
  # Session File Strategy:
  #   - Standard sessions (GNOME, COSMIC): Use desktop environment defaults
  #   - Optimized Hyprland: Uses hyprland_tty script with custom setup
  #   - All sessions properly set XDG_CURRENT_DESKTOP for portal routing
  #
  # Why Two Hyprland Entries?
  #   1. "Hyprland" - Standard launch via Hyprland binary
  #      - Quick, minimal setup
  #      - Uses default Hyprland configuration
  #      - Good for testing or fallback
  #
  #   2. "Hyprland (Optimized)" - Launch via hyprland_tty script
  #      - Full Intel Arc Graphics optimizations
  #      - Dynamic Catppuccin theme support
  #      - Advanced logging and error handling
  #      - Proper systemd/D-Bus integration
  #      - Recommended for daily use
  #
  # Choosing at Login:
  #   - GDM will show all available sessions
  #   - Select "Hyprland (Optimized)" for best experience
  #   - Standard "Hyprland" available as fallback
  #
  # TTY2 Direct Launch:
  #   - zsh_profile.nix already configured for TTY2
  #   - Runs hyprland_tty automatically
  #   - Bypasses display manager completely
  #   - Useful for debugging or minimal boot
  
  environment.etc = {
    # --------------------------------------------------------------------------
    # GNOME Session
    # --------------------------------------------------------------------------
    # Traditional GNOME desktop with Wayland support
    
    "wayland-sessions/gnome.desktop".text = ''
      [Desktop Entry]
      Name=GNOME
      Comment=This session logs you into GNOME
      Exec=gnome-session
      Type=Application
      DesktopNames=GNOME
    '';

    "xdg/gnome-session/sessions/gnome.session".text = ''
      [GNOME Session]
      Name=GNOME
      RequiredComponents=org.gnome.Shell;org.gnome.SettingsDaemon.A11ySettings;org.gnome.SettingsDaemon.Color;org.gnome.SettingsDaemon.Datetime;org.gnome.SettingsDaemon.Housekeeping;org.gnome.SettingsDaemon.Keyboard;org.gnome.SettingsDaemon.MediaKeys;org.gnome.SettingsDaemon.Power;org.gnome.SettingsDaemon.PrintNotifications;org.gnome.SettingsDaemon.Rfkill;org.gnome.SettingsDaemon.ScreensaverProxy;org.gnome.SettingsDaemon.Sharing;org.gnome.SettingsDaemon.Smartcard;org.gnome.SettingsDaemon.Sound;org.gnome.SettingsDaemon.UsbProtection;org.gnome.SettingsDaemon.Wacom;org.gnome.SettingsDaemon.XSettings;
    '';

    # --------------------------------------------------------------------------
    # GNOME Session (Optimized) - Fallback Definition
    # --------------------------------------------------------------------------
    # Optimized GNOME launch with gnome_tty script
    # Features: Catppuccin theme support, custom optimizations

    "wayland-sessions/gnome-optimized.desktop".text = ''
      [Desktop Entry]
      Name=GNOME (Optimized)
      Comment=GNOME with Catppuccin theme and performance optimizations
      Exec=${pkgs.writeShellScript "gnome-optimized-wrapper" ''
        #!/usr/bin/env bash
    
        # GDM tarafından sağlanan environment'ı koru
        export XDG_SESSION_TYPE=wayland
        export XDG_SESSION_DESKTOP=gnome
        export XDG_CURRENT_DESKTOP=GNOME
        export DESKTOP_SESSION=gnome
    
        # D-Bus session kontrolü (GDM zaten sağlıyor)
        if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
            eval $(dbus-launch --sh-syntax --exit-with-session)
        fi
    
        # gnome_tty betiğini çağır (ya da doğrudan gnome-session)
        exec gnome_tty
      ''}
      Type=Application
      DesktopNames=GNOME
      X-GDM-SessionRegisters=true
      X-GDM-SessionType=wayland
    '';
   
    # --------------------------------------------------------------------------
    # Hyprland Session (Standard)
    # --------------------------------------------------------------------------
    # Direct Hyprland launch without custom script
    # Use this for: testing, debugging, fallback
    # Note: programs.hyprland.enable already provides a default session file,
    # but we define it explicitly here for consistency and documentation
    
    "wayland-sessions/hyprland.desktop".text = ''
      [Desktop Entry]
      Name=Hyprland
      Comment=Hyprland Wayland compositor (standard launch)
      Exec=Hyprland
      Type=Application
      DesktopNames=Hyprland
    '';

    # --------------------------------------------------------------------------
    # Hyprland Session (Optimized) - Fallback Definition
    # --------------------------------------------------------------------------
    # This is a fallback/documentation copy
    # The actual registration is done via services.displayManager.sessionPackages
    # Keeping this here ensures:
    #   - TTY2 direct launch can find it
    #   - Documentation is in one place
    #   - Fallback if sessionPackages has issues
    #
    # Features enabled by hyprland_tty:
    #   - Intel Arc Graphics compatibility (WLR_DRM_NO_ATOMIC, etc.)
    #   - Dynamic Catppuccin theme support (CATPPUCCIN_FLAVOR/ACCENT)
    #   - Enhanced logging (rotation, debug modes)
    #   - Proper systemd user session integration
    #   - Turkish F-keyboard layout
    #   - Comprehensive environment variable setup
    #
    # Theme Selection:
    #   Set before login or in ~/.zshrc:
    #     export CATPPUCCIN_FLAVOR=mocha    # latte, frappe, macchiato, mocha
    #     export CATPPUCCIN_ACCENT=mauve    # rosewater, flamingo, pink, mauve, etc.
    #
    # Debug Mode:
    #   From TTY: hyprland_tty -d
    #   From DM: Not available (use TTY2 for debugging)
    
    "wayland-sessions/hyprland-optimized.desktop".text = ''
      [Desktop Entry]
      Name=Hyprland (Optimized)
      Comment=Hyprland with Intel Arc optimizations and Catppuccin theme support
      Exec=hyprland_tty
      Type=Application
      DesktopNames=Hyprland
      Keywords=wayland;wm;tiling;catppuccin;
    '';
  };

  # ============================================================================
  # Font Configuration
  # ============================================================================
  # Strategy: Monospace & Emoji first, comprehensive Unicode coverage
  
  fonts = {
    packages = with pkgs; [
      # Core fonts (tested with Mako notifications)
      maple-mono.NF
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      cascadia-code
      inter
      font-awesome
      
      # Extended coverage
      source-code-pro
      dejavu_fonts
      noto-fonts-cjk-serif
      noto-fonts-extra
      material-design-icons
      
      # Modern favorites
      jetbrains-mono
      ubuntu_font_family
      roboto
      open-sans
    ];

    fontconfig = {
      # Font priorities by category
      defaultFonts = {
        monospace = [
          "Maple Mono NF"
          "Hack Nerd Font Mono"
          "JetBrains Mono"
          "Fira Code"
          "Source Code Pro"
          "Liberation Mono"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
        serif = [ "Liberation Serif" "Noto Serif" "DejaVu Serif" ];
        sansSerif = [ "Liberation Sans" "Inter" "Noto Sans" "DejaVu Sans" ];
      };

      # Subpixel rendering for LCD panels
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      # Hinting configuration
      hinting = {
        enable = true;
        autohint = false;     # Use font's built-in hints
        style = "slight";     # Best for modern displays
      };

      antialias = true;
      # localConf disabled - can break Mako emoji rendering
    };

    enableDefaultPackages = true;
    fontDir.enable = true;
  };

  # ============================================================================
  # System Environment Variables
  # ============================================================================
  # Font-related environment variables for consistency and debugging
  
  environment = {
    variables = {
      FONTCONFIG_PATH = "/etc/fonts";
      LC_ALL = "en_US.UTF-8";
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      FONTCONFIG_FILE = "/etc/fonts/fonts.conf";
    };

    systemPackages = with pkgs; [
      fontconfig      # Font utilities (fc-list, fc-match)
      font-manager    # GUI font browser
    ];
  };

  # ============================================================================
  # Home-Manager User Configuration
  # ============================================================================
  # User-specific font settings and diagnostic tools
  
  home-manager.users.${username} = {
    home.stateVersion = "25.11";
    
    fonts.fontconfig.enable = true;

    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    # Diagnostic and testing aliases
    home.shellAliases = {
      # Quick diagnostics
      "font-list"        = "fc-list";
      "font-emoji"       = "fc-list | grep -i emoji";
      "font-nerd"        = "fc-list | grep -i 'nerd\\|hack\\|maple'";
      "font-maple"       = "fc-list | grep -i maple";
      "font-reload"      = "fc-cache -f -v";

      # Visual tests
      "font-test"        = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols and emoji support'";
      "emoji-test"       = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
      "mako-emoji-test"  = "notify-send 'Emoji Test 🚀' 'Mako notification with emojis: 📱 💬 🔥 ⭐ 🎵'";
      "mako-font-test"   = "notify-send 'Font Test' 'Maple Mono NF with symbols: ★ ♪ ● ⚡ ▲'";
      "mako-icons-test"  = "notify-send 'Icon Test' 'Nerd Font icons:     󰈹 󰍛'";

      # Deep diagnostics
      "font-info"        = "fc-match -v";
      "font-debug"       = "fc-match -s monospace | head -5";
      "font-mono"        = "fc-list : family | grep -i mono | sort";
      "font-available"   = "fc-list : family | sort | uniq";
      "font-cache-clean" = "fc-cache -f -r -v";
      "font-render-test" = "echo 'Rendering Test: ABCDabcd1234 ★♪●⚡▲ 🚀📱💬'";
      "font-ligature-test" = "echo 'Ligature Test: -> => != === >= <= && || /* */ //'";
      "font-nerd-icons"  = "echo 'Nerd Icons:     󰈹 󰍛'";
    };

    # Session variables (mirror system for consistency)
    home.sessionVariables = {
      LC_ALL = "en_US.UTF-8";
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
    };

    # Font utilities
    home.packages = with pkgs; [
      fontpreview    # Preview fonts quickly
      gucharmap      # Character map GUI
    ];
  };
}

