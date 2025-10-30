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
# - Automated cache cleanup with systemd timers
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  system = pkgs.system;
  
  # ==========================================================================
  # Desktop Environment Detection
  # ==========================================================================
  
  # Detect if we're using Wayland - checks multiple sources for accuracy
  # Priority: explicit config > display manager > session environment
  isWayland = (config.my.desktop.wayland.enable or false) || 
              (config.services.xserver.displayManager.gdm.wayland or false) || 
              (builtins.getEnv "XDG_SESSION_TYPE" == "wayland");
  
  # Detect specific desktop environments for targeted optimizations
  isHyprland = config.my.desktop.hyprland.enable or false;
  isGnome = config.services.xserver.desktopManager.gnome.enable or false;
  
in {
  imports = [
    ./extensions.nix
    ./theme.nix
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
  
  # ==========================================================================
  # Main Configuration
  # ==========================================================================
  
  config = lib.mkIf config.my.browser.brave.enable {
    
    # ========================================================================
    # Default Application Associations
    # ========================================================================
    
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
    
    # ========================================================================
    # Brave Browser Configuration
    # ========================================================================
    
    programs.chromium = {
      enable = true;
      package = config.my.browser.brave.package;
      
      # ======================================================================
      # Command Line Arguments
      # ======================================================================
      # Optimized for performance, privacy, and stability
      
      commandLineArgs = [
        # --------------------------------------------------------------------
        # Core Performance Optimizations
        # --------------------------------------------------------------------
        "--disable-extensions-http-throttling"      # Faster extension loads
        
        # --------------------------------------------------------------------
        # Cache Management
        # --------------------------------------------------------------------
        "--disk-cache-size=268435456"               # 256 MB disk cache limit
        "--media-cache-size=134217728"              # 128 MB media cache limit
        
        # --------------------------------------------------------------------
        # Modern Web Platform Features
        # --------------------------------------------------------------------
        "--enable-features=BackForwardCache"        # Instant back/forward navigation
        "--enable-features=QuietNotificationPrompts" # Less intrusive notifications
        "--enable-smooth-scrolling"                 # Smooth scrolling experience
        "--enable-features=OverlayScrollbar"        # Modern overlay scrollbars
        "--enable-features=TabFreeze"               # Suspend inactive tabs to save resources
        
        # --------------------------------------------------------------------
        # UI/UX Improvements
        # --------------------------------------------------------------------
        "--disable-default-apps"                    # No unwanted default apps
        "--no-default-browser-check"                # Skip default browser prompt
        "--no-first-run"                            # Skip first run experience
        
        # --------------------------------------------------------------------
        # Theme and Appearance
        # --------------------------------------------------------------------
        "--enable-features=WebUIDarkMode"           # Dark mode for browser UI
        
        # --------------------------------------------------------------------
        # Language and Region Settings
        # --------------------------------------------------------------------
        "--lang=en-US"                              # Primary language
        "--accept-lang=en-US,tr-TR"                 # Accepted languages
        
      ] 
      # ======================================================================
      # Conditional Hardware Acceleration Flags
      # ======================================================================
      ++ lib.optionals config.my.browser.brave.enableHardwareAcceleration [
        "--enable-gpu-rasterization"                # GPU-accelerated rendering
        "--enable-zero-copy"                        # Efficient GPU memory usage
        "--ignore-gpu-blocklist"                    # Force GPU usage
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL" # Full VA-API support
        "--enable-accelerated-video-decode"         # Hardware video decoding
        "--enable-accelerated-video-encode"         # Hardware video encoding
        "--use-gl=egl"                              # Use EGL backend for Wayland
      ]
      # ======================================================================
      # Conditional Privacy Flags (Strict Mode)
      # ======================================================================
      # Note: These flags enhance privacy but may break some website features
      ++ lib.optionals config.my.browser.brave.enableStrictPrivacy [
        "--disable-background-networking"           # No background connections
        "--disable-sync"                            # Disable sync services
        "--disable-speech-api"                      # Disable speech recognition
      ]
      # ======================================================================
      # Wayland-Specific Flags
      # ======================================================================
      ++ lib.optionals isWayland [
        "--ozone-platform=wayland"                  # Use Wayland backend
        "--enable-wayland-ime"                      # Wayland input method support
        "--enable-features=UseOzonePlatform"        # Enable Ozone platform
        "--gtk-version=4"                           # Use GTK4 for better Wayland support
      ]
      # ======================================================================
      # Hyprland-Specific Optimizations
      # ======================================================================
      ++ lib.optionals isHyprland [
        "--enable-features=WaylandWindowDecorations" # Native window decorations
        "--disable-features=UseChromeOSDirectVideoDecoder" # Better video compatibility
      ]
      # ======================================================================
      # GNOME Integration
      # ======================================================================
      ++ lib.optionals isGnome [
        "--enable-features=MiddleClickAutoscroll"   # GNOME-style middle-click scrolling
      ]
      # ======================================================================
      # Catppuccin Theme Integration
      # ======================================================================
      ++ lib.optionals (config.catppuccin.enable or config.my.browser.brave.enableCatppuccinTheme) [
        "--force-prefers-color-scheme=dark"         # Force dark color scheme
        "--enable-features=WebContentsForceDark"    # Force dark mode on websites
      ];
    };
    
    # ========================================================================
    # System Integration
    # ========================================================================
    
    # Environment variables for better browser integration
    home.sessionVariables = {
      # Default browser
      BROWSER = lib.mkIf config.my.browser.brave.setAsDefault "brave";
      
      # Better font rendering - disables subpixel positioning for clearer text
      BRAVE_DISABLE_FONT_SUBPIXEL_POSITIONING = "1";
      
      # Enable VA-API for hardware acceleration (Intel Gen 8+ / Broadwell and newer)
      # Use "i965" for older Intel GPUs (Gen 7 and below)
      LIBVA_DRIVER_NAME = lib.mkIf config.my.browser.brave.enableHardwareAcceleration "iHD";
    } 
    # Wayland-specific environment variables
    // lib.optionalAttrs isWayland {
      NIXOS_OZONE_WL = "1";                         # Enable Ozone Wayland support
      MOZ_ENABLE_WAYLAND = "1";                     # Mozilla Wayland support (for compatibility)
    };
    
    # ========================================================================
    # Managed Browser Policies (JSON-based configuration)
    # ========================================================================
    # Note: These are applied via JSON files in the profile directory
    # Brave reads policies from: ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
    
    home.file.".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/managed_preferences.json".text = builtins.toJSON {
      # WebRTC Privacy
      webrtc = {
        ip_handling_policy = "disable_non_proxied_udp";  # Prevent WebRTC IP leaks
      };
      
      # Cookie Management
      profile = {
        block_third_party_cookies = true;           # Block 3rd party cookies
        default_content_setting_values = {
          cookies = 1;                              # Allow 1st party cookies only
        };
      };
      
      # Privacy Enhancements
      spellcheck = {
        enabled = false;                            # Disable spellcheck (no data sent to Google)
      };
      search = {
        suggest_enabled = false;                    # Disable search suggestions
      };
      credentials_enable_service = false;           # Disable built-in password manager
      
      # Network Privacy
      dns_over_https = {
        mode = "secure";                            # Force DNS-over-HTTPS
      };
      
      # Additional Security
      ssl = {
        error_override_allowed = false;             # Don't allow bypassing SSL errors
      };
      safebrowsing = {
        enabled = true;
        enhanced = true;                            # Enhanced protection mode
      };
    };
    
    # ========================================================================
    # Desktop Entry Customization
    # ========================================================================
    
    xdg.desktopEntries.brave-browser = lib.mkIf config.my.browser.brave.setAsDefault {
      name = "Brave Browser";
      comment = "Browse the Web with Brave";
      genericName = "Web Browser";
      exec = "brave %U";
      icon = "brave-browser";
      categories = [ "Network" "WebBrowser" ];
      
      # Supported MIME types
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
      
      # Desktop actions (right-click menu)
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
    
    # ========================================================================
    # Profile Management
    # ========================================================================
    
    # Ensure profile directory exists
    home.file.".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/.keep".text = "";
    
    # ========================================================================
    # Automated Cache Cleanup
    # ========================================================================
    
    # Systemd service for cache cleanup
    systemd.user.services.brave-cleanup = {
      Unit = {
        Description = "Brave Browser Cache Cleanup Service";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
        After = [ "graphical-session.target" ];
      };
      
      Service = {
        Type = "oneshot";
        # Clean temporary files and old cache
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find ~/.cache/BraveSoftware -name \"*.tmp\" -o -name \"*.lock\" -delete 2>/dev/null || true'";
        
        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        
        # Resource limits
        MemoryMax = "256M";
        CPUQuota = "50%";
      };
    };
    
    # Systemd timer for scheduled cleanup
    systemd.user.timers.brave-cleanup = {
      Unit = {
        Description = "Daily Brave Browser Cache Cleanup";
        Documentation = [ "https://github.com/kenanpelit/nixosc" ];
      };
      
      Timer = {
        # Run daily at 3 AM
        OnCalendar = "daily";
        # Also run 15 minutes after boot if missed
        OnBootSec = "15min";
        # Catch up on missed runs
        Persistent = true;
        # Randomize start time by up to 1 hour for system load distribution
        RandomizedDelaySec = "1h";
      };
      
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
    
    # ========================================================================
    # Shell Aliases
    # ========================================================================
    
    home.shellAliases = {
      # Development mode with relaxed security (for testing only)
      brave-dev = "brave --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=/tmp/brave-dev";
      
      # Clean mode - no extensions or plugins, incognito
      brave-clean = "brave --disable-extensions --disable-plugins --incognito";
      
      # Launch with specific profile
      brave-profile = "brave --profile-directory='${config.my.browser.brave.profile}'";
      
      # Debug mode - verbose logging
      brave-debug = "brave --enable-logging --v=1";
      
      # Safe mode - minimal features for troubleshooting
      brave-safe = "brave --disable-extensions --disable-plugins --disable-gpu";
    };
    
  };
}

