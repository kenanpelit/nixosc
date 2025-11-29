# modules/home/brave/default.nix
# ==============================================================================
# Brave Browser Configuration - NixOS + Home Manager
# ==============================================================================
# Goals:
# - Keep user profile and preferences under the user's control
# - Only set sane defaults on first install (handled in initial-setup.nix)
# - Use a launcher wrapper for consistent flags (Wayland, VA-API, etc.)
# - Optional integration with extensions and Catppuccin theme modules
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, pkgs, config, lib, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # ============================================================================
  # Desktop environment detection
  # ============================================================================

  isWayland =
    (config.my.desktop.wayland.enable or false)
    || (config.services.xserver.displayManager.gdm.wayland or false)
    || (builtins.getEnv "XDG_SESSION_TYPE" == "wayland");

  isHyprland = config.my.desktop.hyprland.enable or false;
  isGnome    = config.services.xserver.desktopManager.gnome.enable or false;

  # ============================================================================
  # Hardware acceleration detection
  # ============================================================================

  vaApiDriver =
    if config.my.browser.brave.enableHardwareAcceleration
    then "iHD"
    else "";

  # ============================================================================
  # Browser data paths (relative to $HOME)
  # ============================================================================

  braveConfigDir = ".config/BraveSoftware/Brave-Browser";
  profilePath    = "${braveConfigDir}/${config.my.browser.brave.profile}";

  # ============================================================================
  # Feature flags (computed in Nix, used by launcher)
  # ============================================================================

  baseFeatures = [
    "BackForwardCache"
    "QuietNotificationPrompts"
    "TabFreeze"
    "OverlayScrollbar"
    "WebUIDarkMode"
    "AutoDarkMode"
  ];

  enableFeatures =
    lib.concatStringsSep "," (
      baseFeatures
      ++ lib.optionals config.my.browser.brave.enableHardwareAcceleration [
        "VaapiVideoDecoder"
        "VaapiVideoEncoder"
        "VaapiVideoDecodeLinuxGL"
      ]
      ++ lib.optionals isWayland [ "UseOzonePlatform" ]
      ++ lib.optionals isHyprland [ "WaylandWindowDecorations" ]
    );

  disabledFeatures =
    lib.concatStringsSep "," (
      lib.optionals isHyprland [ "UseChromeOSDirectVideoDecoder" ]
    );

in
{
  # Bring in submodules
  imports = [
    ./extensions.nix
    ./theme.nix
    ./initial-setup.nix
  ];

  # ============================================================================
  # Module options
  # ============================================================================

  options.my.browser.brave = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Brave browser installation and configuration.";
    };

    setAsDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set Brave as the default web browser.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.brave;
      description = "The Brave browser package to install.";
    };

    enableCatppuccinTheme = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Catppuccin theme integration for Brave.";
    };

    enableCrypto = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cryptocurrency-related features and extensions.";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = "Brave profile directory name (e.g. \"Default\", \"Profile 1\").";
    };

    enableHardwareAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GPU hardware acceleration (VA-API, EGL, etc.).";
    };

    enableStrictPrivacy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable strict privacy flags (may break some websites).";
    };

    diskCacheSize = lib.mkOption {
      type = lib.types.int;
      default = 268435456; # 256 MiB
      description = "Disk cache size in bytes (default: 256 MiB).";
    };

    mediaCacheSize = lib.mkOption {
      type = lib.types.int;
      default = 134217728; # 128 MiB
      description = "Media cache size in bytes (default: 128 MiB).";
    };

    manageExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically configure Brave extensions via policies.";
    };

    enableAutoCleanup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automated cleanup for Brave cache (tmp/lock files only).";
    };
  };

  # ============================================================================
  # Main configuration
  # ============================================================================

  config = lib.mkIf config.my.browser.brave.enable {

    # -------------------------------------------------------------------------
    # Package installation
    # -------------------------------------------------------------------------

    home.packages = [ config.my.browser.brave.package ];

    # -------------------------------------------------------------------------
    # Default application associations (xdg-mime)
    # -------------------------------------------------------------------------

    xdg.mimeApps = lib.mkIf config.my.browser.brave.setAsDefault {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http"    = [ "brave-browser.desktop" ];
        "x-scheme-handler/https"   = [ "brave-browser.desktop" ];
        "text/html"                = [ "brave-browser.desktop" ];
        "application/xhtml+xml"    = [ "brave-browser.desktop" ];
        "x-scheme-handler/about"   = [ "brave-browser.desktop" ];
        "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
        "application/x-extension-htm"   = [ "brave-browser.desktop" ];
        "application/x-extension-html"  = [ "brave-browser.desktop" ];
        "application/x-extension-shtml" = [ "brave-browser.desktop" ];
        "application/x-extension-xht"   = [ "brave-browser.desktop" ];
        "application/x-extension-xhtml" = [ "brave-browser.desktop" ];
      };
    };

    # -------------------------------------------------------------------------
    # Brave launch wrapper
    # -------------------------------------------------------------------------
    # Single source of truth for all runtime flags.

    home.file.".local/bin/brave-launcher" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Brave Browser Launcher with deterministic flags (NixOS / Home Manager)

        # Show wrapper help instead of passing --help to Brave
        if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
          cat <<EOF
