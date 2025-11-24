# modules/core/display/default.nix
# ==============================================================================
# Display & Desktop Stack — Wayland-First, Multi-Desktop, Portal-Aware
# ==============================================================================
# Module:      modules/core/display
# Purpose:     Unified display stack (DM/DE/Portals/Input/Audio/Fonts)
# Author:      Kenan Pelit
# Last Edited: 2025-11-24
#
# Scope:
#   ✓ Display Manager (GDM — Wayland-first)
#   ✓ Desktop Environments (Hyprland / GNOME / COSMIC)
#   ✓ XDG Desktop Portals (session-aware routing)
#   ✓ Input Stack (XKB layout + libinput devices)
#   ✓ Audio Stack (PipeWire, ALSA, PulseAudio compatibility)
#   ✓ Font Stack (system fonts + fontconfig tuning)
#
# Explicitly NOT handled here:
#   ✗ Home-Manager user configuration (see: modules/core/account)
#   ✗ GPU drivers / Mesa / kernel modules (see: hardware/*)
#   ✗ Security / PAM / keyrings (see: modules/core/security)
#   ✗ WM keybinds, theming, user UI config (see: modules/home/*)
#
# Design Principles:
#   • Wayland-first: native compositors → XWayland only when needed
#   • Strict module boundaries: no user logic, no HM, no debug noise
#   • Composable API: my.display.{enable,enableHyprland,enableGnome,...}
#   • Zero hard-coded host/user names: fully flake-driven
#   • NixOS handles DE packages: Don't duplicate gnome-session/gnome-shell
#
# ==============================================================================

{ pkgs, lib, inputs, config, username, ... }:

