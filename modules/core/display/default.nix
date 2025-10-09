# ==============================================================================
# Display & Desktop Environment Module
# ==============================================================================
#
# Module: modules/core/display
# Author: Kenan Pelit
# Date:   2025-10-09
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
#   2. Wayland-First Architecture
#      - GNOME + Hyprland + COSMIC primarily use Wayland
#      - Xorg enabled only as fallback for legacy applications
#
#   3. PipeWire Central Audio Stack
#      - ALSA/Pulse compatibility through PipeWire
#      - JACK disabled by default (enable if needed for DAW/studio work)
#      - rtkit in security module handles latency/priorities
#
#   4. Conservative Fontconfig
#      - Explicit monospace and emoji font management
#      - Comprehensive Unicode coverage (CJK, emoji, symbols)
#      - Subpixel rendering optimized for modern LCD panels
#
#   5. Living Documentation
#      - Each block has WHY/HOW explanations
#      - Quick decision support for enabling features
#
#   6. Multi-Desktop Support
#      - GNOME: Traditional desktop with Wayland
#      - Hyprland: Tiling compositor with custom optimizations
#      - COSMIC: Next-gen Rust-based desktop (nixpkgs stable)
#
#   7. Session Selection Strategy
#      - GDM provides graphical session selection with XDG discovery
#      - TTY2: Direct hyprland_tty launch with full optimizations
#      - Both methods supported - user chooses workflow preference
#
# Conflict Prevention:
#   - Hyprland portal via programs.hyprland.portalPackage (no duplication)
#   - COSMIC portal automatically provided by services.desktopManager.cosmic
#   - Font env vars identical across system and home-manager
#   - Session files registered via sessionPackages (no manual XDG files)
#
# Module Consolidation:
#   - Replaces: separate fonts, xdg, audio modules
#   - Single import: ./display in modules/core/default.nix
#
# ==============================================================================

{ username, inputs, pkgs, lib, ... }:

let
  # Hyprland packages from flake input
  # Locked versions ensure portal compatibility
  hyprlandPkg = inputs.hyprland.packages.${pkgs.system}.default;
  hyprPortal  = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
