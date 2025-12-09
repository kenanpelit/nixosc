# modules/home/chrome/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for chrome.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ inputs, pkgs, config, lib, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.my.browser.chrome-preview;

  # ---------------------------------------------------------------------------
  # Desktop environment detection
  # ---------------------------------------------------------------------------
  isWayland =
    (config.my.desktop.wayland.enable or false)
    || (config.services.xserver.displayManager.gdm.wayland or false)
    || (builtins.getEnv "XDG_SESSION_TYPE" == "wayland");

  isHyprland = config.my.desktop.hyprland.enable or false;
  isGnome    = config.services.xserver.desktopManager.gnome.enable or false;

  # ---------------------------------------------------------------------------
  # Hardware acceleration detection
  # ---------------------------------------------------------------------------
  vaApiDriver =
    if cfg.enableHardwareAcceleration
    then "iHD"
    else "";

  # ---------------------------------------------------------------------------
  # Package / desktop file / profile paths
  # ---------------------------------------------------------------------------
  previews = inputs.browser-previews.packages.${system};

  chromePackage =
    if cfg.variant == "beta" then previews.google-chrome-beta
    else if cfg.variant == "dev" then previews.google-chrome-dev
    else previews.google-chrome;

  chromeBinary =
    if cfg.variant == "beta" then "google-chrome-beta"
    else if cfg.variant == "dev" then "google-chrome-unstable"
    else "google-chrome-stable";

  desktopFile =
    if cfg.variant == "beta" then "google-chrome-beta.desktop"
    else if cfg.variant == "dev" then "google-chrome-dev.desktop"
    else "google-chrome.desktop";

  configDir =
    if cfg.variant == "beta" then ".config/google-chrome-beta"
    else if cfg.variant == "dev" then ".config/google-chrome-unstable"
    else ".config/google-chrome";

  cacheDir =
    if cfg.variant == "beta" then ".cache/google-chrome-beta"
    else if cfg.variant == "dev" then ".cache/google-chrome-unstable"
    else ".cache/google-chrome";

  profilePath = "${configDir}/${cfg.profile}";

  # ---------------------------------------------------------------------------
  # Feature flags (computed in Nix, used by launcher)
  # ---------------------------------------------------------------------------
  baseFeatures = [
    "BackForwardCache"
    "OverlayScrollbar"
    "TabFreeze"
    "WebUIDarkMode"
    "AutoDarkMode"
  ];

  enableFeatures =
    lib.concatStringsSep "," (
      baseFeatures
      ++ lib.optionals cfg.enableHardwareAcceleration [
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
  # ============================================================================
  # Module options
  # ============================================================================

  options.my.browser.chrome-preview = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Chrome preview browser installation and configuration.";
    };

    variant = lib.mkOption {
      type = lib.types.enum [ "stable" "beta" "dev" ];
      default = "stable";
      description = "Chrome variant to install (stable, beta, or dev).";
    };

    setAsDefault = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set Chrome preview as the default web browser.";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = "Chrome profile directory name (e.g. \"Default\", \"Profile 1\").";
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

    enableAutoCleanup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automated cleanup for Chrome cache (tmp/lock files only).";
    };
  };

  # ============================================================================
  # Main configuration
  # ============================================================================

  config = lib.mkIf cfg.enable {

    # -------------------------------------------------------------------------
    # Package installation
    # -------------------------------------------------------------------------

    home.packages = [ chromePackage ];

    # -------------------------------------------------------------------------
    # Default application associations (xdg-mime)
    # -------------------------------------------------------------------------

    xdg.mimeApps = lib.mkIf cfg.setAsDefault {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http"    = [ desktopFile ];
        "x-scheme-handler/https"   = [ desktopFile ];
        "text/html"                = [ desktopFile ];
        "application/xhtml+xml"    = [ desktopFile ];
        "x-scheme-handler/about"   = [ desktopFile ];
        "x-scheme-handler/unknown" = [ desktopFile ];
      };
    };

    # -------------------------------------------------------------------------
    # Chrome launch wrapper
    # -------------------------------------------------------------------------

    home.file.".local/bin/chrome-launcher" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Google Chrome Launcher with deterministic flags (NixOS / Home Manager)

        if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
          cat <<EOF
Chrome Launcher (NixOS / Home Manager)

Usage:
  chrome-launcher [extra Chrome flags...] [URL...]

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
  BROWSER = chrome-launcher        (if setAsDefault = true)
  LIBVA_DRIVER_NAME = ''${vaApiDriver or "auto"}

