# modules/home/browser/zen/default.nix
# ==============================================================================
# Browser Configuration
# ==============================================================================
{ inputs, pkgs, host, system, ... }:
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    inputs.zen-browser.packages.${system}.default
  ];

  # Zen Browser'ı varsayılan tarayıcı olarak ayarla
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
}
