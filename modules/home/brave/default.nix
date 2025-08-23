# modules/home/brave/default.nix
# ==============================================================================
# Brave Browser Configuration
# ==============================================================================
# This configuration manages Brave browser installation and setup including:
# - Browser package installation with advanced flags
# - Default application associations
# - MIME type handlers for web content
# - URL scheme handlers
# - Extensions management
# - Catppuccin theming integration
# - Performance and security optimizations
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  system = pkgs.system;
  
  # Detect if we're using Wayland
  isWayland = (config.my.desktop.wayland.enable or false) || 
              (config.services.xserver.displayManager.gdm.wayland or false) || 
              (builtins.getEnv "XDG_SESSION_TYPE" == "wayland") || 
              true; # Default to wayland for modern setups
  
  # Detect desktop environment for optimizations
  isHyprland = config.my.desktop.hyprland.enable or false;
  isGnome = config.services.xserver.desktopManager.gnome.enable or false;
  
in {
  imports = [
    ./extensions.nix
    ./theme.nix
  ];
  
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
    
    manageBookmarks = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Manage bookmarks declaratively";
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
  };
  
  config = lib.mkIf config.my.browser.brave.enable {
    # Configure default application associations
    xdg.mimeApps = lib.mkIf config.my.browser.brave.setAsDefault {
      enable = true;
      defaultApplications = {
        # HTTP/HTTPS protocols
        "x-scheme-handler/http" = ["brave-browser.desktop"];
        "x-scheme-handler/https" = ["brave-browser.desktop"];
        
        # HTML content types
        "text/html" = ["brave-browser.desktop"];
        "application/xhtml+xml" = ["brave-browser.desktop"];
        
        # Browser-specific schemes
        "x-scheme-handler/about" = ["brave-browser.desktop"];
        "x-scheme-handler/unknown" = ["brave-browser.desktop"];
        
        # Additional web content types
        "application/x-extension-htm" = ["brave-browser.desktop"];
        "application/x-extension-html" = ["brave-browser.desktop"];
        "application/x-extension-shtml" = ["brave-browser.desktop"];
        "application/x-extension-xht" = ["brave-browser.desktop"];
        "application/x-extension-xhtml" = ["brave-browser.desktop"];
      };
    };
    
    # ==========================================================================
    # Brave Specific Configuration
    # ==========================================================================
    programs.chromium = {
      enable = true;
      package = config.my.browser.brave.package;
      
      # Brave command line arguments for optimal performance and functionality
      commandLineArgs = [
        # Core Performance flags
        "--disable-extensions-http-throttling"
        "--disable-background-timer-throttling"
        "--disable-backgrounding-occluded-windows"
        "--disable-renderer-backgrounding"
        
        # UI/UX improvements
        "--disable-default-apps"
        "--no-default-browser-check"
        "--no-first-run"
        "--disable-component-update"
        
        # Theme and appearance
        "--force-dark-mode"
        "--enable-features=WebUIDarkMode"
        
        # Language and region
        "--lang=en-US"
        "--accept-lang=en-US,tr-TR"
        
      ] 
      # Hardware acceleration flags
      ++ lib.optionals config.my.browser.brave.enableHardwareAcceleration [
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--ignore-gpu-blocklist"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "--enable-accelerated-video-decode"
        "--enable-accelerated-video-encode"
      ]
      # Privacy flags (strict mode)
      ++ lib.optionals config.my.browser.brave.enableStrictPrivacy [
        "--disable-background-networking"
        "--disable-sync"
        "--disable-speech-api"
        "--disable-web-security"
        "--disable-features=AudioServiceOutOfProcess"
        "--disable-background-sync"
      ]
      # Wayland support flags
      ++ lib.optionals isWayland [
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
        "--enable-features=UseOzonePlatform"
        "--gtk-version=4"
      ]
      # Hyprland specific optimizations
      ++ lib.optionals isHyprland [
        "--enable-features=WaylandWindowDecorations"
        "--disable-features=UseChromeOSDirectVideoDecoder"
      ]
      # GNOME integration
      ++ lib.optionals isGnome [
        "--enable-features=MiddleClickAutoscroll"
      ]
      # Catppuccin specific flags
      ++ lib.optionals (config.catppuccin.enable or config.my.browser.brave.enableCatppuccinTheme) [
        "--force-prefers-color-scheme=dark"
        "--enable-features=WebContentsForceDark"
      ];
    };
    
    # ==========================================================================
    # System Integration
    # ==========================================================================
    
    # Environment variables for better integration
    home.sessionVariables = {
      # Default browser
      BROWSER = lib.mkIf config.my.browser.brave.setAsDefault "brave";
      # Better font rendering
      BRAVE_DISABLE_FONT_SUBPIXEL_POSITIONING = "1";
      # Enable VA-API for hardware acceleration
      LIBVA_DRIVER_NAME = lib.mkIf config.my.browser.brave.enableHardwareAcceleration "iHD";
    } // lib.optionalAttrs isWayland {
      # Wayland specific variables
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
    
    # Desktop file customization
    xdg.desktopEntries.brave-browser = lib.mkIf config.my.browser.brave.setAsDefault {
      name = "Brave Browser";
      comment = "Browse the Web with Brave";
      genericName = "Web Browser";
      exec = "brave %U";
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
          exec = "brave --new-window";
        };
        "new-private-window" = {
          name = "New Private Window";
          exec = "brave --incognito";
        };
      };
    };
    
    # ==========================================================================
    # Profile Management
    # ==========================================================================
    
    # Create profile directory structure
    home.file.".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/.keep".text = "";
    
    # Systemd user service for cleanup (optional)
    systemd.user.services.brave-cleanup = {
      Unit = {
        Description = "Brave Browser Cache Cleanup";
        After = [ "graphical-session.target" ];
      };
      
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'find ~/.cache/BraveSoftware -name \"*.tmp\" -delete 2>/dev/null || true'";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    
    # ==========================================================================
    # Shell Aliases
    # ==========================================================================
    
    home.shellAliases = {
      brave-dev = "brave --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=/tmp/brave-dev";
      brave-clean = "brave --disable-extensions --disable-plugins --incognito";
      brave-profile = "brave --profile-directory='${config.my.browser.brave.profile}'";
    };
    
  };
}