EOF
          exit 0
        fi

        CHROME_FLAGS=()

        # Performance-related flags
        CHROME_FLAGS+=(
          --disable-extensions-http-throttling
          --disk-cache-size=${toString cfg.diskCacheSize}
          --media-cache-size=${toString cfg.mediaCacheSize}
          --disable-default-apps
          --no-default-browser-check
          --no-first-run
          --enable-smooth-scrolling
          --lang=en-US
          --accept-lang=en-US,tr-TR
        )

        # Hardware acceleration flags (if enabled)
        ${lib.optionalString cfg.enableHardwareAcceleration ''
        CHROME_FLAGS+=(
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
        CHROME_FLAGS+=(
          --ozone-platform=wayland
          --enable-wayland-ime
          --gtk-version=4
        )
        ''}

        # Strict privacy mode (optional)
        ${lib.optionalString cfg.enableStrictPrivacy ''
        CHROME_FLAGS+=(
          --disable-background-networking
          --disable-sync
          --disable-speech-api
        )
        ''}

        # Deterministic feature flags (computed in Nix)
        CHROME_FLAGS+=( "--enable-features=${enableFeatures}" )
        ${lib.optionalString (disabledFeatures != "") ''
        CHROME_FLAGS+=( "--disable-features=${disabledFeatures}" )
        ''}

        exec ${chromePackage}/bin/${chromeBinary} "''${CHROME_FLAGS[@]}" "$@"
      '';
    };

    # -------------------------------------------------------------------------
    # Session variables
    # -------------------------------------------------------------------------

    home.sessionVariables =
      (lib.optionalAttrs cfg.setAsDefault {
        BROWSER = lib.mkDefault "chrome-launcher";
      })
      // {
        CHROME_WRAPPER = "chrome-launcher";
      }
      // (lib.optionalAttrs (cfg.enableHardwareAcceleration && vaApiDriver != "") {
        LIBVA_DRIVER_NAME = lib.mkDefault vaApiDriver;
      })
      // (lib.optionalAttrs isWayland {
        NIXOS_OZONE_WL     = "1";
        MOZ_ENABLE_WAYLAND = "1";
      })
      // (lib.optionalAttrs isGnome {
        CHROME_DESKTOP = desktopFile;
      });

    # -------------------------------------------------------------------------
    # Ensure profile directory exists (do not manage its contents)
    # -------------------------------------------------------------------------

    home.file."${profilePath}/.keep".text = "";

    # -------------------------------------------------------------------------
    # Desktop entry (uses chrome-launcher)
    # -------------------------------------------------------------------------

    xdg.desktopEntries."chrome-preview" = lib.mkIf cfg.setAsDefault {
      name        = "Google Chrome";
      comment     = "Browse the Web with Google Chrome";
      genericName = "Web Browser";
      exec        = "chrome-launcher %U";
      icon        = "google-chrome";
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
          exec = "chrome-launcher --new-window";
        };
        "new-private-window" = {
          name = "New Incognito Window";
          exec = "chrome-launcher --incognito";
        };
      };
    };

    # -------------------------------------------------------------------------
    # Optional: automated cache cleanup (tmp/lock files only)
    # -------------------------------------------------------------------------

    systemd.user.services.chrome-cleanup = lib.mkIf cfg.enableAutoCleanup {
      Unit = {
        Description   = "Chrome Cache Cleanup Service";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
        After         = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find "$HOME/${cacheDir}" -type f \( -name "*.tmp" -o -name "*.lock" \) -mtime +7 -delete 2>/dev/null || true'
        '';

        PrivateTmp      = true;
        NoNewPrivileges = true;
        MemoryMax       = "256M";
        CPUQuota        = "50%";
      };
    };

    systemd.user.timers.chrome-cleanup = lib.mkIf cfg.enableAutoCleanup {
      Unit = {
        Description   = "Weekly Chrome Cache Cleanup";
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
      chrome = "chrome-launcher";
      chrome-clean = "chrome-launcher --disable-extensions --incognito";
      chrome-safe = "chrome-launcher --disable-extensions --disable-gpu";
      chrome-profile = "chrome-launcher --profile-directory='${cfg.profile}'";
      chrome-debug = "chrome-launcher --enable-logging --v=1";
      chrome-reset-cache =
        "${pkgs.findutils}/bin/find ~/${cacheDir} -type f \\( -name '*.tmp' -o -name '*.lock' \\) -delete 2>/dev/null || true";
    };
  };
}
