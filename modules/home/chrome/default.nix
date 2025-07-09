# modules/home/chrome/default.nix
# ==============================================================================
# Chrome Preview Browser Configuration
# ==============================================================================
# This configuration manages Chrome preview versions installation and setup including:
# - Chrome preview packages (stable, beta, dev)
# - Default application associations
# - MIME type handlers for web content
# - URL scheme handlers
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  system = pkgs.system;
in {
  options.my.browser.chrome-preview = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Chrome preview browser installation and configuration";
    };
    
    variant = lib.mkOption {
      type = lib.types.enum [ "stable" "beta" "dev" ];
      default = "stable";
      description = "Chrome variant to install (stable, beta, or dev)";
    };
    
    setAsDefault = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set Chrome preview as the default web browser (conflicts with other browsers)";
    };
  };

  config = lib.mkIf config.my.browser.chrome-preview.enable {
    # Install Chrome preview browser based on variant
    home.packages = with inputs.browser-previews.packages.${system}; [
      (if config.my.browser.chrome-preview.variant == "beta" then google-chrome-beta
       else if config.my.browser.chrome-preview.variant == "dev" then google-chrome-dev
       else google-chrome)
    ];

    # Configure default application associations
    xdg.mimeApps = lib.mkIf config.my.browser.chrome-preview.setAsDefault {
      enable = true;
      defaultApplications = 
        let
          desktopFile = 
            if config.my.browser.chrome-preview.variant == "beta" then "google-chrome-beta.desktop"
            else if config.my.browser.chrome-preview.variant == "dev" then "google-chrome-dev.desktop"
            else "google-chrome.desktop";
        in {
          # HTTP/HTTPS protocols
          "x-scheme-handler/http" = [desktopFile];
          "x-scheme-handler/https" = [desktopFile];
          
          # HTML content types
          "text/html" = [desktopFile];
          "application/xhtml+xml" = [desktopFile];
          
          # Browser-specific schemes
          "x-scheme-handler/about" = [desktopFile];
          "x-scheme-handler/unknown" = [desktopFile];
        };
    };
  };
}