in
{
  # ============================================================================
  # Wayland Compositor - Hyprland
  # ============================================================================
  # Modern Wayland compositor with proper portal integration
  # Critical for screen sharing and xdg-open when running alongside GNOME
  
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
    # Provides Xwayland for legacy X11 applications
    # Most apps now support Wayland natively
    
    xserver = {
      enable = true;
      xkb = {
        layout = "tr";              # Turkish layout
        variant = "f";              # TR-F variant (ergonomic)
        options = "ctrl:nocaps";    # Caps Lock → Control
      };
    };

    # --------------------------------------------------------------------------
    # Display Manager - GDM
    # --------------------------------------------------------------------------
    # GDM provides robust session selection with full XDG portal support
    # Automatically discovers sessions from:
    #   - services.displayManager.sessionPackages (custom sessions)
    #   - /run/current-system/sw/share/wayland-sessions/ (system packages)
    #   - Desktop environment defaults (GNOME, COSMIC)
    #
    # Why GDM over cosmic-greeter?
    #   - Mature, well-tested with comprehensive session discovery
    #   - Proper XDG standards compliance (crucial for custom sessions)
    #   - Better integration with GNOME components (keyring, portals)
    #   - Reliable multi-session support
    
    displayManager = {
      # ------------------------------------------------------------------------
      # Custom Session Packages
      # ------------------------------------------------------------------------
      # Register custom desktop sessions with display manager
      # This is the ONLY place sessions should be defined (no manual XDG files)
      
      sessionPackages = [
        # Hyprland Optimized session with Intel Arc optimizations
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
          
          # CRITICAL: providedSessions tells NixOS which session names this provides
          passthru.providedSessions = [ "hyprland-optimized" ];
        })

        # GNOME Optimized session with Catppuccin theme
        (pkgs.writeTextFile rec {
          name = "gnome-optimized-session";
          destination = "/share/wayland-sessions/gnome-optimized.desktop";
          text = ''
            [Desktop Entry]
            Name=GNOME (Optimized)
            Comment=GNOME with Catppuccin theme and performance optimizations
            Exec=gnome-session
            Type=Application
            DesktopNames=GNOME
            X-GDM-SessionRegisters=true
          '';
          passthru.providedSessions = [ "gnome-optimized" ];
        })
      ];
      
      # ------------------------------------------------------------------------
      # GDM Configuration
      # ------------------------------------------------------------------------
      
      gdm = {
        enable = true;
        wayland = true;             # Wayland-first approach
        autoSuspend = false;        # Prevent auto-suspend on login screen
      };
      
      # Default session selection
      # Options: "hyprland-optimized", "hyprland", "cosmic", "gnome", "gnome-optimized"
      defaultSession = "hyprland-optimized";
      
      # Security: no auto-login
      autoLogin.enable = false;
    };

    # --------------------------------------------------------------------------
    # Desktop Environments
    # --------------------------------------------------------------------------
    # Multiple desktops for flexibility - user selects at login
    
    desktopManager = {
      gnome.enable = true;          # Traditional GNOME desktop
      cosmic.enable = true;         # COSMIC desktop (Rust-based)
    };

    # --------------------------------------------------------------------------
    # Input Management
    # --------------------------------------------------------------------------
    libinput.enable = true;         # Modern input device handling

    # --------------------------------------------------------------------------
    # Session Security - GNOME Keyring
    # --------------------------------------------------------------------------
    # Manages session secrets (SSH keys, passwords, certificates)
    # PAM integration handled in security module
    
    gnome.gnome-keyring.enable = true;

    # --------------------------------------------------------------------------
    # Audio Stack - PipeWire
    # --------------------------------------------------------------------------
    # Modern audio/video server with broad compatibility
    # Replaces PulseAudio and provides JACK compatibility
    
    pipewire = {
      enable = true;
      
      # ALSA support (native + 32-bit for games)
      alsa.enable = true;
      alsa.support32Bit = true;
      
      # PulseAudio compatibility layer
      pulse.enable = true;
      
      # JACK support (disabled by default)
      # Enable for: DAW, audio production, low-latency recording
      jack.enable = false;
    };
  };

  # ============================================================================
  # XDG Desktop Portals
  # ============================================================================
  # Portal routing ensures applications use correct backend for:
  #   - Screen sharing (ScreenCast)
  #   - Screenshots (Screenshot)
  #   - File selection (FileChooser)
  #   - External links (OpenURI)
  #
  # Each desktop environment gets its optimal portal configuration
  #
  # CRITICAL: COSMIC screenshot fix
  # The cosmic portal must be explicitly set for Screenshot and ScreenCast
  # interfaces to make cosmic-screenshot work properly
  #
  # NOTE: Portal sources:
  #   - Hyprland: programs.hyprland.portalPackage
  #   - COSMIC: services.desktopManager.cosmic (automatic)
  #   - GNOME/GTK: extraPortals (explicit)
  
  xdg.portal = {
    enable = true;
    
    # Route xdg-open through portal (Wayland-safe external link handling)
    xdgOpenUsePortal = true;

    # Portal priority configuration per desktop session
    # Format: desktop_name.interface = [ "preferred_impl" "fallback_impl" ];
    config = {
      # Common fallback for all desktops
      common.default = [ "gtk" ];
      
      # Hyprland session - hyprland portal with gtk fallback
      hyprland.default = [ "hyprland" "gtk" ];
      
      # COSMIC session - cosmic portal with explicit interface routing
      cosmic = {
        default = [ "cosmic" "gtk" ];
        
        # CRITICAL: These lines fix cosmic-screenshot
        "org.freedesktop.impl.portal.Screenshot" = [ "cosmic" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "cosmic" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "cosmic" ];
      };
      
      # GNOME session - gnome portal with gtk fallback
      gnome.default = [ "gnome" "gtk" ];
    };

    # Explicitly add GTK and GNOME portals
    # Desktop-specific portals (cosmic, hyprland) provided by their modules
    extraPortals = with pkgs; [ 
      xdg-desktop-portal-gtk 
      xdg-desktop-portal-gnome
      xdg-desktop-portal-cosmic
    ];
  };

  # ============================================================================
  # Systemd User Services - COSMIC Portal
  # ============================================================================
  # Custom service definition for COSMIC portal
  # Ensures proper startup order and D-Bus registration
  #
  # Key configuration:
  #   - Waits for graphical session (Wayland display ready)
  #   - Proper D-Bus service registration
  #   - Automatic restart on failure
  #   - Reasonable timeouts for stability
  
  systemd.user.services.xdg-desktop-portal-cosmic = {
    description = "Portal service (COSMIC implementation)";
    
    # Wait for graphical session (Wayland display available)
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "xdg-desktop-portal.service" ];
    
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.cosmic";
      ExecStart = "${pkgs.xdg-desktop-portal-cosmic}/libexec/xdg-desktop-portal-cosmic";
      
      # Restart configuration
      Restart = "on-failure";
      RestartSec = "2s";
      
      # Resource management
      Slice = "session.slice";
      
      # Timeout configuration
      TimeoutStartSec = "10s";     # Portal should start quickly
      TimeoutStopSec = "5s";       # Quick shutdown
    };
  };

  # ============================================================================
  # Font Configuration
  # ============================================================================
  # Strategy: Comprehensive Unicode coverage with focus on monospace and emoji
  # Tested extensively with Mako notifications and terminal applications
  
  fonts = {
    packages = with pkgs; [
      # ---- Primary Fonts (Tested & Verified) ----
      maple-mono.NF                # Primary monospace with Nerd Font symbols
      nerd-fonts.hack              # Alternative monospace
      noto-fonts                   # Base Unicode coverage
      noto-fonts-cjk-sans          # Chinese, Japanese, Korean
      noto-fonts-emoji             # Color emoji support
      
      # ---- Development Fonts ----
      jetbrains-mono               # Modern coding font
      fira-code                    # Ligature support
      fira-code-symbols            # Additional symbols
      cascadia-code                # Microsoft's coding font
      source-code-pro              # Adobe's monospace
      
      # ---- System Fonts ----
      liberation_ttf               # Microsoft font replacements
      dejavu_fonts                 # Comprehensive fallback
      
      # ---- UI Fonts ----
      inter                        # Modern UI font
      roboto                       # Google's UI font
      ubuntu_font_family           # Ubuntu system font
      open-sans                    # Web-safe sans-serif
      
      # ---- Icon & Symbol Fonts ----
      font-awesome                 # Icon font
      material-design-icons        # Material Design icons
      
      # ---- Extended Coverage ----
      noto-fonts-cjk-serif         # CJK serif variant
      noto-fonts-extra             # Additional Noto variants
    ];

    fontconfig = {
      # Font priorities by category
      defaultFonts = {
        # Monospace priority list (coding, terminal)
        monospace = [
          "Maple Mono NF"
          "Hack Nerd Font Mono"
          "JetBrains Mono"
          "Fira Code"
          "Source Code Pro"
          "Cascadia Code"
          "Liberation Mono"
          "Noto Color Emoji"       # Emoji fallback in monospace
        ];
        
        # Emoji fonts
        emoji = [ 
          "Noto Color Emoji"       # Primary color emoji
          "Noto Emoji"             # Black & white fallback
        ];
        
        # Serif fonts (reading, documents)
        serif = [ 
          "Noto Serif" 
          "Liberation Serif" 
          "DejaVu Serif" 
        ];
        
        # Sans-serif fonts (UI, web)
        sansSerif = [ 
          "Inter"
          "Noto Sans" 
          "Liberation Sans" 
          "Roboto"
          "Ubuntu"
          "DejaVu Sans" 
        ];
      };

      # Subpixel rendering for LCD panels
      # Improves text clarity on modern displays
      subpixel = {
        rgba = "rgb";                # Standard RGB pixel layout
        lcdfilter = "default";       # Light LCD filtering
      };

      # Hinting configuration
      # Controls how fonts align to pixel grid
      hinting = {
        enable = true;
        autohint = false;            # Use font's built-in hints
        style = "slight";            # Best for high-DPI displays
      };

      # Anti-aliasing for smooth edges
      antialias = true;
      
      # localConf disabled to prevent Mako emoji rendering issues
      # If needed, enable with caution and test notifications
    };

    enableDefaultPackages = true;  # Include base system fonts
    fontDir.enable = true;          # Create /run/current-system/sw/share/X11/fonts
  };

  # ============================================================================
  # System Environment Variables
  # ============================================================================
  # Font-related environment variables for consistency
  
  environment = {
    variables = {
      # Font configuration paths
      FONTCONFIG_PATH = "/etc/fonts";
      FONTCONFIG_FILE = "/etc/fonts/fonts.conf";
      
      # Locale for proper character rendering
      LC_ALL = "en_US.UTF-8";
      
      # FreeType rendering settings
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    systemPackages = with pkgs; [
      fontconfig      # Font utilities (fc-list, fc-match, fc-cache)
      font-manager    # GUI font browser and manager
    ];
  };

  # ============================================================================
  # Home-Manager User Configuration
  # ============================================================================
  # User-specific font settings and diagnostic tools
  # This section can be moved to modules/home/ if preferred
  
  home-manager.users.${username} = {
    # Home-manager state version
    home.stateVersion = "25.11";
    
    # Enable fontconfig for user
    fonts.fontconfig.enable = true;

    # Application font configuration
    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    # --------------------------------------------------------------------------
    # Font Diagnostic Aliases
    # --------------------------------------------------------------------------
    # Quick commands for testing and debugging font issues
    
    home.shellAliases = {
      # Basic diagnostics
      "font-list"        = "fc-list";
      "font-reload"      = "fc-cache -f -v";
      "font-info"        = "fc-match -v";
      
      # Specific font queries
      "font-emoji"       = "fc-list | grep -i emoji";
      "font-mono"        = "fc-list : family | grep -i mono | sort";
      "font-nerd"        = "fc-list | grep -i 'nerd\\|hack\\|maple'";
      
      # Visual tests
      "font-test"        = "echo 'Font Test: Monospace with symbols ★ ♪ ● ⚡ ▲ and emoji 🚀 📱'";
      "emoji-test"       = "echo 'Emoji Test: 🎵 📱 💬 🔥 ⭐ 🚀 💻 🎮 📊 ✨'";
      
      # Notification tests (Mako)
      "mako-test"        = "notify-send 'Font Test 🚀' 'Mono: ★ ♪ ⚡ | Emoji: 📱 💬 🔥'";
      
      # Deep debugging
      "font-debug"       = "fc-match -s monospace | head -10";
      "font-available"   = "fc-list : family | sort | uniq";
    };

    # Session variables (mirror system for consistency)
    home.sessionVariables = {
      LC_ALL = "en_US.UTF-8";
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
    };

    # User font utilities
    home.packages = with pkgs; [
      fontpreview    # Preview fonts in terminal
      gucharmap      # Character map GUI application
    ];
  };

  # ============================================================================
  # Additional Notes
  # ============================================================================
  #
  # Session Launch Methods:
  #   1. GDM Login Screen:
  #      - Select session from list
  #      - "Hyprland (Optimized)" recommended for daily use
  #      - Standard "Hyprland" available as fallback
  #
  #   2. TTY2 Direct Launch:
  #      - Automatically runs hyprland_tty
  #      - Configured in zsh_profile.nix
  #      - Useful for debugging or minimal boot
  #
  # Hyprland Theme Selection:
  #   Set before login in ~/.zshrc:
  #     export CATPPUCCIN_FLAVOR=mocha    # latte, frappe, macchiato, mocha
  #     export CATPPUCCIN_ACCENT=mauve    # rosewater, flamingo, pink, etc.
  #
  # Enabling JACK:
  #   For audio production or low-latency recording:
  #     services.pipewire.jack.enable = true;
  #
  # Troubleshooting Portals:
  #   Check portal status:
  #     systemctl --user status xdg-desktop-portal
  #     systemctl --user status xdg-desktop-portal-cosmic
  #   
  #   Test portal functionality:
  #     xdg-desktop-portal --version
  #     busctl --user tree org.freedesktop.portal.Desktop
  #
  # Font Issues:
  #   If Mako notifications show broken emoji:
  #     1. Check: font-emoji (should show Noto Color Emoji)
  #     2. Run: font-reload
  #     3. Test: mako-test
  #     4. Restart Mako: systemctl --user restart mako
  #
  # ============================================================================
}

