# modules/core/display/default.nix
# ==============================================================================
# Display & Desktop Environment Module
# ==============================================================================
#
# Module: modules/core/display
# Author: Kenan Pelit
# Date:   2025-10-01
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
#   1. Hyprland-First Portal Strategy
#      - Hyprland portal active in Hyprland sessions
#      - GTK portal as fallback for common cases
#      - COSMIC portal for COSMIC sessions
#      - Ensures xdg-open and screen sharing use correct backend
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
#      - Hyprland: Tiling compositor for power users
#      - COSMIC: Next-gen Rust-based desktop (Beta - from nixpkgs)
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
    # Display Manager - COSMIC Greeter (Primary)
    # --------------------------------------------------------------------------
    # COSMIC greeter provides session selection for GNOME, Hyprland, and COSMIC
    # Alternative: Use GDM by commenting cosmic-greeter and uncommenting gdm
    
    displayManager = {
      # COSMIC Greeter (Primary - supports all desktop sessions)
      cosmic-greeter.enable = true;
      
      # GDM (Alternative - uncomment to use instead of cosmic-greeter)
      # gdm = {
      #   enable = true;
      #   wayland = true;             # Wayland-first approach
      # };
      
      # Default session selection
      defaultSession = "cosmic";
      
      autoLogin.enable = false;     # Security: no auto-login
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
  };

  # ============================================================================
  # XDG Desktop Portals
  # ============================================================================
  # Portal routing ensures applications use the correct backend for
  # screen sharing, file selection, and external link handling.
  # Each desktop environment gets its optimal portal configuration.
  # NOTE: COSMIC portal is automatically provided by services.desktopManager.cosmic
  
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;  # Route xdg-open through portal (Wayland-safe)

    # Portal priority configuration per desktop session
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [ "gtk" "hyprland" ];  # Hyprland session uses both
      cosmic.default = [ "cosmic" "gtk" ];      # COSMIC session prefers cosmic portal
      gnome.default = [ "gnome" "gtk" ];        # GNOME session uses gnome portal
    };

    # GTK and GNOME portals (Desktop-specific portals via programs.hyprland or cosmic module)
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk 
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  # ============================================================================
  # GNOME Wayland Session Files
  # ============================================================================
  # Explicit session definitions for consistency across different DM setups
  
  environment.etc = {
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
