# modules/nixos/display/default.nix
# ==============================================================================
# NixOS display stack policy (consolidated)
# ------------------------------------------------------------------------------
# This module owns desktop/session plumbing for the repo:
# - Display toggles (Hyprland/GNOME/Niri/COSMIC) + keyboard defaults
# - Display Manager wiring (GDM/greetd integration)
# - Session definitions (.desktop entries)
# - XDG portal selection (per-session)
# - Audio (PipeWire) toggles
# - Fonts + fontconfig defaults
# - Bluetooth UX (Blueman) + BlueZ defaults on physical hosts
#
# Consolidated from:
#   modules/nixos/{desktop,dm,sessions,portals,audio,fonts,bluetooth}
# ==============================================================================

{ lib, pkgs, inputs, config, options, system, ... }:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    ;

  cfg = config.my.display;
  username = config.my.user.name or "kenan";

  isPhysicalHost = config.my.host.isPhysicalHost or false;
  flatpakEnabled = config.services.flatpak.enable or false;

  # DM glue
  dmsGreeterEnabled = config.my.greeter.dms.enable or false;
  hasCosmicDesktopManager =
    lib.hasAttrByPath [ "services" "desktopManager" "cosmic" "enable" ] options;
  hasCosmicGreeter =
    lib.hasAttrByPath [ "services" "displayManager" "cosmic-greeter" "enable" ] options;

  # Sessions
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hyprPortalPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  niriPkg = pkgs.niri-unstable;
  cosmicSessionPkg = pkgs."cosmic-session" or null;
  cosmicEnabled = cfg.enableCosmic or false;
  cosmicAvailable = cosmicSessionPkg != null;

  # Portals
  cosmicPortalPkg = pkgs."xdg-desktop-portal-cosmic" or null;
  cosmicPortalEnabled = cosmicEnabled && cosmicPortalPkg != null;

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

      Exec=/etc/profiles/per-user/${username}/bin/hypr-set tty

      Keywords=wayland;wm;tiling;hyprland;compositor;
    '';
    passthru.providedSessions = [ "hyprland-optimized" ];
  };

  gnomeSessionWrapper = pkgs.writeTextFile {
    name = "gnome-session-wrapper";
    destination = "/share/wayland-sessions/gnome-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=GNOME (Optimized)
      Comment=GNOME with systemd user session support and custom launcher (gnome_tty)

      Type=Application
      DesktopNames=GNOME
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
      X-GDM-SessionRegisters=true
      X-GDM-CanRunHeadless=true

      Exec=/etc/profiles/per-user/${username}/bin/gnome_tty
    '';
    passthru.providedSessions = [ "gnome-optimized" ];
  };

  niriSession = pkgs.writeTextFile {
    name = "niri-session";
    # Avoid clobbering Niri's upstream `niri.desktop` (Exec=niri-session),
    # otherwise greeters will only see the upstream entry and our optimized one
    # disappears from the menu.
    destination = "/share/wayland-sessions/niri-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=Niri (Optimized)
      Comment=Scrollable-tiling Wayland compositor (via niri-set tty)
      Exec=/etc/profiles/per-user/${username}/bin/niri-set tty
      Type=Application
      DesktopNames=niri
    '';
    passthru.providedSessions = [ "niri-optimized" ];
  };

  cosmicSession = pkgs.writeTextFile {
    name = "cosmic-session";
    # Avoid clobbering COSMIC's upstream `cosmic.desktop` if/when it exists.
    destination = "/share/wayland-sessions/cosmic-optimized.desktop";
    text = ''
      [Desktop Entry]
      Name=COSMIC (Optimized)
      Comment=COSMIC desktop environment (Epoch)
      Exec=${lib.getExe' cosmicSessionPkg "cosmic-session"}
      Type=Application
      DesktopNames=COSMIC
      X-GDM-SessionType=wayland
      X-Session-Type=wayland
    '';
    passthru.providedSessions = [ "cosmic-optimized" ];
  };
in
{
  options.my.display = {
    enable = mkEnableOption "display stack (DM/DE/portals/fonts/audio)";
    enableHyprland = mkEnableOption "Hyprland Wayland compositor";
    enableGnome    = mkEnableOption "GNOME desktop environment";
    enableNiri     = mkEnableOption "Niri compositor";
    enableCosmic   = mkEnableOption "COSMIC (Epoch) desktop environment";

    defaultSession = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default session name for the display manager.";
    };

    autoLogin = {
      enable = mkOption { type = types.bool; default = false; description = "GDM auto-login"; };
      user   = mkOption { type = types.nullOr types.str; default = null; };
    };

    keyboard = {
      layout = mkOption { type = types.str; default = "tr"; };
      variant = mkOption { type = types.nullOr types.str; default = "f"; };
      options = mkOption { type = types.listOf types.str; default = [ "ctrl:nocaps" ]; };
    };

    enableAudio = mkEnableOption "PipeWire audio stack";

    fonts = {
      enable = mkEnableOption "system font stack (packages + fontconfig)";

      hiDpiOptimized = mkOption {
        type = types.bool;
        default = false; # Default to FALSE for 2K (Standard DPI needs subpixel)
        description = ''
          If true, fontconfig is tuned for HiDPI/Retina (4K+) panels:
            - grayscale antialiasing (no subpixel)
          If false (default for 2K/FHD), we use standard subpixel rendering:
            - rgb subpixel (sharper on standard screens)
            - slight hinting
            - lcddefault filter
        '';
      };
    };
  };

  config = mkMerge [
    # -------------------------------------------------------------------------
    # Desktop glue (shared across WMs/DEs)
    # -------------------------------------------------------------------------
    {
      services = {
        gvfs.enable = true;
        fstrim.enable = true;

        dbus = {
          enable = true;
          # Provide D-Bus services for Secret Service / keyring prompts (gcr),
          # and gnome-keyring D-Bus activation files.
          packages = with pkgs; [ gcr gnome-keyring ];
        };

        # Start gnome-keyring (Secret Service / PKCS#11 / optional SSH agent socket).
        # Without this, apps may fall back to gcr-prompter popups later in the session.
        gnome.gnome-keyring.enable = true;

        touchegg.enable = false;
        tumbler.enable = true;
        fwupd.enable = true;

        spice-vdagentd.enable = mkDefault false;
        printing.enable = false;

        avahi = {
          enable = false;
          nssmdns4 = false;
        };

        # Keep speech-dispatcher fully disabled system-wide.
        speechd.enable = mkForce false;
      };

      # Hard-disable speech dispatcher units/sockets at user level as well.
      systemd.user.services.speech-dispatcher = {
        enable = false;
        unitConfig.ConditionPathExists = "!/dev/null";
      };
      systemd.user.sockets.speech-dispatcher = {
        enable = false;
        unitConfig.ConditionPathExists = "!/dev/null";
      };

      # Avoid multiple competing SSH agents on Wayland sessions.
      # We already pin `SSH_AUTH_SOCK` to GNOME Keyring's socket; disable GCR's
      # ssh-agent wrapper completely to prevent it from starting in the background.
      systemd.user.services.gcr-ssh-agent = {
        enable = false;
        unitConfig.ConditionPathExists = "!/dev/null";
      };
      systemd.user.sockets.gcr-ssh-agent = {
        enable = false;
        unitConfig.ConditionPathExists = "!/dev/null";
      };

      environment.sessionVariables = {
        # Avoid GTK a11y bridge overhead/noise (common desktop hardening/perf tweak).
        GTK_A11Y = "none";
        NO_AT_BRIDGE = "1";

        # Make SSH use the keyring-managed agent socket (stable for Wayland sessions).
        # This reduces repeated "enter passphrase" prompts caused by changing agents/sockets.
        SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
      };
    }

    # -------------------------------------------------------------------------
    # Bluetooth (physical hosts)
    # -------------------------------------------------------------------------
    (mkIf isPhysicalHost {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
            # Disable experimental LE Audio plugins like BAP (which require ISO sockets).
            # This avoids log spam like:
            #   bluetoothd: ... BAP requires ISO Socket which is not enabled
            Experimental = false;
            Disable = "bap";
          };
        };
      };

      services.blueman.enable = true;
    })

    # -------------------------------------------------------------------------
    # Audio (PipeWire)
    # -------------------------------------------------------------------------
    (mkIf cfg.enableAudio {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    })

    # -------------------------------------------------------------------------
    # Fonts + fontconfig (system-wide)
    # -------------------------------------------------------------------------
    (mkIf cfg.fonts.enable {
      fonts = {
        packages = with pkgs; [
          # Extra symbols / light fallbacks
          nerd-fonts.symbols-only
          monaspace
          nerd-fonts.monaspace
          nerd-fonts.hack
          fira-code
          fira-code-symbols

          # Emoji & icons
          noto-fonts-color-emoji
          font-awesome
          material-design-icons

          # General UI / document fonts (minimal, kept for compatibility)
          liberation_ttf
          dejavu_fonts
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          roboto
          ubuntu-classic
          open-sans
        ];

        enableDefaultPackages = true;
        fontDir.enable = true;

        fontconfig = {
          defaultFonts = {
            monospace = [
              # Primary everywhere
              "Maple Mono NF"
              "Maple Mono"
              "Maple Mono NF CN"

              # Minimal fallbacks
              "Monaspace Neon"
              "Hack Nerd Font"
              "Hack"
              "FiraCode Nerd Font"
              "Noto Color Emoji"
            ];

            emoji = [ "Noto Color Emoji" ];

            serif = [
              "Maple Mono NF"
              "Maple Mono"
              "Liberation Serif"
              "Noto Serif"
              "Noto Serif CJK SC"
              "DejaVu Serif"
              "Noto Color Emoji"
            ];

            sansSerif = [
              "Maple Mono NF"
              "Maple Mono"
              "Noto Sans"
              "Noto Sans CJK SC"
              "Liberation Sans"
              "DejaVu Sans"
              "Noto Color Emoji"
            ];
          };

          # 2K/Standard Monitor Optimization (Gold Standard)
          subpixel = {
            rgba = if cfg.fonts.hiDpiOptimized then "none" else "rgb";
            lcdfilter = if cfg.fonts.hiDpiOptimized then "none" else "lcddefault";
          };

          hinting = {
            enable   = true;
            autohint = false;
            style    = "slight"; # Slight is best for modern fonts on both 2K and 4K
          };

          antialias = true;
          useEmbeddedBitmaps = false;

          # Force emoji fallback into Inter/Fira/Maple
          localConf = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
            <fontconfig>
              <!-- Prefer Noto, explicitly reject Twitter Color Emoji -->
              <rejectfont>
                <pattern>
                  <patelt name="family">
                    <string>Twitter Color Emoji</string>
                  </patelt>
                </pattern>
              </rejectfont>

              <!-- Generic Emoji Alias -->
              <alias>
                <family>emoji</family>
                <prefer>
                  <family>Noto Color Emoji</family>
                  <family>Twitter Color Emoji</family>
                </prefer>
              </alias>

              <!-- Specific Font Fallbacks -->
              <alias>
                <family>Inter</family>
                <prefer><family>Noto Color Emoji</family></prefer>
              </alias>
              <alias>
                <family>Fira Code</family>
                <prefer><family>Noto Color Emoji</family></prefer>
              </alias>
              <alias>
                <family>Maple Mono NF</family>
                <prefer><family>Noto Color Emoji</family></prefer>
              </alias>
            </fontconfig>
          '';
        };
      };

      environment.variables = {
        # Version 40 is standard for Arch/CachyOS (sharper)
        FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      };
    })

    # -------------------------------------------------------------------------
    # Display manager (GDM by default; greetd when DMS greeter is enabled)
    # -------------------------------------------------------------------------
    (mkIf cfg.enable (mkMerge [
      {
        services.xserver.enable = true;

        services.displayManager.gdm = mkIf (!dmsGreeterEnabled) {
          enable = true;
          wayland = true;
        };
        services.desktopManager.gnome.enable = cfg.enableGnome;
        services.displayManager.autoLogin = {
          enable = cfg.autoLogin.enable;
          user   = cfg.autoLogin.user or null;
        };
        services.displayManager.defaultSession =
          if cfg.defaultSession != null then cfg.defaultSession
          else if cfg.enableHyprland then "hyprland-optimized"
          else if cfg.enableGnome then "gnome"
          else if cfg.enableCosmic then "cosmic-optimized"
          else null;

        services.xserver.xkb.layout  = cfg.keyboard.layout;
        services.xserver.xkb.variant = cfg.keyboard.variant;
        services.xserver.xkb.options = lib.concatStringsSep "," cfg.keyboard.options;
      }

      (mkIf (cfg.enableCosmic && hasCosmicDesktopManager) {
        services.desktopManager.cosmic.enable = true;
      })

      (mkIf hasCosmicGreeter {
        # We use dms-greeter; keep COSMIC greeter disabled.
        services.displayManager."cosmic-greeter".enable = mkForce false;
      })
    ]))

    # -------------------------------------------------------------------------
    # Sessions (DM entries + required packages)
    # -------------------------------------------------------------------------
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = (!cosmicEnabled) || cosmicAvailable;
          message = "my.display.enableCosmic is enabled, but `pkgs.cosmic-session` is missing from nixpkgs.";
        }
      ];

      # GNOME Shell (mutter) started via `org.gnome.Shell@wayland.service` expects
      # the current logind session to be a *graphical* session (Type=wayland/x11).
      #
      # Force pam_systemd to register `login` sessions as wayland so GNOME can be
      # started directly from a TTY without GDM.
      security.pam.services.login.rules.session.systemd.settings.type = mkDefault "wayland";

      services.displayManager.sessionPackages = mkMerge [
        (lib.optional cfg.enableHyprland hyprlandOptimizedSession)
        (lib.optional cfg.enableGnome gnomeSessionWrapper)
        (lib.optional cfg.enableNiri niriSession)
        (lib.optional (cosmicEnabled && cosmicAvailable) cosmicSession)
      ];

      environment.systemPackages = mkMerge [
        (lib.optional cfg.enableHyprland hyprlandPkg)
        (lib.optional cfg.enableHyprland hyprPortalPkg)
        (lib.optional cfg.enableHyprland hyprlandOptimizedSession)

        (lib.optional cfg.enableGnome gnomeSessionWrapper)
        (lib.optional cfg.enableGnome pkgs."gnome-session")

        (lib.optional cfg.enableNiri niriPkg)
        (lib.optional cfg.enableNiri niriSession)

        (lib.optional (cosmicEnabled && cosmicAvailable) cosmicSessionPkg)
        (lib.optional (cosmicEnabled && cosmicAvailable) cosmicSession)
      ];
    })

    # -------------------------------------------------------------------------
    # XDG portals (per-session selection; also required for Flatpak)
    # -------------------------------------------------------------------------
    (mkIf (cfg.enable || flatpakEnabled) {
      # Required when Home Manager installs portals via user packages
      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];

      xdg.portal = {
        enable = true;
        extraPortals =
          (lib.optional cfg.enableHyprland hyprPortalPkg)
          ++ (lib.optional cosmicPortalEnabled cosmicPortalPkg)
          ++ (lib.optional cfg.enableNiri pkgs.xdg-desktop-portal-wlr)
          ++ [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-gnome
          ];

        # Pick portal backends per-session to avoid "wrong compositor portal"
        # when multiple WMs are installed on the same host.
        config = mkMerge [
          {
            common.default = [ "gtk" ];

            # Hyprland sessions (upstream often sets "Hyprland", but keep a
            # lowercase alias to be resilient across greeters/wrappers).
            Hyprland.default = [ "hyprland" "gtk" ];
            hyprland.default = [ "hyprland" "gtk" ];

            # Niri: keep GTK as the general-purpose portal backend, and use GNOME
            # portal only for ScreenCast/Screenshot (Niri implements Mutter D-Bus).
            niri = {
              default = [ "gtk" ];
              "org.freedesktop.impl.portal.Access" = [ "gtk" ];
              "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
              "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
              # Avoid GNOME's GlobalShortcuts provider UI popping up under Niri.
              "org.freedesktop.impl.portal.GlobalShortcuts" = [ "gtk" ];
              "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
              "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome-niri" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "gnome-niri" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "gnome-niri" ];
            };

            # GNOME session.
            GNOME.default = [ "gnome" "gtk" ];
          }
          (mkIf cosmicPortalEnabled {
            COSMIC.default = [ "cosmic" "gtk" ];
            cosmic.default = [ "cosmic" "gtk" ];
          })
        ];
      };
    })
  ];
}
