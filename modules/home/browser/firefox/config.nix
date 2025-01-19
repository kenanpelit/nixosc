# ==============================================================================
# Firefox Core Configuration
# ==============================================================================
# modules/home/browser/firefox/config.nix
{ config, lib, pkgs, username, ... }:

let
  # Firefox eklentileri
  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
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

  # Arama motorları yapılandırması
  searchConfig = let
    nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  in {
    "Ecosia" = {
      iconUpdateURL = "https://www.ecosia.org/static/icons/favicon.ico";
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
      iconUpdateURL = "https://github.com/favicon.ico";
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
      iconUpdateURL = "https://github.com/favicon.ico";
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
  hm.xdg.mimeApps = let
    defaultApplications = {
      "default-web-browser" = ["firefox.desktop"];
      "text/html" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/about" = ["firefox.desktop"];
      "x-scheme-handler/unknown" = ["firefox.desktop"];
      "application/xhtml+xml" = ["firefox.desktop"];
      "text/xml" = ["firefox.desktop"];
    };
  in
    lib.mkIf (config.variables.defaultBrowser == "firefox") {
      enable = true;
      inherit defaultApplications;
      associations.added = defaultApplications;
    };

# Firefox'u sadece bir alternatif olarak yükle, varsayılan olarak ayarlama
  hm.programs.firefox = {
    enable = true;
    nativeMessagingHosts = with pkgs; [fx-cast-bridge];
    
    profiles."${username}" = {
      inherit extensions;
      search = {
        force = true;
        default = "Ecosia";
        engines = searchConfig;
      };
      settings = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.download.useDownloadDir" = true;
        "browser.shell.checkDefaultBrowser" = false;  # Varsayılan tarayıcı kontrolünü devre dışı bırak
        "browser.shell.defaultBrowserCheckCount" = 0;
        "browser.startup.homepage" = "https://google.com";
        "browser.bookmarks.showMobileBookmarks" = true;
        "dom.security.https_only_mode" = true;
        "privacy.trackingprotection.enabled" = true;
        "signon.rememberSignons" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "identity.fxaccounts.enabled" = true;
        "browser.newtabpage.pinned" = lib.singleton {
          title = "NixOS";
          url = "https://nixos.org";
        };
      };
    };
  };
}
