# modules/home/brave/default.nix
# ==============================================================================
# Brave Browser Configuration - Fixed Version
# ==============================================================================
# Bu konfigürasyon kullanıcı ayarlarını ve eklentileri koruyacak şekilde
# optimize edilmiştir. Ayarlar kullanıcının değişikliklerine açıktır.
#
# ÖNEMLİ DEĞİŞİKLİKLER:
# - Preferences dosyası artık force edilmiyor (kullanıcı ayarları korunuyor)
# - Extensions doğru şekilde yönetiliyor
# - Policy-based yaklaşım yerine öneri-bazlı yaklaşım
# - İlk kurulum için varsayılan ayarlar, sonrasında kullanıcıya bırakılıyor
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;

  # ==========================================================================
  # Desktop Environment Detection
  # ==========================================================================
  
  isWayland = (config.my.desktop.wayland.enable or false) ||
              (config.services.xserver.displayManager.gdm.wayland or false) ||
              (builtins.getEnv "XDG_SESSION_TYPE" == "wayland");

  isHyprland = config.my.desktop.hyprland.enable or false;
  isGnome = config.services.xserver.desktopManager.gnome.enable or false;

  # ==========================================================================
  # Hardware Acceleration Detection
  # ==========================================================================
  
  vaApiDriver =
    if config.my.browser.brave.enableHardwareAcceleration
    then "iHD"
    else "";

  # ==========================================================================
  # Browser Data Paths
  # ==========================================================================
  
  braveConfigDir = ".config/BraveSoftware/Brave-Browser";
  profilePath = "${braveConfigDir}/${config.my.browser.brave.profile}";
  
