# modules/home/browser/brave/default.nix
{ inputs, pkgs, config, lib, ... }:

let
  system = pkgs.system;
in {
  # Brave tarayıcısını yükle (sadece temel kurulum)
  home.packages = with pkgs; [
    brave  # Kararlı sürüm
  ];

  # İsteğe bağlı: Brave'i varsayılan tarayıcı olarak ayarlama
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = ["brave-browser.desktop"];
      "x-scheme-handler/https" = ["brave-browser.desktop"];
      "text/html" = ["brave-browser.desktop"];
      "application/xhtml+xml" = ["brave-browser.desktop"];
      "x-scheme-handler/about" = ["brave-browser.desktop"];
      "x-scheme-handler/unknown" = ["brave-browser.desktop"];
    };
  };
}

