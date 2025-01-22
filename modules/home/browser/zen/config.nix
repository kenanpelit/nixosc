# modules/home/browser/zen/config.nix
{ inputs, pkgs, host, lib, ... }:
let
 system = pkgs.system;
 nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
 
 # Eklentiler Firefox'tan alındı
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

 profiles = {
   CompecTA.avatarPath = "chrome://browser/content/zen-avatars/avatar-7.svg";
   Proxy.avatarPath = "chrome://browser/content/zen-avatars/avatar-43.svg";
   Whats.avatarPath = "chrome://browser/content/zen-avatars/avatar-89.svg";
   Discord.avatarPath = "chrome://browser/content/zen-avatars/avatar-73.svg";
   Spotify.avatarPath = "chrome://browser/content/zen-avatars/avatar-31.svg";
   NoVpn.avatarPath = "chrome://browser/content/zen-avatars/avatar-62.svg";
   Kenp = {
     avatarPath = "chrome://browser/content/zen-avatars/avatar-2.svg";
     isDefault = true;
   };
 };

 # Arama motorları
 searchEngines = {
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

in
{
 home.packages = with pkgs; [
   inputs.zen-browser.packages.${system}.default
 ] ++ extensions;  # Eklentileri ekle

 xdg.mimeApps = {
   enable = true;
   defaultApplications = {
     "default-web-browser" = ["zen-browser.desktop"];
     "text/html" = ["zen-browser.desktop"];
     "x-scheme-handler/http" = ["zen-browser.desktop"];
     "x-scheme-handler/https" = ["zen-browser.desktop"];
     "x-scheme-handler/about" = ["zen-browser.desktop"];
     "x-scheme-handler/unknown" = ["zen-browser.desktop"];
     "application/xhtml+xml" = ["zen-browser.desktop"];
     "text/xml" = ["zen-browser.desktop"];
   };
 };

 home.file = (lib.mapAttrs 
   (name: _: {
     target = ".zen/${name}/search-engines.json";
     text = builtins.toJSON searchEngines;
   })
   profiles) // {
   ".zen/profiles.ini" = {
     text = ''
       [General]
       StartWithLastProfile=1
       Version=2

       [Profile0]
       Name=CompecTA
       IsRelative=1
       Path=CompecTA
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-7.svg

       [Profile1]
       Name=Proxy
       IsRelative=1
       Path=Proxy
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-43.svg

       [Profile2]
       Name=Whats
       IsRelative=1
       Path=Whats
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-89.svg

       [Profile3]
       Name=Discord
       IsRelative=1
       Path=Discord
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-73.svg

       [Profile4]
       Name=Spotify
       IsRelative=1
       Path=Spotify
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-31.svg

       [Profile5]
       Name=NoVpn
       IsRelative=1
       Path=NoVpn
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-62.svg

       [Profile6]
       Name=Kenp
       IsRelative=1
       Path=Kenp
       ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-2.svg
       Default=1

       [Install661F71C8ADC20D91]
       Default=Kenp
       Locked=1

       [Install15B76BAA26BA15E7]
       Default=Kenp
       Locked=1
     '';
   };
 };
}
