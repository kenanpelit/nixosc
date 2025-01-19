# ==============================================================================
# Search Engine Configuration
# ==============================================================================
# modules/home/browser/zen/search.nix
{ lib, pkgs, ... }:

let
  nix-icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
in {
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
}
