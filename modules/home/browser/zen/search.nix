# ==============================================================================
# Search Engine Configuration
# ==============================================================================
# modules/home/browser/zen/search.nix
{ lib, pkgs, ... }:
let
  nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  
  # İlk olarak tüm profilleri tanımlayalım
  profiles = {
    CompecTA = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-7.svg";
      index = 0;
    };
    Proxy = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-43.svg";
      index = 1;
    };
    Whats = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-89.svg";
      index = 2;
    };
    Discord = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-73.svg";
      index = 3;
    };
    Spotify = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-31.svg";
      index = 4;
    };
    NoVpn = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-62.svg";
      index = 5;
    };
    Kenp = {
      avatarPath = "chrome://browser/content/zen-avatars/avatar-2.svg";
      index = 6;
      isDefault = true;
    };
  };

  # Arama motorlarını tanımla
  searchEngines = {
    # Default Search Engine
    "Ecosia" = {
      iconUpdateURL = "https://www.ecosia.org/static/icons/favicon.ico";
      updateInterval = 24 * 60 * 60 * 1000; # Daily
      definedAliases = ["@e" "@ecosia"];
      urls = lib.singleton {
        template = "https://www.ecosia.org/search?q={searchTerms}";
      };
    };
    
    # Nix Package Search
    "Nix Packages" = {
      inherit nix-icon;
      definedAliases = ["@np"];
      urls = lib.singleton {
        template = "https://search.nixos.org/packages?type=packages&query={searchTerms}";
      };
    };
    
    # NixOS Documentation
    "NixOS Options" = {
      inherit nix-icon;
      definedAliases = ["@no"];
      urls = lib.singleton {
        template = "https://search.nixos.org/options?type=packages&query={searchTerms}";
      };
    };
    
    # NixOS Community
    "NixOS Wiki" = {
      inherit nix-icon;
      definedAliases = ["@nw"];
      urls = lib.singleton {
        template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
      };
    };
    
    # Development Tools
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
    
    # Code Search
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

  # profiles.ini içeriğini oluştur
  profilesIniContent = ''
    [General]
    StartWithLastProfile=1
    Version=2

    ${lib.concatStrings (lib.mapAttrsToList (name: profile: ''
      [Profile${toString profile.index}]
      Name=${name}
      IsRelative=1
      Path=${name}
      ZenAvatarPath=${profile.avatarPath}
      ${lib.optionalString (profile ? isDefault) "Default=1"}
    '') profiles)}

    [Install661F71C8ADC20D91]
    Default=Kenp
    Locked=1

    [Install15B76BAA26BA15E7]
    Default=Kenp
    Locked=1
  '';

in
{
  home.file = (lib.mapAttrs 
    (name: _: {
      target = ".zen/${name}/search-engines.json";
      text = builtins.toJSON searchEngines;
    }) 
    profiles) // {
    ".zen/profiles.ini" = {
      text = profilesIniContent;
    };
  };
}