Brave Launcher (NixOS / Home Manager)

Usage:
  brave-launcher [extra Brave flags...] [URL...]

This wrapper always adds a fixed, optimized set of flags:
  • disk/media cache sizes
  • Wayland / Hyprland integration (if detected)
  • VA-API hardware acceleration (if enabled)
  • Strict privacy flags (if enabled)

Compiled feature flags:
  --enable-features=${enableFeatures}${
            if disabledFeatures != "" then ''
  --disable-features=${disabledFeatures}'' else ""}

Environment hints:
  BROWSER = brave-launcher        (if setAsDefault = true)
  LIBVA_DRIVER_NAME = ''${vaApiDriver or "auto"}

To see Brave's own flags, run:
  brave --help

EOF
          exit 0
        fi

        BRAVE_FLAGS=()

        # Performance-related flags
        BRAVE_FLAGS+=(
          --disable-extensions-http-throttling
          --disk-cache-size=${toString config.my.browser.brave.diskCacheSize}
          --media-cache-size=${toString config.my.browser.brave.mediaCacheSize}
          --disable-default-apps
          --no-default-browser-check
          --no-first-run
          --enable-smooth-scrolling
          --lang=en-US
          --accept-lang=en-US,tr-TR
        )

        # Hardware acceleration flags (if enabled)
        ${lib.optionalString config.my.browser.brave.enableHardwareAcceleration ''
        BRAVE_FLAGS+=(
          --enable-gpu-rasterization
          --enable-zero-copy
          --ignore-gpu-blocklist
          --enable-accelerated-video-decode
          --enable-accelerated-video-encode
          --use-gl=egl
        )
        ''}

        # Wayland flags
        ${lib.optionalString isWayland ''
        BRAVE_FLAGS+=(
          --ozone-platform=wayland
          --enable-wayland-ime
          --gtk-version=4
        )
        ''}

        # Strict privacy mode (optional)
        ${lib.optionalString config.my.browser.brave.enableStrictPrivacy ''
        BRAVE_FLAGS+=(
          --disable-background-networking
          --disable-sync
          --disable-speech-api
        )
        ''}

        # Deterministic feature flags (computed in Nix)
        BRAVE_FLAGS+=( "--enable-features=${enableFeatures}" )
        ${lib.optionalString (disabledFeatures != "") ''
        BRAVE_FLAGS+=( "--disable-features=${disabledFeatures}" )
        ''}

        exec ${config.my.browser.brave.package}/bin/brave "''${BRAVE_FLAGS[@]}" "$@"
      '';
    };

    # -------------------------------------------------------------------------
    # Session variables
    # -------------------------------------------------------------------------
    # Use optionalAttrs to keep types correct.

    home.sessionVariables =
      # Only set BROWSER if we want Brave as default
      (lib.optionalAttrs config.my.browser.brave.setAsDefault {
        BROWSER = lib.mkDefault "brave-launcher";
      })
      # Always-on environment variables
      // {
        BRAVE_DISABLE_FONT_SUBPIXEL_POSITIONING = "1";
      }
      # VA-API driver when hardware acceleration is enabled
      // (lib.optionalAttrs (config.my.browser.brave.enableHardwareAcceleration && vaApiDriver != "") {
        LIBVA_DRIVER_NAME = lib.mkDefault vaApiDriver;
      })
      # Wayland-specific variables
      // (lib.optionalAttrs isWayland {
        NIXOS_OZONE_WL    = "1";
        MOZ_ENABLE_WAYLAND = "1";
      });

    # -------------------------------------------------------------------------
    # Ensure profile directory exists (do not manage its contents)
    # -------------------------------------------------------------------------

    home.file."${profilePath}/.keep".text = "";

    # -------------------------------------------------------------------------
    # Desktop entry (uses brave-launcher)
    # -------------------------------------------------------------------------

    xdg.desktopEntries.brave-browser = lib.mkIf config.my.browser.brave.setAsDefault {
      name        = "Brave Browser";
      comment     = "Browse the Web with Brave";
      genericName = "Web Browser";
      exec        = "brave-launcher %U";
      icon        = "brave-browser";
      categories  = [ "Network" "WebBrowser" ];

      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/xml"
        "application/rss+xml"
        "application/rdf+xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/ftp"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ];

      actions = {
        "new-window" = {
          name = "New Window";
          exec = "brave-launcher --new-window";
        };
        "new-private-window" = {
          name = "New Private Window";
          exec = "brave-launcher --incognito";
        };
      };
    };

    # -------------------------------------------------------------------------
    # Optional: automated cache cleanup (tmp/lock files only)
    # -------------------------------------------------------------------------

    systemd.user.services.brave-cleanup = lib.mkIf config.my.browser.brave.enableAutoCleanup {
      Unit = {
        Description   = "Brave Browser Cache Cleanup Service";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
        After         = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find "$HOME/.cache/BraveSoftware" -type f \( -name "*.tmp" -o -name "*.lock" \) -mtime +7 -delete 2>/dev/null || true'
        '';

        PrivateTmp      = true;
        NoNewPrivileges = true;
        MemoryMax       = "256M";
        CPUQuota        = "50%";
      };
    };

    systemd.user.timers.brave-cleanup = lib.mkIf config.my.browser.brave.enableAutoCleanup {
      Unit = {
        Description   = "Weekly Brave Browser Cache Cleanup";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
      };

      Timer = {
        OnCalendar         = "weekly";
        OnBootSec          = "1h";
        Persistent         = true;
        RandomizedDelaySec = "2h";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # -------------------------------------------------------------------------
    # Shell aliases
    # -------------------------------------------------------------------------

    home.shellAliases = {
      # Normal launch (with all flags)
      brave = "brave-launcher";

      # Development mode (separate user data dir)
      brave-dev =
        "brave-launcher --disable-web-security --user-data-dir=/tmp/brave-dev";

      # Clean mode: no extensions, incognito
      brave-clean =
        "brave-launcher --disable-extensions --incognito";

      # Specific profile (still uses launcher flags)
      brave-profile =
        "brave-launcher --profile-directory='${config.my.browser.brave.profile}'";

      # Debug logging
      brave-debug =
        "brave-launcher --enable-logging --v=1";

      # Safe mode: no extensions, no GPU
      brave-safe =
        "brave-launcher --disable-extensions --disable-gpu";

      # Manual cache reset (tmp/lock files)
      brave-reset-cache =
        "${pkgs.findutils}/bin/find ~/.cache/BraveSoftware -type f \\( -name '*.tmp' -o -name '*.lock' \\) -delete 2>/dev/null || true";
    };
  };
}
