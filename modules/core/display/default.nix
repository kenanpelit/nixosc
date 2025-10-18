# modules/core/display/default.nix
# ==============================================================================
# Display & Desktop Environment Module - Production Grade
# ==============================================================================
#
# Module:      modules/core/display
# Author:      Kenan Pelit
# Created:     2025-10-10
# Modified:    2025-10-18
# Version:     2.1
#
# Purpose:
#   Unified display stack with multi-desktop support, optimized portal routing,
#   GDM integration, and Intel Arc A380 optimizations.
#
# Architecture:
#   GDM → [Hyprland Optimized | Hyprland | GNOME | COSMIC]
#      ↓
#   XDG Portals (Hyprland/GNOME/COSMIC/GTK) → Session-aware routing
#      ↓
#   PipeWire Audio Stack (ALSA/PulseAudio compat)
#
# Key Features:
#   ✓ Multi-desktop (Hyprland/GNOME/COSMIC)
#   ✓ Session-aware portal routing (clean, no conflicts)
#   ✓ Intel Arc A380 optimizations
#   ✓ GDM systemd wrapper (fixes user services)
#   ✓ Comprehensive font stack (Nerd Fonts/emoji/CJK)
#   ✓ Wayland-first + XWayland fallback
#   ✓ PipeWire audio
#
# Troubleshooting:
#   busctl --user list | grep portal        # Check active portals
#   journalctl -xe --user                   # Debug session issues
#   systemctl --user status waybar.service  # Check user services
#   font-debug                              # Font diagnostics (see aliases)
#
# Dependencies:
#   • inputs.hyprland (flake input)
#   • home-manager (user configs)
#
# ==============================================================================

{ username, inputs, pkgs, lib, config, ... }:

