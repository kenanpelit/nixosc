# modules/home/brave/default.nix
# ==============================================================================
# Brave Browser Configuration
# ==============================================================================
# This configuration manages Brave browser installation and setup including:
# - Browser package installation
# - Default application associations
# - MIME type handlers for web content
# - URL scheme handlers
# - Extensions management
# - Catppuccin theming integration
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
let
  system = pkgs.system;
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
      };
    };
    
    # ==========================================================================
    # Brave Specific Configuration
    # ==========================================================================
    programs.chromium = {
      enable = true;
      package = config.my.browser.brave.package;
      
      # Brave command line arguments for better performance and theming
      commandLineArgs = [
        # Performance flags
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--ignore-gpu-blocklist"
        
        # Privacy flags
        "--disable-background-networking"
        "--disable-background-timer-throttling"
        "--disable-backgrounding-occluded-windows"
        
        # Theme flags
        "--force-dark-mode"
        "--enable-features=WebUIDarkMode"
        
        # Wayland support
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
      ] ++ lib.optionals (config.catppuccin.enable or false) [
        # Catppuccin specific flags
        "--force-prefers-color-scheme=dark"
      ];
    };
  };
}

