# modules/home/firefox/config.nix
# ==============================================================================
# Firefox Core Configuration
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
{ config, lib, pkgs, username, ... }:
let
  cfg = config.my.browser.firefox;
  
  extensionsList = with pkgs.nur.repos.rycee.firefox-addons; [
    ublock-origin
    sponsorblock
    return-youtube-dislikes
    darkreader
    plasma-integration
    enhancer-for-youtube
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
      inherit nix-icon;
      definedAliases = ["@np"];
      urls = lib.singleton {
        template = "https://search.nixos.org/packages?type=packages&query={searchTerms}";
      };
    };
    "NixOS Options" = {
      inherit nix-icon;
      definedAliases = ["@no"];
      urls = lib.singleton {
        template = "https://search.nixos.org/options?type=packages&query={searchTerms}";
      };
    };
    "NixOS Wiki" = {
      inherit nix-icon;
      definedAliases = ["@nw"];
      urls = lib.singleton {
        template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
      };
    };
    "Nixpkgs PR Tracker" = {
      inherit nix-icon;
      definedAliases = ["@nprt"];
      urls = lib.singleton {
        template = "https://nixpk.gs/pr-tracker.html?pr={searchTerms}";
      };
    };
    "Noogle" = {
      inherit nix-icon;
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
      default = true;
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
    # Install Firefox
    home.packages = [ cfg.package ];

    # Firefox configuration
    programs.firefox = {
      enable = true;
      package = cfg.package;
      nativeMessagingHosts = with pkgs; [fx-cast-bridge];
      
      profiles."${username}" = {
        extensions.packages = extensionsList;
        search = {
          force = true;
          default = cfg.defaultSearchEngine;
          engines = searchConfig;
        };
        settings = {
          # File Picker Settings
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          
          # Browser Behavior
          "browser.disableResetPrompt" = true;
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = true;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 0;
          "browser.startup.homepage" = cfg.homepage;
          "browser.bookmarks.showMobileBookmarks" = true;
          
          # Privacy & Security
          "dom.security.https_only_mode" = true;
          "privacy.trackingprotection.enabled" = true;
          "signon.rememberSignons" = false;
          
          # Sponsored Content
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          
          # Account Integration
          "identity.fxaccounts.enabled" = true;
          
          # Pinned Sites
          "browser.newtabpage.pinned" = lib.singleton {
            title = "NixOS";
            url = "https://nixos.org";
          };
        };
      };
    };

    # Configure default application associations
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
  };
}

