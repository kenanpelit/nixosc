# modules/home/firefox/default.nix
# ==============================================================================
# Firefox Core Configuration - Fixed for Home Manager Compatibility
# ==============================================================================
# This configuration manages Firefox browser setup including:
# - Extension management and installation
# - Search engines and custom shortcuts
# - Privacy and security settings
# - Browser behavior customization
# - Profile management
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username ? "kenan", ... }:
let
  cfg = config.my.browser.firefox;
  
  extensionsList = with pkgs.nur.repos.rycee.firefox-addons; [
    ublock-origin
    sponsorblock
    return-youtube-dislikes
    darkreader
    plasma-integration
    indie-wiki-buddy
    stylus
    canvasblocker
  ];
  
  searchConfig = let
    nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  in {
    "ecosia" = {
      icon = "https://www.ecosia.org/static/icons/favicon.ico";
      updateInterval = 24 * 60 * 60 * 1000;
      definedAliases = ["@e" "@ecosia"];
      urls = lib.singleton {
        template = "https://www.ecosia.org/search?q={searchTerms}";
      };
    };
    "Nix Packages" = {
      icon = nix-icon;
      definedAliases = ["@np"];
      urls = lib.singleton {
        template = "https://search.nixos.org/packages?type=packages&query={searchTerms}";
      };
    };
    "NixOS Options" = {
      icon = nix-icon;
      definedAliases = ["@no"];
      urls = lib.singleton {
        template = "https://search.nixos.org/options?type=packages&query={searchTerms}";
      };
    };
    "NixOS Wiki" = {
      icon = nix-icon;
      definedAliases = ["@nw"];
      urls = lib.singleton {
        template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
      };
    };
    "Nixpkgs PR Tracker" = {
      icon = nix-icon;
      definedAliases = ["@nprt"];
      urls = lib.singleton {
        template = "https://nixpk.gs/pr-tracker.html?pr={searchTerms}";
      };
    };
    "Noogle" = {
      icon = nix-icon;
      definedAliases = ["@nog"];
      urls = lib.singleton {
        template = "https://noogle.dev/q?term={searchTerms}";
      };
    };
    "Nixpkgs" = {
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@npkgs"];
      urls = lib.singleton {
        template = "https://github.com/search";
        params = lib.attrsToList {
          "type" = "code";
          "q" = "repo:NixOS/nixpkgs lang:nix {searchTerms}";
        };
      };
    };
    "Github Nix Code" = {
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@ghn"];
      urls = lib.singleton {
        template = "https://github.com/search";
        params = lib.attrsToList {
          "type" = "code";
          "q" = "lang:nix NOT is:fork {searchTerms}";
        };
      };
    };
  };
in {
  options.my.browser.firefox = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Firefox browser with custom configuration";
    };
    
    setAsDefault = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set Firefox as the default web browser (conflicts with other browsers)";
    };
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.firefox;
      description = "The Firefox package to install";
    };
    
    defaultSearchEngine = lib.mkOption {
      type = lib.types.str;
      default = "ecosia";
      description = "Default search engine for Firefox";
    };
    
    homepage = lib.mkOption {
      type = lib.types.str;
      default = "https://google.com";
      description = "Firefox homepage URL";
    };
  };

  config = lib.mkIf cfg.enable {
    # Firefox configuration using Home Manager's firefox module
    programs.firefox = {
      enable = true;
      package = cfg.package;
      
      # Native messaging hosts for extensions
      nativeMessagingHosts = with pkgs; [ fx-cast-bridge ];
      # Profiles managed manually (Kenp/Compecta/Proxy); Home Manager does not write profiles.ini here.
    };

    # Configure default application associations if requested
    xdg.mimeApps = lib.mkIf cfg.setAsDefault {
      enable = true;
      defaultApplications = {
        # HTTP/HTTPS protocols
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        
        # HTML content types
        "text/html" = ["firefox.desktop"];
        "application/xhtml+xml" = ["firefox.desktop"];
        
        # Browser-specific schemes
        "x-scheme-handler/about" = ["firefox.desktop"];
        "x-scheme-handler/unknown" = ["firefox.desktop"];
      };
    };

    # Shell aliases for Firefox management
    home.shellAliases = {
      "firefox-profile" = "firefox -P";
      "firefox-safe" = "firefox -safe-mode";
      "firefox-new" = "firefox -new-instance";
    };
  };
}
