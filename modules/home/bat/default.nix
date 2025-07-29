# modules/home/bat/default.nix
# ==============================================================================
# Bat (Cat Clone) Configuration
# ==============================================================================
{ pkgs, lib, ... }:
{
  # =============================================================================
  # Program Configuration
  # =============================================================================
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = lib.mkDefault "Catppuccin-mocha";  # FIXED: Added lib.mkDefault to avoid conflicts
    };
    # =============================================================================
    # Theme Configuration
    # =============================================================================
    themes = {
      Catppuccin-mocha = {
        src = ./theme;  # Tema dosyasının bulunduğu dizin
        file = "Catppuccin-mocha.tmTheme";  # Tema dosyasının adı
      };
    };
  };
}

