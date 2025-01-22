# ==============================================================================
# Browser Configuration
# ==============================================================================
# modules/home/browser/zen/config.nix
{ inputs, pkgs, host, lib, ... }:
let
  system = pkgs.system;
in
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    inputs.zen-browser.packages.${system}.default
  ];

  # =============================================================================
  # Browser Configuration
  # =============================================================================
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

  # =============================================================================
  # Ana dizin altına .zen dizini oluştur
  # =============================================================================
  home.file.".zen/.keep".text = "";
}