in {
  imports = [
    ./extensions.nix
    ./theme.nix
    ./initial-setup.nix
  ];

  # ==========================================================================
  # Module Options
  # ==========================================================================

  options.my.browser.brave = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Brave browser installation and configuration";
    };

    setAsDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set Brave as the default web browser";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.brave;
      description = "The Brave browser package to install";
    };

    enableCatppuccinTheme = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Catppuccin theme integration";
    };

    enableCrypto = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cryptocurrency wallet extensions";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = "Browser profile name";
    };

    enableHardwareAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GPU hardware acceleration";
    };

    enableStrictPrivacy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable strict privacy flags (may break some sites)";
    };

    diskCacheSize = lib.mkOption {
      type = lib.types.int;
      default = 268435456; # 256 MB
      description = "Disk cache size in bytes (default: 256 MB)";
    };

    mediaCacheSize = lib.mkOption {
      type = lib.types.int;
      default = 134217728; # 128 MB
      description = "Media cache size in bytes (default: 128 MB)";
    };

    manageExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically install and manage extensions";
    };

    enableAutoCleanup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automatic cache cleanup (may remove user data)";
    };
  };

  # ==========================================================================
  # Main Configuration
  # ==========================================================================

  config = lib.mkIf config.my.browser.brave.enable {

    # ========================================================================
    # Package Installation
    # ========================================================================
    
    home.packages = [ config.my.browser.brave.package ];

    # ========================================================================
    # Default Application Associations
    # ========================================================================

    xdg.mimeApps = lib.mkIf config.my.browser.brave.setAsDefault {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = ["brave-browser.desktop"];
        "x-scheme-handler/https" = ["brave-browser.desktop"];
        "text/html" = ["brave-browser.desktop"];
        "application/xhtml+xml" = ["brave-browser.desktop"];
        "x-scheme-handler/about" = ["brave-browser.desktop"];
        "x-scheme-handler/unknown" = ["brave-browser.desktop"];
        "application/x-extension-htm" = ["brave-browser.desktop"];
        "application/x-extension-html" = ["brave-browser.desktop"];
        "application/x-extension-shtml" = ["brave-browser.desktop"];
        "application/x-extension-xht" = ["brave-browser.desktop"];
        "application/x-extension-xhtml" = ["brave-browser.desktop"];
      };
    };

    # ========================================================================
    # Brave Launch Wrapper
    # ========================================================================
    # Brave'i doğru flag'lerle başlatan wrapper script
    
    home.file.".local/bin/brave-launcher" = {
      text = ''
        #!/usr/bin/env bash
        # Brave Browser Launcher with optimized flags
        
        BRAVE_FLAGS=(
          # Performance
          --disable-extensions-http-throttling
          --disk-cache-size=${toString config.my.browser.brave.diskCacheSize}
          --media-cache-size=${toString config.my.browser.brave.mediaCacheSize}
          
          # Modern Features
          --enable-features=BackForwardCache,QuietNotificationPrompts,TabFreeze
          --enable-smooth-scrolling
          --enable-features=OverlayScrollbar
          
          # UI/UX
          --disable-default-apps
          --no-default-browser-check
          --no-first-run
          
          # Theme
          --enable-features=WebUIDarkMode
          --force-prefers-color-scheme=dark
          --enable-features=AutoDarkMode
          
          # Language
          --lang=en-US
          --accept-lang=en-US,tr-TR
        )
        
        ${lib.optionalString config.my.browser.brave.enableHardwareAcceleration ''
        # Hardware Acceleration
        BRAVE_FLAGS+=(
          --enable-gpu-rasterization
          --enable-zero-copy
          --ignore-gpu-blocklist
          --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL
          --enable-accelerated-video-decode
          --enable-accelerated-video-encode
          --use-gl=egl
        )
        ''}
        
        ${lib.optionalString isWayland ''
        # Wayland Support
        BRAVE_FLAGS+=(
          --ozone-platform=wayland
          --enable-wayland-ime
          --enable-features=UseOzonePlatform
          --gtk-version=4
        )
        ''}
        
        ${lib.optionalString isHyprland ''
        # Hyprland Optimizations
        BRAVE_FLAGS+=(
          --enable-features=WaylandWindowDecorations
          --disable-features=UseChromeOSDirectVideoDecoder
        )
        ''}
        
        ${lib.optionalString config.my.browser.brave.enableStrictPrivacy ''
        # Privacy Mode
        BRAVE_FLAGS+=(
          --disable-background-networking
          --disable-sync
          --disable-speech-api
        )
        ''}
        
        # Launch Brave with all flags
        exec ${config.my.browser.brave.package}/bin/brave "''${BRAVE_FLAGS[@]}" "$@"
      '';
      executable = true;
    };

    # ========================================================================
    # System Integration
    # ========================================================================

    home.sessionVariables = {
      BROWSER = lib.mkIf config.my.browser.brave.setAsDefault (lib.mkDefault "brave-launcher");
      BRAVE_DISABLE_FONT_SUBPIXEL_POSITIONING = "1";
      LIBVA_DRIVER_NAME = lib.mkIf (config.my.browser.brave.enableHardwareAcceleration && vaApiDriver != "") 
        (lib.mkDefault vaApiDriver);
    }
    // lib.optionalAttrs isWayland {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # ========================================================================
    # Profile Directory Setup
    # ========================================================================
    # Profile dizininin var olduğundan emin ol ama içeriğini değiştirme
    
    home.file."${profilePath}/.keep".text = "";

    # ========================================================================
    # Desktop Entry
    # ========================================================================

    xdg.desktopEntries.brave-browser = lib.mkIf config.my.browser.brave.setAsDefault {
      name = "Brave Browser";
      comment = "Browse the Web with Brave";
      genericName = "Web Browser";
      exec = "brave-launcher %U";
      icon = "brave-browser";
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
          exec = "brave-launcher --new-window";
        };
        "new-private-window" = {
          name = "New Private Window";
          exec = "brave-launcher --incognito";
        };
      };
    };

    # ========================================================================
    # Optional: Automated Cache Cleanup
    # ========================================================================
    # Sadece explicitly istenirse aktif et

    systemd.user.services.brave-cleanup = lib.mkIf config.my.browser.brave.enableAutoCleanup {
      Unit = {
        Description = "Brave Browser Cache Cleanup Service";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        # Sadece temp ve lock dosyalarını temizle
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find ~/.cache/BraveSoftware -type f \\( -name \"*.tmp\" -o -name \"*.lock\" \\) -mtime +7 -delete 2>/dev/null || true'";
        
        PrivateTmp = true;
        NoNewPrivileges = true;
        MemoryMax = "256M";
        CPUQuota = "50%";
      };
    };

    systemd.user.timers.brave-cleanup = lib.mkIf config.my.browser.brave.enableAutoCleanup {
      Unit = {
        Description = "Weekly Brave Browser Cache Cleanup";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
      };

      Timer = {
        OnCalendar = "weekly";
        OnBootSec = "1h";
        Persistent = true;
        RandomizedDelaySec = "2h";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # ========================================================================
    # Shell Aliases
    # ========================================================================

    home.shellAliases = {
      # Normal başlatma
      brave = "brave-launcher";
      
      # Development mode
      brave-dev = "brave --disable-web-security --user-data-dir=/tmp/brave-dev";
      
      # Clean mode
      brave-clean = "brave --disable-extensions --incognito";
      
      # Specific profile
      brave-profile = "brave --profile-directory='${config.my.browser.brave.profile}'";
      
      # Debug mode
      brave-debug = "brave --enable-logging --v=1";
      
      # Safe mode
      brave-safe = "brave --disable-extensions --disable-gpu";
      
      # Reset cache (kullanıcı manuel olarak çalıştırabilir)
      brave-reset-cache = "${pkgs.findutils}/bin/find ~/.cache/BraveSoftware -type f \\( -name '*.tmp' -o -name '*.lock' \\) -delete";
    };

  };
}
