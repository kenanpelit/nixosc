# modules/home/browser/chrome-preview/default.nix
{ inputs, pkgs, config, lib, ... }:

let
  system = pkgs.system;
in {
  home.packages = with inputs.browser-previews.packages.${system}; [
    #google-chrome-beta    # Beta sürüm
    #google-chrome-dev     # Dev sürüm
    google-chrome       # Kararlı sürüm (isteğe bağlı)
  ];

  ## İsteğe bağlı: Belirli bir Chrome sürümünü varsayılan tarayıcı olarak ayarlama
  #xdg.mimeApps = {
  #  enable = true;
  #  defaultApplications = {
  #    "x-scheme-handler/http" = ["google-chrome-beta.desktop"];
  #    "x-scheme-handler/https" = ["google-chrome-beta.desktop"];
  #    "text/html" = ["google-chrome-beta.desktop"];
  #    "application/xhtml+xml" = ["google-chrome-beta.desktop"];
  #    "x-scheme-handler/about" = ["google-chrome-beta.desktop"];
  #    "x-scheme-handler/unknown" = ["google-chrome-beta.desktop"];
  #  };
  #};
}