let
  inherit (lib) mkOption mkEnableOption mkIf types;

  cfg = config.my.display;

  # ---------------------------------------------------------------------------
  # Hyprland packages pinned via flake input
  # ---------------------------------------------------------------------------
  hyprlandPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;

  hyprPortalPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  # ---------------------------------------------------------------------------
  # Custom Hyprland session for GDM
  # ---------------------------------------------------------------------------
  # Notes:
  #   - Exec path assumes a hyprland_tty wrapper in the user's PATH
  #   - The username is not hard-coded; we derive it from my.user/flake arg
  #   - Purely registers a .desktop session; it does not manage systemd here
  #
  hyprlandOptimizedSession = pkgs.writeTextFile {
    name = "hyprland-optimized-session";
    destination = "/share/wayland-sessions/hyprland-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland (Optimized)
      Comment=Hyprland with pinned flake build and user-session integration

      Type=Application
      DesktopNames=Hyprland
      X-GDM-SessionType=wayland
      X-Session-Type=wayland

      Exec=/etc/profiles/per-user/${username}/bin/hyprland_tty

      Keywords=wayland;wm;tiling;hyprland;compositor;
    '';
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

  # ---------------------------------------------------------------------------
  # Derived values
  # ---------------------------------------------------------------------------
  defaultSession =
    if cfg.defaultSession != null
    then cfg.defaultSession
    else (if cfg.enableHyprland then "hyprland-optimized" else "gnome");

  autoLoginUser =
    cfg.autoLogin.user or username;

in
{
  # ===========================================================================
  # Options
  # ===========================================================================

  options.my.display = {
    enable = mkEnableOption "the display stack (DM/DE/portals/fonts/audio)";

    # -------------------------------------------------------------------------
    # Desktop selection
    # -------------------------------------------------------------------------
    enableHyprland = mkEnableOption "Hyprland Wayland compositor";
    enableGnome    = mkEnableOption "GNOME desktop environment";
    enableCosmic   = mkEnableOption "COSMIC desktop environment";

    # Default login/session name for GDM (e.g. hyprland-optimized, gnome, cosmic)
    defaultSession = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Default session name for the display manager.

        If null:
          - Prefer "hyprland-optimized" when Hyprland is enabled
          - Otherwise fallback to "gnome"
      '';
    };

    # -------------------------------------------------------------------------
    # Display manager & auto-login
    # -------------------------------------------------------------------------
    autoLogin = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable GDM auto-login for the primary user.

          SECURITY:
            - Only use on single-user, fully encrypted machines.
            - Auto-login + no disk encryption is a bad idea.
        '';
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Username to auto-login via GDM.

          If null, falls back to the flake "username" argument.
          Typically you want this to match my.user.name.
        '';
      };
    };

    # -------------------------------------------------------------------------
    # Keyboard layout (propagated via XKB to Wayland compositors)
    # -------------------------------------------------------------------------
    keyboard = {
      layout = mkOption {
        type = types.str;
        default = "tr";
        description = "XKB keyboard layout (e.g. 'us', 'tr').";
      };

      variant = mkOption {
        type = types.nullOr types.str;
        default = "f";
        description = "XKB layout variant (e.g. 'intl', 'f').";
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [ "ctrl:nocaps" ];
        description = ''
          List of XKB options (e.g. ["ctrl:nocaps" "compose:ralt"]).

          Default:
            - ctrl:nocaps → Caps Lock becomes an extra Control key.
        '';
      };
    };

    # -------------------------------------------------------------------------
    # Audio stack
    # -------------------------------------------------------------------------
    enableAudio = mkEnableOption "PipeWire-based audio stack";

    # -------------------------------------------------------------------------
    # Font stack tuning
    # -------------------------------------------------------------------------
    fonts = {
      enable = mkEnableOption "system font stack (packages + fontconfig)";

      hiDpiOptimized = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If true, fontconfig is tuned for HiDPI/modern LCD panels:
            - subpixel RGB
            - slight hinting
            - antialias enabled
        '';
      };
    };
  };

  # ===========================================================================
  # Configuration
  # ===========================================================================

  config = mkIf cfg.enable {

    # -------------------------------------------------------------------------
    # Hyprland compositor
    # -------------------------------------------------------------------------
    programs.hyprland = mkIf cfg.enableHyprland {
      enable        = true;
      package       = hyprlandPkg;
      # IMPORTANT:
      #   - Hyprland portal backend (xdg-desktop-portal-hyprland) buradan geliyor.
      #   - XDG portal extraPortals kısmında tekrar eklemiyoruz ki unit çakışması olmasın.
      portalPackage = hyprPortalPkg;
    };

    # -------------------------------------------------------------------------
    # X server stub (for XKB + XWayland)
    # -------------------------------------------------------------------------
    services.xserver = {
      enable = true;

      xkb = {
        layout  = cfg.keyboard.layout;
        variant = cfg.keyboard.variant;
        options = lib.concatStringsSep "," cfg.keyboard.options;
      };
    };

    # -------------------------------------------------------------------------
    # Input stack (libinput)
    # -------------------------------------------------------------------------
    services.libinput.enable = true;

    # -------------------------------------------------------------------------
    # Display manager: GDM (Wayland-first)
    # -------------------------------------------------------------------------
    services.displayManager = {
      # Register custom sessions
      # NOTE:
      #   - Hyprland: Custom session wrapper (hyprland_tty) ekledik
      #   - GNOME: services.desktopManager.gnome.enable otomatik session ekliyor
      #            Manuel gnome-session EKLEME! Conflict yaratır.
      sessionPackages = lib.optionals cfg.enableHyprland [ hyprlandOptimizedSession ];

      # We pick GDM and explicitly disable SDDM to avoid conflicts
      gdm = {
        enable      = true;
        wayland     = true;
        autoSuspend = false;
        
        # Disable debug mode to prevent G_DEBUG=fatal-warnings crash
        debug       = false;
      };

      sddm.enable = false;

      defaultSession = defaultSession;

      autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user   = autoLoginUser;
      };
    };

    # -------------------------------------------------------------------------
    # Desktop environments (GNOME / COSMIC)
    # -------------------------------------------------------------------------
    # NOTE:
    #   - Bu enable'lar otomatik olarak tüm gerekli paketleri yükler:
    #     * gnome.enable → gnome-session, gnome-shell, mutter, gdm session files
    #     * cosmic.enable → cosmic-session, cosmic-comp
    #   - Manuel paket eklemeye gerek YOK!
    #
    services.desktopManager = {
      gnome.enable  = cfg.enableGnome;
      cosmic.enable = cfg.enableCosmic;
    };

    # -------------------------------------------------------------------------
    # GNOME services & integrations
    # -------------------------------------------------------------------------
    services.gnome = mkIf cfg.enableGnome {
      # Keyring (password management)
      gnome-keyring.enable = true;
      
      # Core GNOME apps (calculator, text editor, system monitor, etc.)
      # NOTE: NixOS 24.11+ renamed: core-utilities → core-apps
      # Disabled for minimal setup - user can install desired apps via home-manager
      core-apps.enable = false;
      
      # Evolution data server (calendar, contacts, tasks integration)
      evolution-data-server.enable = true;
      
      # GNOME Settings Daemon (handles theme, input, power management)
      gnome-settings-daemon.enable = true;
      
      # Remote desktop (disabled by default for security)
      gnome-remote-desktop.enable = false;
      
      # Online accounts integration (Google, Microsoft, etc.)
      # Disabled - user can enable via GNOME Settings if needed
      gnome-online-accounts.enable = false;
    };

    # -------------------------------------------------------------------------
    # PAM integration for GNOME keyring
    # -------------------------------------------------------------------------
    # NOTE:
    #   - Bu security modülünde değil, burada olmalı.
    #   - GNOME enable olduğunda otomatik devreye girer.
    #   - Login sırasında keyring'i unlock eder.
    #   - GDM ve login PAM stack'lerine GNOME Keyring entegrasyonu ekler.
    #
    security.pam.services = mkIf cfg.enableGnome {
      gdm.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };

    # -------------------------------------------------------------------------
    # Audio stack (PipeWire)
    # -------------------------------------------------------------------------
    services.pipewire = mkIf cfg.enableAudio {
      enable = true;

      alsa.enable       = true;
      alsa.support32Bit = true;
      pulse.enable      = true;
      jack.enable       = false;
    };

    # -------------------------------------------------------------------------
    # D-Bus + Portal backend registration
    # -------------------------------------------------------------------------
    services.dbus = {
      enable = true;
      # NOTE:
      #   - Core xdg-desktop-portal burada.
      #   - DE/WM backend'leri xdg.portal.extraPortals üzerinden geliyor.
      packages = [ pkgs.xdg-desktop-portal ];
    };

    # -------------------------------------------------------------------------
    # XDG Desktop Portals (session-aware routing)
    # -------------------------------------------------------------------------
    # NOTE:
    #   - Portal backend seçimi session bazlı yapılıyor.
    #   - Hyprland: programs.hyprland.portalPackage sağlıyor.
    #   - GNOME: xdg-desktop-portal-gnome kullanıyor.
    #   - COSMIC: xdg-desktop-portal-cosmic kullanıyor.
    #   - GTK portal tüm DE'lerde fallback olarak var.
    #
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;

      # Burada sadece backend paketlerini DE/WM bazlı ekliyoruz.
      # Hyprland portalını programs.hyprland.portalPackage sağlıyor; burada tekrar yok.
      extraPortals =
        lib.concatLists [
          # Hyprland:
          #   - Backend: hyprland portal (programs.hyprland.portalPackage)
          #   - Burada sadece GTK fallback dosya seçici vs. için.
          (lib.optionals cfg.enableHyprland [
            pkgs.xdg-desktop-portal-gtk
          ])

          # GNOME: GNOME portal + GTK fallback
          (lib.optionals cfg.enableGnome [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ])

          # COSMIC: COSMIC portal + GTK fallback
          (lib.optionals cfg.enableCosmic [
            pkgs.xdg-desktop-portal-cosmic
            pkgs.xdg-desktop-portal-gtk
          ])
        ];

      # Backend seçim haritası:
      #   - Session name → backend tercih sırası
      config = {
        # Fallback for unknown sessions
        common.default = [ "gtk" ];

        # Hyprland → hyprland backend + gtk fallback
        hyprland.default = [ "hyprland" "gtk" ];

        # GNOME → gnome backend + gtk fallback
        gnome.default    = [ "gnome"    "gtk" ];

        # COSMIC → cosmic backend + gtk fallback
        cosmic.default   = [ "cosmic"   "gtk" ];
      };
    };

    # -------------------------------------------------------------------------
    # Hyprland session target (for user services)
    # -------------------------------------------------------------------------
    # NOTE:
    #   - User services'lerin Hyprland başladıktan sonra çalışması için.
    #   - Home-Manager services'leri buna bağlanabilir.
    #
    systemd.user.targets.hyprland-session = mkIf cfg.enableHyprland {
      description = "Hyprland compositor session";

      bindsTo = [ "graphical-session.target" ];
      wants   = [ "graphical-session-pre.target" ];
      after   = [ "graphical-session-pre.target" ];
    };

    # -------------------------------------------------------------------------
    # Font stack
    # -------------------------------------------------------------------------
    fonts = mkIf cfg.fonts.enable {
      packages = with pkgs; [
        # Coding / Nerd fonts
        maple-mono.NF
        nerd-fonts.hack
        cascadia-code
        fira-code
        fira-code-symbols
        jetbrains-mono
        source-code-pro

        # Emoji & icons
        noto-fonts-color-emoji
        font-awesome
        material-design-icons

        # General UI / document fonts
        liberation_ttf
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        inter
        roboto
        ubuntu-classic
        open-sans
      ];

      enableDefaultPackages = true;
      fontDir.enable = true;

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

        subpixel = mkIf cfg.fonts.hiDpiOptimized {
          rgba      = "rgb";
          lcdfilter = "default";
        };

        hinting = {
          enable   = true;
          autohint = false;
          style    = if cfg.fonts.hiDpiOptimized then "slight" else "medium";
        };

        antialias = true;
      };
    };

    # -------------------------------------------------------------------------
    # System environment
    # -------------------------------------------------------------------------
    environment = {
      # Keep this minimal. Locale should be handled in a dedicated module.
      variables = {
        # FreeType hinting quality
        FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      };

      systemPackages =
        [ hyprlandOptimizedSession ]
        ++ (with pkgs; [
          # Font management utilities
          fontconfig
          font-manager
        ]);
    };
  };
}
