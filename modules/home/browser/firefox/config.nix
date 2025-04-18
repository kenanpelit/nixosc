# modules/home/browser/firefox/config.nix
# ==============================================================================
# Firefox Core Configuration
# ==============================================================================
{ config, lib, pkgs, username, ... }:
let
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
 programs.firefox = {
   enable = true;
   package = pkgs.firefox;
   nativeMessagingHosts = with pkgs; [fx-cast-bridge];
   
   profiles."${username}" = {
     extensions.packages = extensionsList;
     search = {
       force = true;
       default = "ecosia";
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
       "browser.startup.homepage" = "https://google.com";
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
}
