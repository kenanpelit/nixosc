# modules/home/vivaldi/default.nix
# ==============================================================================
# Vivaldi Browser Configuration
# ==============================================================================

{ inputs, pkgs, config, lib, ... }:

let
  system = pkgs.system;

  # Detect Wayland session (default to Wayland on modern setups)
  isWayland =
    (config.my.desktop.wayland.enable or false) ||
    (config.services.xserver.displayManager.gdm.wayland or false) ||
    (builtins.getEnv "XDG_SESSION_TYPE" == "wayland") ||
    true;

  # Detect desktop environments for minor tweaks
  isHyprland = config.my.desktop.hyprland.enable or false;
  isGnome    = config.services.xserver.desktopManager.gnome.enable or false;

in {
  imports = [
    ./extensions.nix
    ./theme.nix
  ];

  options.my.browser.vivaldi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Vivaldi browser installation and configuration";
    };

    setAsDefault = lib.mkOption {
      type = lib.types.bool;
      default = false; # do NOT claim default browser by default
      description = "Set Vivaldi as the default web browser";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vivaldi;
      description = "The Vivaldi browser package to install";
    };

    enableCatppuccinTheme = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Catppuccin theme integration";
    };

    enableMailCalendar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep Vivaldi's integrated Mail/Calendar/RSS enabled (UI features).";
    };

    manageBookmarks = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Manage bookmarks declaratively (placeholder switch).";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = "Browser profile directory name under ~/.config/vivaldi/";
    };

    enableHardwareAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GPU hardware acceleration (VA-API on Linux).";
    };

    enableStrictPrivacy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable strict privacy flags (may break some sites).";
    };

    # IMPORTANT: Keep this false so Brave owns programs.chromium.*
    useChromiumWrapper = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Home Manager's Chromium wrapper to inject flags for Vivaldi.";
    };
  };

  config = lib.mkIf config.my.browser.vivaldi.enable {

    # Ensure Vivaldi itself + codecs are installed (without touching programs.chromium)
    home.packages = [
      config.my.browser.vivaldi.package
      pkgs.vivaldi-ffmpeg-codecs
    ];

    # Default application associations (only if explicitly requested)
    xdg.mimeApps = lib.mkIf config.my.browser.vivaldi.setAsDefault {
      enable = true;
      defaultApplications = {
        # Protocol handlers
        "x-scheme-handler/http"    = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/https"   = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/about"   = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/unknown" = [ "vivaldi-stable.desktop" ];

        # Content types
        "text/html"                    = [ "vivaldi-stable.desktop" ];
        "application/xhtml+xml"        = [ "vivaldi-stable.desktop" ];
        "application/x-extension-htm"  = [ "vivaldi-stable.desktop" ];
        "application/x-extension-html" = [ "vivaldi-stable.desktop" ];
        "application/x-extension-shtml"= [ "vivaldi-stable.desktop" ];
        "application/x-extension-xht"  = [ "vivaldi-stable.desktop" ];
        "application/x-extension-xhtml"= [ "vivaldi-stable.desktop" ];
      };
    };

    # ==========================================================================
    # Command-line flags via the Chromium wrapper (ENABLE ONLY IF asked)
    # ==========================================================================
    programs.chromium = lib.mkIf config.my.browser.vivaldi.useChromiumWrapper {
      enable  = true;
      package = config.my.browser.vivaldi.package;

      commandLineArgs =
        [
          # Core performance tweaks
          "--disable-extensions-http-throttling"
          "--disable-background-timer-throttling"
          "--disable-backgrounding-occluded-windows"
          "--disable-renderer-backgrounding"

          # UX
          "--disable-default-apps"
          "--no-default-browser-check"
          "--no-first-run"
          "--disable-component-update"

          # Theme/appearance
          "--force-dark-mode"
          "--enable-features=WebUIDarkMode"

          # Language and region
          "--lang=en-US"
          "--accept-lang=en-US,tr-TR"
        ]
        # Hardware acceleration
        ++ lib.optionals config.my.browser.vivaldi.enableHardwareAcceleration [
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--ignore-gpu-blocklist"
          "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
          "--enable-accelerated-video-decode"
          "--enable-accelerated-video-encode"
        ]
        # Privacy (strict mode; WARNING: some flags may break sites)
        ++ lib.optionals config.my.browser.vivaldi.enableStrictPrivacy [
          "--disable-background-networking"
          "--disable-sync"
          "--disable-speech-api"
          "--disable-web-security" # NOTE: very strict; consider for dev only
          "--disable-features=AudioServiceOutOfProcess"
          "--disable-background-sync"
        ]
        # Wayland support
        ++ lib.optionals isWayland [
          "--ozone-platform=wayland"
          "--enable-wayland-ime"
          "--enable-features=UseOzonePlatform"
          "--gtk-version=4"
        ]
        # Hyprland optimizations
        ++ lib.optionals isHyprland [
          "--enable-features=WaylandWindowDecorations"
          "--disable-features=UseChromeOSDirectVideoDecoder"
        ]
        # GNOME integration
        ++ lib.optionals isGnome [
          "--enable-features=MiddleClickAutoscroll"
        ]
        # Catppuccin-friendly darkening
        ++ lib.optionals (config.catppuccin.enable or config.my.browser.vivaldi.enableCatppuccinTheme) [
          "--force-prefers-color-scheme=dark"
          "--enable-features=WebContentsForceDark"
        ];
    };

    # ==========================================================================
    # Environment integration
    # ==========================================================================
    home.sessionVariables =
      {
        # Do NOT export BROWSER here (Brave wins)
        LIBVA_DRIVER_NAME = lib.mkIf config.my.browser.vivaldi.enableHardwareAcceleration "iHD";
      }
      // lib.optionalAttrs isWayland {
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
      };

    # Desktop entry override (active only if setAsDefault = true)
    xdg.desktopEntries.vivaldi = lib.mkIf config.my.browser.vivaldi.setAsDefault {
      name = "Vivaldi";
      comment = "Browse the Web with Vivaldi";
      genericName = "Web Browser";
      exec = "vivaldi %U";
      icon = "vivaldi";
      categories = [ "Network" "WebBrowser" ];
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
          exec = "vivaldi --new-window";
        };
        "new-private-window" = {
          name = "New Private Window";
          exec = "vivaldi --incognito";
        };
      };
    };

    # ==========================================================================
    # Profile management
    # ==========================================================================
    home.file.".config/vivaldi/${config.my.browser.vivaldi.profile}/.keep".text = "";

    # Optional: cache cleanup service
    systemd.user.services.vivaldi-cleanup = {
      Unit = {
        Description = "Vivaldi Browser Cache Cleanup";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'find ~/.cache/vivaldi -name \"*.tmp\" -delete 2>/dev/null || true'";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # ==========================================================================
    # Shell aliases
    # ==========================================================================
    home.shellAliases = {
      vivaldi-dev     = "vivaldi --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=/tmp/vivaldi-dev";
      vivaldi-clean   = "vivaldi --disable-extensions --disable-plugins --incognito";
      vivaldi-profile = "vivaldi --profile-directory='${config.my.browser.vivaldi.profile}'";
    };
  };
}