let
  # ---------------------------------------------------------------------------
  # Hyprland Packages (Locked Version)
  # ---------------------------------------------------------------------------
  hyprlandPkg = inputs.hyprland.packages.${pkgs.system}.default;
  hyprPortal  = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;

  # ---------------------------------------------------------------------------
  # Hyprland Optimized Session (Intel Arc A380)
  # ---------------------------------------------------------------------------
  # GDM .desktop entry that launches hyprland_tty directly.
  # hyprland_tty handles systemd initialization internally.
  
  hyprlandOptimizedSession = pkgs.writeTextFile {
    name = "hyprland-optimized-session";
    destination = "/share/wayland-sessions/hyprland-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland (Optimized)
      Comment=Hyprland with Intel Arc A380 optimizations and Catppuccin theming
      
      Type=Application
      DesktopNames=Hyprland
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
      
      # Direct launch via hyprland_tty (handles systemd internally)
      Exec=/etc/profiles/per-user/${username}/bin/hyprland_tty
      
      Keywords=wayland;wm;tiling;catppuccin;intel-arc;
    '';
    
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

in
{
  # =============================================================================
  # Hyprland Compositor
  # =============================================================================
  programs.hyprland = {
    enable = true;
    package = hyprlandPkg;
    portalPackage = hyprPortal;  # Must match Hyprland version
  };

  # =============================================================================
  # System Services
  # =============================================================================
  services = {
    # X11 Server (XWayland + keyboard config propagation)
    xserver = {
      enable = true;
      xkb = {
        layout  = "tr";
        variant = "f";            # Turkish F-keyboard
        options = "ctrl:nocaps";  # Caps Lock → Control
      };
    };

    # Display Manager (GDM)
    displayManager = {
      sessionPackages = [ hyprlandOptimizedSession ];
      
      gdm = {
        enable = true;
        wayland = true;
        autoSuspend = false;
      };
      
      defaultSession = "hyprland-optimized";
      
      autoLogin = {
        enable = true;
        user = "kenan";
      };
      
      sddm.enable = false;
    };

    # Desktop Environments
    desktopManager = {
      gnome.enable  = true;   # Traditional GNOME
      cosmic.enable = true;   # System76 Rust-based DE (Beta)
    };

    # Input Devices
    libinput.enable = true;

    # Session Security (Keyring)
    gnome.gnome-keyring.enable = true;

    # Audio (PipeWire)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };

    # D-Bus (Portal registration)
    dbus = {
      enable = true;
      packages = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        xdg-desktop-portal-cosmic
      ];
    };
  };

  # =============================================================================
  # XDG Desktop Portals (Session-Aware Routing)
  # =============================================================================
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    config = {
      # Common fallback
      common.default = [ "gtk" ];

      # Hyprland: Use Hyprland portal, GTK for file dialogs
      hyprland.default = [ "hyprland" "gtk" ];

      # COSMIC: Full portal implementation with explicit interface routing
      cosmic = {
        default = [ "cosmic" "gtk" ];
        "org.freedesktop.impl.portal.Screenshot"  = [ "cosmic" ];
        "org.freedesktop.impl.portal.ScreenCast"  = [ "cosmic" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "cosmic" ];
      };

      # GNOME: GNOME portal with GTK fallback
      gnome.default = [ "gnome" "gtk" ];
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-cosmic
    ];
  };

  # =============================================================================
  # Systemd User Services
  # =============================================================================
  
  # Hyprland Session Target
  systemd.user.targets.hyprland-session = {
    description = "Hyprland compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  # COSMIC Portal (Conditional - Only when COSMIC desktop enabled)
  systemd.user.services.xdg-desktop-portal-cosmic = lib.mkIf config.services.desktopManager.cosmic.enable {
    description = "Portal service (COSMIC implementation)";
    
    after    = [ "graphical-session.target" ];
    partOf   = [ "graphical-session.target" ];
    wantedBy = [ "xdg-desktop-portal.service" ];

    serviceConfig = {
      Type    = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.cosmic";
      ExecStart = "${pkgs.xdg-desktop-portal-cosmic}/libexec/xdg-desktop-portal-cosmic";
      Restart    = "on-failure";
      RestartSec = "2s";
      Slice = "session.slice";
      TimeoutStartSec = "10s";
      TimeoutStopSec  = "5s";
    };

    environment = {
      XDG_CURRENT_DESKTOP = "COSMIC";
    };
  };

  # =============================================================================
  # Font Configuration
  # =============================================================================
  fonts = {
    packages = with pkgs; [
      # Terminal/Coding fonts
      maple-mono.NF
      nerd-fonts.hack
      cascadia-code
      fira-code
      fira-code-symbols
      jetbrains-mono
      source-code-pro

      # Emoji & Icons
      noto-fonts-emoji
      font-awesome
      material-design-icons

      # System fonts
      liberation_ttf
      dejavu_fonts

      # CJK support
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      # Extended Unicode
      noto-fonts
      noto-fonts-extra

      # Modern UI fonts
      inter
      roboto
      ubuntu_font_family
      open-sans
    ];

    fontconfig = {
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
        
        serif = [
          "Liberation Serif"
          "Noto Serif"
          "DejaVu Serif"
        ];
        
        sansSerif = [
          "Liberation Sans"
          "Inter"
          "Noto Sans"
          "DejaVu Sans"
        ];
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      hinting = {
        enable   = true;
        autohint = false;
        style    = "slight";
      };

      antialias = true;
    };

    enableDefaultPackages = true;
    fontDir.enable = true;
  };

  # =============================================================================
  # System Environment
  # =============================================================================
  environment = {
    variables = {
      FONTCONFIG_PATH     = "/etc/fonts";
      FONTCONFIG_FILE     = "/etc/fonts/fonts.conf";
      LC_ALL              = "en_US.UTF-8";
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    systemPackages = (with pkgs; [
      fontconfig
      font-manager
    ]) ++ [
      hyprlandOptimizedSession
    ];
  };

  # =============================================================================
  # Home-Manager User Configuration
  # =============================================================================
  home-manager.users.${username} = {
    home.stateVersion = "25.11";
    fonts.fontconfig.enable = true;

    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    home.shellAliases = {
      # Font diagnostics
      "font-list"        = "fc-list";
      "font-emoji"       = "fc-list | grep -i emoji";
      "font-nerd"        = "fc-list | grep -i 'nerd\\|hack\\|maple'";
      "font-maple"       = "fc-list | grep -i maple";
      "font-reload"      = "fc-cache -f -v";

      # Font tests
      "font-test"        = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols'";
      "emoji-test"       = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
      "font-render-test" = "echo 'Rendering: ABCDabcd1234 ★♪●⚡▲ 🚀📱💬'";
      "font-ligature-test" = "echo 'Ligatures: -> => != === >= <= && || /* */ //'";
      "font-nerd-icons"  = "echo 'Nerd Icons:     󰈹 󰍛'";

      # Notification tests
      "mako-emoji-test"  = "notify-send 'Emoji Test 🚀' 'Emojis: 📱 💬 🔥 ⭐ 🎵'";
      "mako-font-test"   = "notify-send 'Font Test' 'Symbols: ★ ♪ ● ⚡ ▲'";
      "mako-icons-test"  = "notify-send 'Icon Test' 'Icons:     󰈹 󰍛'";

      # Deep diagnostics
      "font-info"        = "fc-match -v";
      "font-debug"       = "fc-match -s monospace | head -5";
      "font-mono"        = "fc-list : family | grep -i mono | sort";
      "font-available"   = "fc-list : family | sort | uniq";
      "font-cache-clean" = "fc-cache -f -r -v";
    };

    home.sessionVariables = {
      LC_ALL = "en_US.UTF-8";
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };

    home.packages = with pkgs; [
      fontpreview
      gucharmap
    ];
  };
}

# ==============================================================================
# Post-Installation Verification
# ==============================================================================
#
# After rebuild (nixos-rebuild switch --flake .#hay):
#
# 1. Check sessions:
#    ls /run/current-system/sw/share/wayland-sessions/
#    # Expected: hyprland.desktop, hyprland-optimized.desktop, 
#    #           gnome.desktop, cosmic.desktop
#
# 2. Check portals (in Hyprland session):
#    busctl --user list | grep portal
#    # Expected: xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk
#    # Optional: xdg-desktop-portal-cosmic (if COSMIC enabled)
#
# 3. Check systemd:
#    systemctl --user is-system-running
#    # Expected: running or degraded (not "chroot")
#    echo $SYSTEMD_OFFLINE
#    # Expected: 0 (not 1)
#
# 4. Check fonts:
#    fc-list | grep -i "maple\|hack\|emoji"
#    # Expected: Maple Mono NF, Hack Nerd Font, Noto Color Emoji
#
# 5. Check audio:
#    pactl info
#    # Expected: Server Name: PulseAudio (on PipeWire)
#
# 6. Check user services:
#    systemctl --user status waybar.service
#    # Expected: active (running) - not "Running in chroot"
#
# ==============================================================================
# Troubleshooting
# ==============================================================================
#
# Issue: Waybar not starting
# Fix:   systemctl --user restart waybar.service
#        journalctl --user -u waybar.service -n 50
#
# Issue: SYSTEMD_OFFLINE=1
# Fix:   hyprland_tty script handles systemd initialization automatically
#        Check: echo $SYSTEMD_OFFLINE (should be 0)
#        Verify: systemctl --user is-system-running (should not be "chroot")
#
# Issue: Portal conflicts
# Fix:   busctl --user list | grep portal  # Check which are active
#        systemctl --user restart xdg-desktop-portal.service
#
# Issue: Fonts not rendering
# Fix:   fc-cache -f -v  # Rebuild font cache
#        font-debug      # Check fallback chain
#
# Issue: COSMIC portal in Hyprland
# Fix:   Normal behavior - portal is registered but not used in Hyprland
#        Portal routing ensures Hyprland portal takes priority
#
# ==============================================================================
